import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

// 简单测试，验证库可以被导入和基本类可以被实例化
void main() {
  test('基本库类可以被实例化', () {
    // 验证EventBus可以创建
    final eventBus = KysionEventBus.simple();
    expect(eventBus, isNotNull);

    // 验证SmartDispatcher可以创建
    final dispatcher = SmartDispatcher(
        minBatchSize: 3,
        maxBatchSize: 10,
        batchTimeout: const Duration(milliseconds: 50));
    expect(dispatcher, isNotNull);

    // 验证BatchProcessor可以创建
    final batchProcessor = BatchProcessor(
        minBatchSize: 3,
        maxBatchSize: 10,
        timeout: const Duration(milliseconds: 100));
    expect(batchProcessor, isNotNull);

    // 验证CircuitBreaker可以创建
    final circuitBreaker = CircuitBreaker(
        failureThreshold: 3, resetTimeout: const Duration(milliseconds: 100));
    expect(circuitBreaker, isNotNull);

    // 验证EventTracer可以创建
    final tracer = EventTracer();
    expect(tracer, isNotNull);

    // 验证ObjectPool可以创建
    final pool = ObjectPool<String>(factory: () => 'test', reset: (obj) {});
    expect(pool, isNotNull);

    // 验证优先级枚举可用
    expect(Priority.values.length, equals(4));
    expect(Priority.high, isNotNull);

    // 验证元数据类可用
    final metadata = EventMetadata(priority: Priority.normal);
    expect(metadata, isNotNull);
  });
}
