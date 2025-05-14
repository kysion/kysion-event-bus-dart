import 'dart:collection';

/// 对象池
///
/// 用于重用对象以减少内存分配和垃圾回收
class ObjectPool<T> {
  /// 对象工厂函数
  final T Function() _factory;

  /// 对象重置函数
  final void Function(T object)? _reset;

  /// 对象池大小
  final int _maxSize;

  /// 对象存储队列
  final Queue<T> _pool;

  /// 创建对象池
  ///
  /// [factory] 对象工厂函数
  /// [reset] 对象重置函数
  /// [initialSize] 初始池大小
  /// [maxSize] 最大池大小
  ObjectPool({
    required T Function() factory,
    void Function(T object)? reset,
    int initialSize = 0,
    int maxSize = 100,
  })  : _factory = factory,
        _reset = reset,
        _maxSize = maxSize,
        _pool = Queue<T>() {
    // 初始化对象池
    for (var i = 0; i < initialSize; i++) {
      _pool.add(_factory());
    }
  }

  /// 从池中获取对象
  T get() {
    if (_pool.isEmpty) {
      return _factory();
    }
    return _pool.removeFirst();
  }

  /// 将对象返回池中
  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
  }

  /// 清空对象池
  void clear() {
    _pool.clear();
  }

  /// 获取当前池大小
  int get size => _pool.length;

  /// 获取最大池大小
  int get maxSize => _maxSize;

  /// 批量获取对象
  List<T> getBatch(int count) {
    final batch = <T>[];
    for (var i = 0; i < count; i++) {
      batch.add(get());
    }
    return batch;
  }

  /// 批量释放对象
  void releaseBatch(List<T> objects) {
    for (var object in objects) {
      release(object);
    }
  }

  /// 预热对象池
  ///
  /// 创建指定数量的对象并添加到池中
  void warmup(int count) {
    final remaining = _maxSize - _pool.length;
    final actualCount = count < remaining ? count : remaining;

    for (var i = 0; i < actualCount; i++) {
      _pool.add(_factory());
    }
  }

  /// 调整池大小
  ///
  /// [newMaxSize] 新的最大池大小
  void resize(int newMaxSize) {
    while (_pool.length > newMaxSize) {
      _pool.removeLast();
    }
  }
}
