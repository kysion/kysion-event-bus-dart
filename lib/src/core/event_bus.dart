import 'dart:async';
// import 'package:meta/meta.dart'; // 暂时不使用，保留注释作为记录
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import '../models/emit_options.dart';
import '../models/event_metadata.dart';
import '../models/priority.dart';
import '../utils/platform_checker.dart';
import 'event_store.dart';
import 'event_stream.dart';
import 'event_tracer.dart';
import 'smart_dispatcher.dart';

/// 全局错误处理器定义
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

/// 事件过滤器定义
typedef EventFilter<T> = bool Function(T event);

/// 事件转换器定义
typedef EventTransformer<T, R> = R Function(T event);

/// 事件总线配置
class EventBusConfig {
  /// 是否启用历史记录
  ///
  /// 启用后，[EventStore]将保存事件历史，可用于事件回放和调试
  final bool historyEnabled;

  /// 事件调度器配置
  ///
  /// 用于配置批处理大小、批处理超时等参数
  /// 如果为null，则使用平台默认配置
  final SmartDispatcherConfig? dispatcherConfig;

  /// 全局错误处理器
  ///
  /// 用于捕获和处理事件总线中的错误
  /// 如果为null，则使用默认错误处理器
  final ErrorHandler? errorHandler;

  /// 是否启用轻量级元数据
  ///
  /// 启用后，事件元数据将使用轻量级模式，减少内存占用
  /// 轻量级模式下，部分元数据字段（如source和timestamp）可能不可用
  final bool useLightweightMetadata;

  /// 创建事件总线配置
  const EventBusConfig({
    this.historyEnabled = false,
    this.dispatcherConfig,
    this.errorHandler,
    this.useLightweightMetadata = false,
  });

  /// 创建高性能配置
  ///
  /// 返回针对高性能场景优化的配置
  /// - 禁用历史记录以减少内存使用
  /// - 启用轻量级元数据以提高性能
  static EventBusConfig highPerformance() => const EventBusConfig(
        historyEnabled: false,
        useLightweightMetadata: true,
      );

  /// 创建调试配置
  ///
  /// 返回针对调试场景优化的配置
  /// - 启用历史记录以便调试
  /// - 禁用轻量级元数据以获取完整信息
  static EventBusConfig debug() => const EventBusConfig(
        historyEnabled: true,
        useLightweightMetadata: false,
      );

  /// 创建与现有配置合并的新配置
  ///
  /// 用于在保留原有配置的基础上修改部分参数
  /// 参数为null时保留原配置值
  EventBusConfig copyWith({
    bool? historyEnabled,
    SmartDispatcherConfig? dispatcherConfig,
    ErrorHandler? errorHandler,
    bool? useLightweightMetadata,
  }) {
    return EventBusConfig(
      historyEnabled: historyEnabled ?? this.historyEnabled,
      dispatcherConfig: dispatcherConfig ?? this.dispatcherConfig,
      errorHandler: errorHandler ?? this.errorHandler,
      useLightweightMetadata:
          useLightweightMetadata ?? this.useLightweightMetadata,
    );
  }
}

/// 事件总线
///
/// 提供事件发布订阅、事件存储、事件追踪等功能
class KysionEventBus {
  /// 事件调度器
  final SmartDispatcher _dispatcher;

  /// 事件存储
  final EventStore _store;

  /// 事件追踪器
  final EventTracer _tracer;

  /// 事件流控制器
  final _controller = StreamController<dynamic>.broadcast();

  /// 事件流缓存
  final _streamCache = <Type, EventStream>{};

  /// 类型缓存，提高类型检查性能
  final _typeCache = <Type, bool Function(dynamic)>{};

  /// 调度锁 - 用于保护调度器操作
  final _dispatchLock = Lock();

  /// 存储锁 - 用于保护存储操作
  final _storeLock = Lock();

  /// 控制器锁 - 用于保护控制器操作
  final _controllerLock = Lock();

  /// 全局错误处理器
  ErrorHandler _errorHandler;

  /// 是否启用轻量级元数据
  bool _useLightweightMetadata = false;

  /// 是否已关闭
  bool _isDisposed = false;

  /// 创建事件总线
  ///
  /// [dispatcher] 事件调度器
  /// [store] 事件存储
  /// [tracer] 事件追踪器
  /// [historyEnabled] 是否启用历史记录，默认为false
  /// [errorHandler] 全局错误处理器
  KysionEventBus({
    SmartDispatcher? dispatcher,
    EventStore? store,
    EventTracer? tracer,
    bool historyEnabled = false,
    ErrorHandler? errorHandler,
    bool useLightweightMetadata = false,
  })  : _dispatcher = dispatcher ??
            SmartDispatcher(
              minBatchSize: PlatformChecker.getPlatformConfig()['minBatchSize'],
              maxBatchSize: PlatformChecker.getPlatformConfig()['maxBatchSize'],
              batchTimeout: PlatformChecker.getPlatformConfig()['batchTimeout'],
            ),
        _store = store ?? MemoryEventStore(historyEnabled: historyEnabled),
        _tracer = tracer ?? EventTracer(),
        _errorHandler = errorHandler ?? _defaultErrorHandler {
    _useLightweightMetadata = useLightweightMetadata;
  }

  /// 使用配置创建事件总线
  ///
  /// [config] 事件总线配置
  KysionEventBus.withConfig(EventBusConfig config)
      : _dispatcher = SmartDispatcher(
          minBatchSize: config.dispatcherConfig?.minBatchSize ??
              PlatformChecker.getPlatformConfig()['minBatchSize'],
          maxBatchSize: config.dispatcherConfig?.maxBatchSize ??
              PlatformChecker.getPlatformConfig()['maxBatchSize'],
          batchTimeout: config.dispatcherConfig?.batchTimeout ??
              PlatformChecker.getPlatformConfig()['batchTimeout'],
        ),
        _store = MemoryEventStore(historyEnabled: config.historyEnabled),
        _tracer = EventTracer(),
        _errorHandler = config.errorHandler ?? _defaultErrorHandler {
    _useLightweightMetadata = config.useLightweightMetadata;
  }

  /// 创建基本事件总线
  ///
  /// 适用于大多数简单场景
  static KysionEventBus simple() => KysionEventBus();

  /// 创建带历史记录的事件总线
  ///
  /// 适用于需要历史事件回放的场景
  static KysionEventBus withHistory() => KysionEventBus(historyEnabled: true);

  /// 创建高性能事件总线
  ///
  /// 适用于高吞吐量场景
  /// 特点:
  /// - 更大的批处理大小，提高批处理效率
  /// - 更短的批处理超时，减少延迟
  /// - 启用轻量级元数据，减少内存开销
  static KysionEventBus forPerformance() => KysionEventBus(
        dispatcher: SmartDispatcher(
          minBatchSize: 50,
          maxBatchSize: 500,
          batchTimeout: const Duration(milliseconds: 50),
        ),
        useLightweightMetadata: true,
      );

  /// 创建适合当前平台的事件总线
  ///
  /// 自动根据平台选择最佳配置:
  /// - Web平台: 较小批处理大小，启用轻量级元数据，禁用历史记录
  /// - 移动平台: 中等批处理大小，启用历史记录
  /// - 桌面平台: 较大批处理大小，启用历史记录
  ///
  /// 通过[PlatformChecker]自动检测当前平台并应用相应配置
  static KysionEventBus forCurrentPlatform() {
    final platform = PlatformChecker.currentPlatform;

    switch (platform) {
      case PlatformType.web:
        return KysionEventBus(
          dispatcher: SmartDispatcher(
            minBatchSize: 5,
            maxBatchSize: 50,
            batchTimeout: const Duration(milliseconds: 50),
          ),
          historyEnabled: false,
          useLightweightMetadata: true,
        );

      case PlatformType.android:
      case PlatformType.ios:
        return KysionEventBus(
          dispatcher: SmartDispatcher(
            minBatchSize: 10,
            maxBatchSize: 100,
            batchTimeout: const Duration(milliseconds: 100),
          ),
          historyEnabled: true,
        );

      case PlatformType.macOS:
      case PlatformType.windows:
      case PlatformType.linux:
        return KysionEventBus(
          dispatcher: SmartDispatcher(
            minBatchSize: 20,
            maxBatchSize: 200,
            batchTimeout: const Duration(milliseconds: 200),
          ),
          historyEnabled: true,
        );

      default:
        return KysionEventBus.simple();
    }
  }

  /// 创建调试模式事件总线
  ///
  /// 启用完整的跟踪和历史记录功能
  static KysionEventBus forDebugging() => KysionEventBus(
        historyEnabled: true,
        useLightweightMetadata: false,
        errorHandler: (error, stackTrace) {
          print('=== KysionEventBus DEBUG ERROR ===');
          print('错误: $error');
          print('堆栈信息: $stackTrace');
          print('============================');
        },
      );

  /// 默认错误处理器
  static void _defaultErrorHandler(Object error, StackTrace stackTrace) {
    print('KysionEventBus错误: $error');
    print('堆栈信息: $stackTrace');
  }

  /// 设置错误处理器
  void setErrorHandler(ErrorHandler handler) {
    _errorHandler = handler;
  }

  /// 启用轻量级元数据
  void enableLightweightMetadata(bool enable) {
    _useLightweightMetadata = enable;
  }

  /// 获取事件流
  ///
  /// [options] 事件选项，包括优先级、元数据等
  ///
  /// 返回类型为[T]的事件流，可链式调用进行过滤、转换等操作
  ///
  /// 性能优化:
  /// - 使用类型缓存提高类型检查性能
  /// - 使用流缓存避免重复创建相同类型的事件流
  /// - 通过广播流支持多订阅者
  EventStream<T> on<T>({EmitOptions? options}) {
    _checkDisposed();
    return _streamCache.putIfAbsent(
      T,
      () => _EventStreamImpl<T>(
        _controller.stream
            .where(_getTypeChecker<T>())
            .cast<T>()
            .asBroadcastStream(),
        this,
        options ?? const EmitOptions(),
      ),
    ) as EventStream<T>;
  }

  /// 获取事件流并立即过滤
  ///
  /// [filter] 过滤函数
  /// [options] 事件选项
  EventStream<T> onWhere<T>(EventFilter<T> filter, {EmitOptions? options}) {
    return on<T>(options: options).where(filter);
  }

  /// 获取事件流并立即转换
  ///
  /// [transformer] 转换函数
  /// [options] 事件选项
  EventStream<R> onTransform<T, R>(EventTransformer<T, R> transformer,
      {EmitOptions? options}) {
    return on<T>(options: options).transform(transformer);
  }

  /// 获取类型检查函数，使用缓存提高性能
  bool Function(dynamic) _getTypeChecker<T>() {
    return _typeCache.putIfAbsent(T, () => (dynamic event) => event is T);
  }

  /// 判断是否已关闭
  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('事件总线已关闭，无法执行操作');
    }
  }

  /// 发送事件
  ///
  /// [event] 要发送的事件
  /// [options] 发送选项，包括优先级、元数据等
  ///
  /// 事件处理流程:
  /// 1. 创建或使用提供的元数据
  /// 2. 如果启用追踪，记录事件开始
  /// 3. 通过调度器分发事件（使用锁保证并发安全）
  /// 4. 调度器将根据优先级和批处理策略处理事件
  /// 5. 事件处理完成后，存储事件并通知订阅者
  /// 6. 如果启用追踪，记录事件完成
  ///
  /// 返回发送是否成功，失败时会抛出异常
  Future<bool> emit<T>(T event, {EmitOptions? options}) async {
    _checkDisposed();
    final effectiveOptions = options ?? const EmitOptions();
    final metadata =
        effectiveOptions.metadata ?? _createMetadata(effectiveOptions.priority);

    if (effectiveOptions.enableTracing) {
      _tracer.startTrace(event, metadata);
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 分离锁的粒度，分别保护不同的操作
      await _dispatchLock.synchronized(() async {
        await _dispatcher.dispatch(
          event,
          metadata,
          (e) async {
            // 使用单独的锁保护存储操作
            await _storeLock.synchronized(() async {
              await _store.store(e, metadata);
            });

            // 使用单独的锁保护控制器操作
            await _controllerLock.synchronized(() {
              _controller.add(e);
            });
          },
        );
      });

      if (effectiveOptions.enableTracing) {
        _tracer.endTrace(event, metadata, stopwatch.elapsed);
      }

      return true;
    } catch (error, stackTrace) {
      if (effectiveOptions.enableTracing) {
        _tracer.recordError(event, metadata, error, stackTrace);
      }
      _handleError(error, stackTrace);
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  /// 创建元数据，根据设置选择完整或轻量级
  EventMetadata _createMetadata(Priority priority) {
    if (_useLightweightMetadata) {
      // 使用轻量级元数据工厂方法
      return EventMetadata.lightweight(
        priority: priority,
      );
    } else {
      // 使用完整元数据工厂方法
      return EventMetadata(
        priority: priority,
        source: PlatformChecker.currentPlatform.toString(),
        type: MetadataType.full,
        eventTypeName: null, // 在emit阶段无法知道实际事件类型名
      );
    }
  }

  /// 处理错误
  void _handleError(Object error, StackTrace stackTrace) {
    try {
      _errorHandler(error, stackTrace);
    } catch (e) {
      // 保证错误处理器本身不会抛出异常
      _defaultErrorHandler(e, StackTrace.current);
    }
  }

  /// 发送并忘记（不等待结果也不处理错误）
  void fireAndForget<T>(T event, {EmitOptions? options}) {
    _checkDisposed();
    emit(event, options: options).catchError((error, stackTrace) {
      _handleError(error, stackTrace);
      return false; // 返回bool类型以符合Future.catchError的返回类型要求
    });
  }

  /// 延迟发送事件
  Future<bool> fireDelayed<T>(T event, Duration delay,
      {EmitOptions? options}) async {
    _checkDisposed();
    await Future.delayed(delay);
    return emit(event, options: options);
  }

  /// 批量发送事件
  ///
  /// [events] 要发送的事件列表
  /// [options] 发送选项
  ///
  /// 按顺序发送多个事件，每个事件独立处理
  /// 一个事件失败不会影响其他事件的处理
  ///
  /// 返回每个事件的发送结果列表
  Future<List<bool>> emitBatch<T>(List<T> events,
      {EmitOptions? options}) async {
    _checkDisposed();
    final results = <bool>[];
    for (final event in events) {
      try {
        results.add(await emit(event, options: options));
      } catch (e) {
        results.add(false);
      }
    }
    return results;
  }

  /// 按顺序发送事件，如果前一个失败则停止
  ///
  /// [events] 要发送的事件列表
  /// [options] 发送选项
  ///
  /// 与[emitBatch]不同，此方法在遇到第一个失败时会停止发送后续事件
  /// 用于需要严格按顺序且每步都成功的操作
  ///
  /// 返回是否全部发送成功
  Future<bool> emitSequence<T>(List<T> events, {EmitOptions? options}) async {
    _checkDisposed();
    for (final event in events) {
      if (!await emit(event, options: options)) {
        return false;
      }
    }
    return true;
  }

  /// 获取事件历史
  ///
  /// [type] 事件类型
  /// [limit] 限制返回的事件数量
  /// [offset] 跳过的事件数量
  Future<List<Map<String, dynamic>>> getHistory<T>({
    int? limit,
    int? offset,
  }) async {
    _checkDisposed();
    try {
      return await _store.getHistory<T>(
        limit: limit,
        offset: offset,
      );
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return [];
    }
  }

  /// 清除事件历史
  ///
  /// [type] 事件类型
  /// [before] 清除该时间之前的事件
  Future<void> clearHistory<T>({DateTime? before}) async {
    _checkDisposed();
    try {
      await _store.clearHistory<T>(before: before);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// 获取性能指标
  ///
  /// [eventType] 事件类型
  Map<String, dynamic> getMetrics([String? eventType]) {
    _checkDisposed();
    try {
      return _tracer.getMetrics(eventType);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// 获取错误统计
  ///
  /// [eventType] 事件类型
  Map<String, int> getErrorStats([String? eventType]) {
    _checkDisposed();
    try {
      return _tracer.getErrorStats(eventType);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }

  /// 重置统计信息
  void resetStats() {
    _checkDisposed();
    try {
      _tracer.reset();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// 判断事件总线是否已关闭
  bool get isDisposed => _isDisposed;

  /// 关闭事件总线
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    await _controller.close();
    await _store.close();
    _streamCache.clear();
    _typeCache.clear();
  }

  /// 获取当前平台信息
  Map<String, dynamic> getPlatformInfo() {
    _checkDisposed();
    try {
      return {
        'platform': PlatformChecker.currentPlatform.toString(),
        'isWeb': PlatformChecker.isWeb,
        'isMobile': PlatformChecker.isMobile,
        'isDesktop': PlatformChecker.isDesktop,
        'historyEnabled': _store.historyEnabled,
        'useLightweightMetadata': _useLightweightMetadata,
        'features': {
          'eventHistory':
              PlatformChecker.isFeatureSupported(Feature.eventHistory),
          'batchProcessing':
              PlatformChecker.isFeatureSupported(Feature.batchProcessing),
          'priorityQueue':
              PlatformChecker.isFeatureSupported(Feature.priorityQueue),
          'tracing': PlatformChecker.isFeatureSupported(Feature.tracing),
        },
        'config': PlatformChecker.getPlatformConfig(),
        'dispatcherStatus': _dispatcher.getProcessorStatus(),
      };
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      return {};
    }
  }
}

/// 事件流实现
class _EventStreamImpl<T> implements EventStream<T> {
  final Stream<T> _stream;
  final KysionEventBus _eventBus;
  final EmitOptions _options;

  _EventStreamImpl(this._stream, this._eventBus, this._options);

  @override
  Stream<T> get stream => _stream;

  @override
  Future<bool> emit(T event, {EmitOptions? options}) {
    return _eventBus.emit(
      event,
      options: options?.merge(_options) ?? _options,
    );
  }

  @override
  EventStream<T> where(bool Function(T event) predicate) {
    return _EventStreamImpl<T>(
      _stream.where(predicate),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<R> transform<R>(R Function(T event) transformer) {
    return _EventStreamImpl<R>(
      _stream.map(transformer),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> withMetadata(EventMetadata metadata) {
    return _EventStreamImpl<T>(
      _stream,
      _eventBus,
      _options.copyWith(metadata: metadata),
    );
  }

  @override
  EventStream<T> withPriority(Priority priority) {
    return _EventStreamImpl<T>(
      _stream,
      _eventBus,
      _options.copyWith(priority: priority),
    );
  }

  @override
  EventStream<T> take(int count) {
    return _EventStreamImpl<T>(
      _stream.take(count),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> skip(int count) {
    return _EventStreamImpl<T>(
      _stream.skip(count),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> takeForDuration(Duration duration) {
    final startTime = DateTime.now();

    return _EventStreamImpl<T>(
      _stream.takeWhile((_) {
        // 使用时间差而不是创建不必要的计时器
        return DateTime.now().difference(startTime) < duration;
      }),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> debounce(Duration duration) {
    // 使用RxDart的debounceTime操作符
    if (_stream is ValueStream<T>) {
      return _EventStreamImpl<T>(
        (_stream as ValueStream<T>).debounceTime(duration),
        _eventBus,
        _options,
      );
    }

    // 普通Stream的简单防抖实现
    return _EventStreamImpl<T>(
      Stream<T>.eventTransformed(
        _stream,
        (sink) => _DebounceSink<T>(sink, duration),
      ),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> throttle(Duration duration) {
    // 使用RxDart的throttleTime操作符
    if (_stream is ValueStream<T>) {
      return _EventStreamImpl<T>(
        (_stream as ValueStream<T>).throttleTime(duration),
        _eventBus,
        _options,
      );
    }

    // 普通Stream的简单节流实现
    return _EventStreamImpl<T>(
      Stream<T>.eventTransformed(
        _stream,
        (sink) => _ThrottleSink<T>(sink, duration),
      ),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> mergeWith(Stream<T> other) {
    return _EventStreamImpl<T>(
      Stream.multi((controller) {
        StreamSubscription<T>? subscription1;
        StreamSubscription<T>? subscription2;

        subscription1 = _stream
            .listen(controller.add, onError: controller.addError, onDone: () {
          subscription1?.cancel();
          if (subscription2?.isPaused ?? false) {
            controller.close();
          }
        });

        subscription2 = other
            .listen(controller.add, onError: controller.addError, onDone: () {
          subscription2?.cancel();
          if (subscription1?.isPaused ?? false) {
            controller.close();
          }
        });

        controller.onCancel = () {
          subscription1?.cancel();
          subscription2?.cancel();
        };
      }),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<dynamic> concat(Stream<dynamic> other) {
    return _EventStreamImpl<dynamic>(
      _stream
          .cast<dynamic>()
          .asyncExpand((event) => Stream.value(event))
          .concatWith([other]),
      _eventBus,
      _options,
    );
  }

  @override
  Future<T> get first => _stream.first;

  @override
  Future<T> get last => _stream.last;

  @override
  Future<List<T>> toList() => _stream.toList();

  @override
  EventStream<T> doOnData(void Function(T event) action) {
    return _EventStreamImpl<T>(
      _stream.map((event) {
        action(event);
        return event;
      }),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> doOnError(
      void Function(Object error, StackTrace stackTrace) action) {
    return _EventStreamImpl<T>(
      _stream.handleError((error, stackTrace) {
        action(error, stackTrace ?? StackTrace.current);
      }),
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<T> doOnDone(void Function() action) {
    late StreamController<T> controller;
    controller = StreamController<T>.broadcast(onListen: () {
      _stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          action();
          controller.close();
        },
      );
    });

    return _EventStreamImpl<T>(
      controller.stream,
      _eventBus,
      _options,
    );
  }

  @override
  EventStream<R> asyncMap<R>(FutureOr<R> Function(T event) mapper) {
    return _EventStreamImpl<R>(
      _stream.asyncMap(mapper),
      _eventBus,
      _options,
    );
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<void> close() async {
    // 流会在事件总线关闭时自动关闭
  }
}

/// 防抖事件转换器
class _DebounceSink<T> implements EventSink<T> {
  final EventSink<T> _sink;
  final Duration _duration;
  Timer? _timer;
  T? _pendingEvent;
  bool _hasPendingEvent = false;
  bool _isClosed = false;

  _DebounceSink(this._sink, this._duration);

  @override
  void add(T data) {
    if (_isClosed) return;

    _timer?.cancel();
    _pendingEvent = data;
    _hasPendingEvent = true;

    _timer = Timer(_duration, () {
      if (_hasPendingEvent && !_isClosed) {
        _sink.add(_pendingEvent as T);
        _hasPendingEvent = false;
        _pendingEvent = null; // 释放引用，避免内存泄漏
      }
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isClosed) return;

    _timer?.cancel();
    _hasPendingEvent = false;
    _pendingEvent = null; // 释放引用
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _timer?.cancel();
    _timer = null;

    if (_hasPendingEvent) {
      _sink.add(_pendingEvent as T);
      _hasPendingEvent = false;
      _pendingEvent = null; // 释放引用
    }
    _sink.close();
  }
}

/// 节流事件转换器
class _ThrottleSink<T> implements EventSink<T> {
  final EventSink<T> _sink;
  final Duration _duration;
  Timer? _timer;
  bool _canEmit = true;
  bool _isClosed = false;
  T? _lastValue; // 保存最后一个值，用于在关闭时发射
  bool _hasLastValue = false;

  _ThrottleSink(this._sink, this._duration);

  @override
  void add(T data) {
    if (_isClosed) return;

    _lastValue = data;
    _hasLastValue = true;

    if (_canEmit) {
      _sink.add(data);
      _canEmit = false;
      _hasLastValue = false;

      _timer?.cancel();
      _timer = Timer(_duration, () {
        if (!_isClosed) {
          _canEmit = true;
          // 发射最后保存的值
          if (_hasLastValue) {
            _sink.add(_lastValue as T);
            _hasLastValue = false;
            _lastValue = null;

            // 重置冷却状态
            _canEmit = false;
            _timer?.cancel();
            _timer = Timer(_duration, () {
              if (!_isClosed) _canEmit = true;
            });
          }
        }
      });
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isClosed) return;
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _timer?.cancel();
    _timer = null;

    // 发射最后保存的值，如果有的话
    if (_hasLastValue) {
      _sink.add(_lastValue as T);
    }

    _lastValue = null;
    _sink.close();
  }
}
