import 'package:logging/logging.dart';
import '../models/event_metadata.dart';

/// 事件追踪器
///
/// 用于追踪事件的生命周期、性能指标和错误信息
class EventTracer {
  /// 日志记录器
  final Logger _logger;

  /// 性能指标收集器
  final _metrics = <String, List<Duration>>{};

  /// 错误计数器
  final _errorCounts = <String, int>{};

  /// 创建事件追踪器
  ///
  /// [name] 追踪器名称
  EventTracer({String name = 'EventTracer'}) : _logger = Logger(name);

  /// 开始追踪事件
  ///
  /// [event] 要追踪的事件
  /// [metadata] 事件元数据
  void startTrace<T>(T event, EventMetadata metadata) {
    _logger.info('开始处理事件: ${event.runtimeType}', {
      'eventId': metadata.id,
      'traceId': metadata.traceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 结束追踪事件
  ///
  /// [event] 要追踪的事件
  /// [metadata] 事件元数据
  /// [duration] 处理时长
  void endTrace<T>(T event, EventMetadata metadata, Duration duration) {
    final eventType = event.runtimeType.toString();

    // 记录性能指标
    _metrics.putIfAbsent(eventType, () => []).add(duration);

    _logger.info('完成处理事件: $eventType', {
      'eventId': metadata.id,
      'traceId': metadata.traceId,
      'duration': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 记录错误
  ///
  /// [event] 发生错误的事件
  /// [metadata] 事件元数据
  /// [error] 错误信息
  /// [stackTrace] 堆栈跟踪
  void recordError<T>(
    T event,
    EventMetadata metadata,
    Object error,
    StackTrace stackTrace,
  ) {
    final eventType = event.runtimeType.toString();

    // 增加错误计数
    _errorCounts[eventType] = (_errorCounts[eventType] ?? 0) + 1;

    final errorInfo = {
      'eventId': metadata.id,
      'traceId': metadata.traceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.severe('事件处理错误: $eventType', error, stackTrace);
    _logger.info('错误详情: $errorInfo');
  }

  /// 获取性能指标
  ///
  /// [eventType] 事件类型
  Map<String, dynamic> getMetrics([String? eventType]) {
    if (eventType != null) {
      final durations = _metrics[eventType] ?? [];
      if (durations.isEmpty) {
        return {'eventType': eventType, 'metrics': {}};
      }

      return {
        'eventType': eventType,
        'metrics': _calculateMetrics(durations),
      };
    }

    return {
      for (var entry in _metrics.entries)
        entry.key: _calculateMetrics(entry.value),
    };
  }

  /// 计算性能指标
  Map<String, dynamic> _calculateMetrics(List<Duration> durations) {
    if (durations.isEmpty) return {};

    durations.sort();
    final total = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );

    return {
      'count': durations.length,
      'min': durations.first.inMilliseconds,
      'max': durations.last.inMilliseconds,
      'avg': total / durations.length,
      'p95': durations[(durations.length * 0.95).floor()].inMilliseconds,
      'p99': durations[(durations.length * 0.99).floor()].inMilliseconds,
    };
  }

  /// 获取错误统计
  Map<String, int> getErrorStats([String? eventType]) {
    if (eventType != null) {
      return {eventType: _errorCounts[eventType] ?? 0};
    }
    return Map.unmodifiable(_errorCounts);
  }

  /// 重置统计信息
  void reset() {
    _metrics.clear();
    _errorCounts.clear();
  }

  /// 设置日志级别
  void setLogLevel(Level level) {
    hierarchicalLoggingEnabled = true;
    _logger.level = level;
  }

  /// 添加日志处理器
  void addLogHandler(void Function(LogRecord) handler) {
    _logger.onRecord.listen(handler);
  }
}
