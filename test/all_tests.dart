import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

// 独立组件测试
import 'basic_test.dart' as basic_test;
import 'circuit_breaker_test.dart' as circuit_breaker_test;
import 'batch_processor_test.dart' as batch_processor_test;
import 'object_pool_test.dart' as object_pool_test;

// 依赖EventBus的组件测试
import 'smart_dispatcher_test.dart' as smart_dispatcher_test;
import 'event_tracer_test.dart' as event_tracer_test;

// 简化的API测试
import 'simple_event_bus_test.dart' as simple_event_bus_test;
import 'simple_event_stream_test.dart' as simple_event_stream_test;
import 'event_stream_test.dart' as event_stream_test;
import 'event_bus_test.dart' as event_bus_test;

void main() {
  group('kysion_event_bus 测试套件', () {
    // 1. 基础类型测试 - 不涉及事件总线
    group('基础类型测试', () {
      basic_test.main();
    });

    // 2. 独立组件测试 - 不依赖事件总线
    group('独立组件测试', () {
      circuit_breaker_test.main();
      batch_processor_test.main();
      object_pool_test.main();
    });

    // 3. 事件总线依赖组件测试
    group('事件总线依赖组件测试', () {
      smart_dispatcher_test.main();
      event_tracer_test.main();
    });

    // 4. 简化API测试 - 基本验证
    group('简化API测试', () {
      // 执行简化版的测试
      simple_event_bus_test.main();
      simple_event_stream_test.main();
    });

    // 5. 完整API测试 - 包含异步行为
    group('完整API测试', () {
      // 执行完整版但更健壮的测试
      event_stream_test.main();
      event_bus_test.main();
    });
  });

  test('库可以被正确导入和初始化', () {
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
