/// 熔断器状态
enum CircuitState {
  /// 关闭状态：允许请求通过
  closed,

  /// 开启状态：阻止请求通过
  open,

  /// 半开状态：允许部分请求通过以测试系统
  halfOpen,
}

/// 熔断器
///
/// 用于防止系统过载，当失败率达到阈值时自动切断请求
class CircuitBreaker {
  /// 失败计数器
  int _failureCount = 0;

  /// 连续成功计数器
  int _successCount = 0;

  /// 当前状态
  CircuitState _state = CircuitState.closed;

  /// 上次状态改变时间
  DateTime? _lastStateChange;

  /// 失败阈值
  final int failureThreshold;

  /// 重置超时时间
  final Duration resetTimeout;

  /// 半开状态下的成功阈值
  final int halfOpenSuccessThreshold;

  /// 状态改变监听器
  final void Function(CircuitState)? onStateChange;

  /// 创建熔断器
  ///
  /// [failureThreshold] 失败阈值
  /// [resetTimeout] 重置超时时间
  /// [halfOpenSuccessThreshold] 半开状态下的成功阈值
  /// [onStateChange] 状态改变监听器
  CircuitBreaker({
    required this.failureThreshold,
    required this.resetTimeout,
    this.halfOpenSuccessThreshold = 5,
    this.onStateChange,
  }) {
    _lastStateChange = DateTime.now();
  }

  /// 是否允许请求通过
  bool get isAllowed {
    _checkState();
    return _state != CircuitState.open;
  }

  /// 获取当前状态
  CircuitState get state => _state;

  /// 记录成功
  void recordSuccess() {
    if (_state == CircuitState.halfOpen) {
      _successCount++;
      if (_successCount >= halfOpenSuccessThreshold) {
        _transitionTo(CircuitState.closed);
      }
    }
    _failureCount = 0;
  }

  /// 记录失败
  void recordFailure() {
    _failureCount++;
    _successCount = 0;

    if (_state == CircuitState.closed && _failureCount >= failureThreshold) {
      _transitionTo(CircuitState.open);
    }
  }

  /// 检查状态
  void _checkState() {
    if (_state == CircuitState.open &&
        DateTime.now().difference(_lastStateChange!) >= resetTimeout) {
      _transitionTo(CircuitState.halfOpen);
    }
  }

  /// 转换状态
  void _transitionTo(CircuitState newState) {
    if (_state == newState) return;

    _state = newState;
    _lastStateChange = DateTime.now();
    _failureCount = 0;
    _successCount = 0;

    onStateChange?.call(newState);
  }

  /// 重置熔断器
  void reset() {
    _transitionTo(CircuitState.closed);
  }

  /// 强制开启熔断器
  void forceOpen() {
    _transitionTo(CircuitState.open);
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'state': _state.toString(),
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastStateChange': _lastStateChange?.toIso8601String(),
    };
  }
}
