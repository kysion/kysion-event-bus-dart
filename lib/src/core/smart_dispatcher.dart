import 'dart:async';
import 'dart:collection';

import '../models/priority.dart';
import '../models/event_metadata.dart';
import '../utils/batch_processor.dart';
import '../utils/circuit_breaker.dart';

/// 智能调度器配置
class SmartDispatcherConfig {
  /// 最小批处理大小
  final int minBatchSize;

  /// 最大批处理大小
  final int maxBatchSize;

  /// 批处理超时时间
  final Duration batchTimeout;

  /// 熔断失败阈值
  final int failureThreshold;

  /// 熔断重置超时
  final Duration resetTimeout;

  /// 自适应阈值启用
  final bool adaptiveThreshold;

  /// 创建智能调度器配置
  const SmartDispatcherConfig({
    this.minBatchSize = 10,
    this.maxBatchSize = 1000,
    this.batchTimeout = const Duration(milliseconds: 100),
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.adaptiveThreshold = true,
  });
}

/// 智能调度器
///
/// 负责事件的智能调度、批处理和流量控制
/// 核心功能:
/// - 按优先级管理事件队列
/// - 批量处理事件，提高吞吐量
/// - 熔断保护，防止系统过载
/// - 自适应阈值调整，优化性能
class SmartDispatcher {
  /// 批处理器
  final BatchProcessor _batchProcessor;

  /// 熔断器
  final CircuitBreaker _circuitBreaker;

  /// 优先级队列
  final Map<Priority, Queue<_EventWrapper>> _priorityQueues;

  /// 调度统计信息
  final _stats = _DispatcherStats();

  /// 是否自适应调整阈值
  final bool _adaptiveThreshold;

  /// 创建智能调度器
  ///
  /// [minBatchSize] 最小批处理大小
  /// [maxBatchSize] 最大批处理大小
  /// [batchTimeout] 批处理超时时间
  /// [failureThreshold] 熔断失败阈值
  /// [resetTimeout] 熔断重置超时
  /// [adaptiveThreshold] 是否自适应调整阈值
  SmartDispatcher({
    int minBatchSize = 10,
    int maxBatchSize = 1000,
    Duration batchTimeout = const Duration(milliseconds: 100),
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(seconds: 30),
    bool adaptiveThreshold = true,
  })  : _batchProcessor = BatchProcessor(
          minBatchSize: minBatchSize,
          maxBatchSize: maxBatchSize,
          timeout: batchTimeout,
        ),
        _circuitBreaker = CircuitBreaker(
          failureThreshold: failureThreshold,
          resetTimeout: resetTimeout,
        ),
        _priorityQueues = {
          for (var priority in Priority.values)
            priority: Queue<_EventWrapper>(),
        },
        _adaptiveThreshold = adaptiveThreshold;

  /// 使用配置创建智能调度器
  ///
  /// [config] 调度器配置
  SmartDispatcher.withConfig(SmartDispatcherConfig config)
      : _batchProcessor = BatchProcessor(
          minBatchSize: config.minBatchSize,
          maxBatchSize: config.maxBatchSize,
          timeout: config.batchTimeout,
        ),
        _circuitBreaker = CircuitBreaker(
          failureThreshold: config.failureThreshold,
          resetTimeout: config.resetTimeout,
        ),
        _priorityQueues = {
          for (var priority in Priority.values)
            priority: Queue<_EventWrapper>(),
        },
        _adaptiveThreshold = config.adaptiveThreshold;

  /// 调度事件
  ///
  /// [event] 要调度的事件
  /// [metadata] 事件元数据
  /// [handler] 事件处理函数
  ///
  /// 事件调度流程:
  /// 1. 检查熔断器状态，如果熔断器开启则拒绝调度
  /// 2. 创建事件包装器并添加到对应优先级的队列
  /// 3. 判断是否应该立即处理队列中的事件
  /// 4. 如果条件满足，则启动批处理
  ///
  /// 熔断器保护机制防止系统因事件过多而过载
  Future<void> dispatch<T>(
    T event,
    EventMetadata metadata,
    Future<void> Function(T event) handler,
  ) async {
    // 检查熔断器状态
    if (!_circuitBreaker.isAllowed) {
      throw StateError('Circuit breaker is open');
    }

    final wrapper = _EventWrapper(event, metadata, handler);
    final queue = _priorityQueues[metadata.priority]!;

    // 添加到优先级队列
    queue.add(wrapper);
    _stats.incrementQueued(metadata.priority);

    // 尝试批处理
    if (_shouldProcessBatch(metadata.priority)) {
      await _processBatch(metadata.priority);
    }
  }

  /// 判断是否应该进行批处理
  ///
  /// [priority] 事件优先级
  ///
  /// 判断逻辑:
  /// 1. 关键优先级事件总是立即处理
  /// 2. 队列长度达到或超过最小批处理大小时处理
  /// 3. 如果启用自适应阈值，根据历史处理量动态调整批处理阈值
  ///
  /// 自适应阈值能够根据系统实际性能动态调整批处理策略
  bool _shouldProcessBatch(Priority priority) {
    final queue = _priorityQueues[priority]!;

    // 对关键优先级的事件立即处理
    if (priority == Priority.critical) {
      return queue.isNotEmpty;
    }

    // 正常阈值判断
    if (queue.length >= _batchProcessor.minBatchSize) {
      return true;
    }

    // 自适应阈值（根据历史处理速度动态调整）
    if (_adaptiveThreshold) {
      final historySize = _stats.getProcessedCount(priority);
      final queueSize = queue.length;

      // 如果历史处理量大，允许较小的批处理
      if (historySize > 1000 && queueSize > _batchProcessor.minBatchSize / 2) {
        return true;
      }
    }

    return false;
  }

  /// 处理批量事件
  ///
  /// [priority] 要处理的事件优先级
  ///
  /// 处理流程:
  /// 1. 对队列中的事件按重试次数排序，优先处理重试次数少的事件
  /// 2. 检查每个事件是否需要延迟处理（指数退避策略）
  /// 3. 通过批处理器处理事件批次
  /// 4. 对每个事件独立处理结果，成功则重置重试计数，失败则记录并准备重试
  /// 5. 对永久失败的事件（超过最大重试次数）进行特殊处理
  ///
  /// 智能重试机制确保临时失败的事件能够被重新处理，同时避免系统资源被失败事件占用
  Future<void> _processBatch(Priority priority) async {
    final queue = _priorityQueues[priority]!;
    if (queue.isEmpty) return;

    final batch = <_EventWrapper>[];

    // 优先处理重试次数较低的事件
    final queueList = queue.toList()
      ..sort((a, b) => a.retryCount.compareTo(b.retryCount));

    // 清空队列并使用排序后的列表
    queue.clear();
    queue.addAll(queueList);

    // 取出事件进行处理
    while (batch.length < _batchProcessor.maxBatchSize && queue.isNotEmpty) {
      final wrapper = queue.removeFirst();

      // 检查是否需要延迟处理（指数退避）
      if (wrapper.retryCount > 0) {
        final lastFailedAt = wrapper._lastFailedAt;
        final now = DateTime.now();
        final retryDelay = wrapper.retryDelay;

        if (lastFailedAt != null && now.difference(lastFailedAt) < retryDelay) {
          // 还没到重试时间，放回队列末尾
          queue.addLast(wrapper);
          continue;
        }

        // 记录重试统计
        _stats.incrementRetried(priority);
      }

      batch.add(wrapper);
    }

    if (batch.isEmpty) {
      // 所有事件都在等待重试延迟
      return;
    }

    try {
      await _batchProcessor.process(batch, (items) async {
        for (var wrapper in items) {
          try {
            await wrapper.handler(wrapper.event);
            _stats.incrementProcessed(priority);
            _circuitBreaker.recordSuccess();
            wrapper.resetRetryCount(); // 成功后重置重试计数
          } catch (e) {
            _stats.incrementFailed(priority);
            _circuitBreaker.recordFailure();
            wrapper.recordFailure(e); // 记录失败

            // 在这里不重新抛出异常，而是单独处理每个事件的失败
            if (wrapper.shouldRetry) {
              // 放回队列以便重试
              queue.addLast(wrapper);
            } else {
              // 已达到最大重试次数
              _stats.incrementPermanentlyFailed(priority);

              // 此处可以添加永久失败事件的额外处理逻辑
              // 例如记录到持久化存储或发送通知
            }
          }
        }
      });
    } catch (e) {
      // 批处理本身失败（非事件处理失败）
      // 这种情况很少见，可能是系统资源问题
      for (var wrapper in batch) {
        if (wrapper.shouldRetry) {
          queue.addFirst(wrapper); // 优先重试
          wrapper.incrementRetryCount();
          _stats.incrementRetried(priority);
        } else {
          _stats.incrementPermanentlyFailed(priority);
        }
      }
      rethrow;
    }
  }

  /// 获取调度器统计信息
  Map<String, dynamic> getStats() => _stats.toJson();

  /// 重置统计信息
  void resetStats() => _stats.reset();

  /// 获取当前批处理器状态
  Map<String, dynamic> getProcessorStatus() {
    return {
      'minBatchSize': _batchProcessor.minBatchSize,
      'maxBatchSize': _batchProcessor.maxBatchSize,
      'currentBatchSize': _batchProcessor.currentBatchSize,
      'adaptiveThreshold': _adaptiveThreshold,
      'circuitBreakerStatus': _circuitBreaker.getStats(),
    };
  }
}

/// 事件包装器
///
/// 封装事件及其相关信息，用于智能调度和重试管理
/// 功能:
/// - 封装事件、元数据和处理函数
/// - 管理重试计数和最大重试次数
/// - 实现指数退避策略
/// - 记录失败信息用于调试
class _EventWrapper<T> {
  /// 事件对象
  final T event;

  /// 事件元数据
  final EventMetadata metadata;

  /// 事件处理函数
  final Future<void> Function(T event) handler;

  /// 重试计数
  int _retryCount = 0;

  /// 最大重试次数，根据优先级设置
  final int maxRetries;

  /// 最后一次失败的时间
  DateTime? _lastFailedAt;

  /// 最后一次失败的错误
  Object? _lastError;

  _EventWrapper(this.event, this.metadata, this.handler)
      : maxRetries = _calculateMaxRetries(metadata.priority);

  /// 根据优先级计算最大重试次数
  ///
  /// 高优先级事件允许更多次重试，确保重要事件能够成功处理
  /// 低优先级事件限制重试次数，避免系统资源被占用
  static int _calculateMaxRetries(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return 10; // 关键优先级事件尝试更多次
      case Priority.high:
        return 5;
      case Priority.normal:
        return 3;
      case Priority.low:
        return 1;
    }
  }

  /// 获取当前重试计数
  int get retryCount => _retryCount;

  /// 获取重试间隔（使用指数退避）
  ///
  /// 实现指数退避策略:
  /// - 重试次数越多，等待时间越长
  /// - 高优先级事件的基础等待时间更短
  /// - 设置上限防止等待时间过长
  Duration get retryDelay {
    if (_retryCount <= 0) return Duration.zero;

    // 基础延迟，根据优先级设置
    final baseDelay = metadata.priority == Priority.critical
        ? const Duration(milliseconds: 50)
        : metadata.priority == Priority.high
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 200);

    // 指数退避，但设置上限
    final multiplier = _retryCount > 10 ? 10 : _retryCount;
    return baseDelay * multiplier;
  }

  /// 增加重试计数
  ///
  /// 每次调用增加重试计数并记录当前时间
  void incrementRetryCount() {
    _retryCount++;
    _lastFailedAt = DateTime.now();
  }

  /// 记录失败
  ///
  /// 保存错误信息并增加重试计数
  void recordFailure(Object error) {
    _lastError = error;
    incrementRetryCount();
  }

  /// 重置重试计数
  ///
  /// 成功处理后调用，清空所有失败相关信息
  void resetRetryCount() {
    _retryCount = 0;
    _lastFailedAt = null;
    _lastError = null;
  }

  /// 是否应该继续重试
  ///
  /// 根据当前重试次数和最大重试次数判断
  bool get shouldRetry => _retryCount < maxRetries;

  /// 获取失败信息
  ///
  /// 返回包含重试次数、最大重试次数、最后失败时间等信息的Map
  /// 用于调试和监控
  Map<String, dynamic> getFailureInfo() {
    return {
      'retryCount': _retryCount,
      'maxRetries': maxRetries,
      'lastFailedAt': _lastFailedAt?.toIso8601String(),
      'lastError': _lastError?.toString(),
      'eventType': event.runtimeType.toString(),
      'priority': metadata.priority.toString(),
    };
  }
}

/// 调度器统计信息
class _DispatcherStats {
  final _queued = <Priority, int>{};
  final _processed = <Priority, int>{};
  final _failed = <Priority, int>{};
  final _permanentlyFailed = <Priority, int>{};
  final _retried = <Priority, int>{};

  _DispatcherStats() {
    for (var priority in Priority.values) {
      _queued[priority] = 0;
      _processed[priority] = 0;
      _failed[priority] = 0;
      _permanentlyFailed[priority] = 0;
      _retried[priority] = 0;
    }
  }

  void incrementQueued(Priority priority) =>
      _queued[priority] = (_queued[priority] ?? 0) + 1;
  void incrementProcessed(Priority priority) =>
      _processed[priority] = (_processed[priority] ?? 0) + 1;
  void incrementFailed(Priority priority) =>
      _failed[priority] = (_failed[priority] ?? 0) + 1;
  void incrementPermanentlyFailed(Priority priority) =>
      _permanentlyFailed[priority] = (_permanentlyFailed[priority] ?? 0) + 1;
  void incrementRetried(Priority priority) =>
      _retried[priority] = (_retried[priority] ?? 0) + 1;

  int getProcessedCount(Priority priority) => _processed[priority] ?? 0;
  int getFailedCount(Priority priority) => _failed[priority] ?? 0;
  int getPermanentlyFailedCount(Priority priority) =>
      _permanentlyFailed[priority] ?? 0;

  void reset() {
    for (var priority in Priority.values) {
      _queued[priority] = 0;
      _processed[priority] = 0;
      _failed[priority] = 0;
      _permanentlyFailed[priority] = 0;
      _retried[priority] = 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'queued': {
        for (var entry in _queued.entries) entry.key.toString(): entry.value
      },
      'processed': {
        for (var entry in _processed.entries) entry.key.toString(): entry.value
      },
      'failed': {
        for (var entry in _failed.entries) entry.key.toString(): entry.value
      },
      'permanentlyFailed': {
        for (var entry in _permanentlyFailed.entries)
          entry.key.toString(): entry.value
      },
      'retried': {
        for (var entry in _retried.entries) entry.key.toString(): entry.value
      },
    };
  }
}
