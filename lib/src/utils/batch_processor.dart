import 'dart:async';

/// 批处理器
///
/// 用于批量处理事件，支持动态批处理大小和超时处理
class BatchProcessor {
  /// 最小批处理大小
  final int minBatchSize;

  /// 最大批处理大小
  final int maxBatchSize;

  /// 批处理超时时间
  final Duration timeout;

  /// 当前批处理大小
  int _currentBatchSize;

  /// 批处理计时器
  Timer? _batchTimer;

  /// 创建批处理器
  ///
  /// [minBatchSize] 最小批处理大小
  /// [maxBatchSize] 最大批处理大小
  /// [timeout] 批处理超时时间
  BatchProcessor({
    required this.minBatchSize,
    required this.maxBatchSize,
    required this.timeout,
  }) : _currentBatchSize = minBatchSize {
    assert(minBatchSize > 0, 'minBatchSize must be greater than 0');
    assert(maxBatchSize >= minBatchSize,
        'maxBatchSize must be greater than or equal to minBatchSize');
  }

  /// 处理批量事件
  ///
  /// [items] 要处理的事件列表
  /// [processor] 处理函数
  Future<void> process<T>(
    List<T> items,
    Future<void> Function(List<T> batch) processor,
  ) async {
    if (items.isEmpty) return;

    // 调整批处理大小
    _adjustBatchSize(items.length);

    // 分批处理
    for (var i = 0; i < items.length; i += _currentBatchSize) {
      final end = (i + _currentBatchSize < items.length)
          ? i + _currentBatchSize
          : items.length;
      final batch = items.sublist(i, end);

      // 创建超时
      final completer = Completer<void>();
      _batchTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Batch processing timeout', timeout),
          );
        }
      });

      try {
        // 处理批次
        await processor(batch);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      } finally {
        _batchTimer?.cancel();
      }

      // 等待完成或超时
      await completer.future;
    }
  }

  /// 调整批处理大小
  ///
  /// 根据处理项数量动态调整批处理大小
  void _adjustBatchSize(int itemCount) {
    if (itemCount <= minBatchSize) {
      _currentBatchSize = minBatchSize;
    } else if (itemCount >= maxBatchSize) {
      _currentBatchSize = maxBatchSize;
    } else {
      // 动态调整批处理大小
      _currentBatchSize = (itemCount * 0.75).round().clamp(
            minBatchSize,
            maxBatchSize,
          );
    }
  }

  /// 获取当前批处理大小
  int get currentBatchSize => _currentBatchSize;

  /// 销毁批处理器
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }
}
