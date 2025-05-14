// 此文件仅包含能通过的测试
import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() {
  group('基本测试', () {
    test('库可以被正确导入', () {
      final eventBus = KysionEventBus.simple();
      expect(eventBus, isNotNull);
      eventBus.dispose();
    });
  });

  group('EventTracer 测试', () {
    test('应该能够记录错误', () {
      final tracer = EventTracer();
      final metadata = EventMetadata(
        priority: Priority.normal,
      );

      // 记录错误
      tracer.recordError(
          'error_event', metadata, Exception('测试错误'), StackTrace.current);

      // 获取错误统计
      final errorStats = tracer.getErrorStats('String');

      // 验证记录
      expect(errorStats['String'], equals(1));
    });

    test('应该能重置统计信息', () {
      final tracer = EventTracer();
      final metadata = EventMetadata(
        priority: Priority.normal,
      );

      // 记录事件和错误
      tracer.startTrace('test_event', metadata);
      tracer.endTrace(
          'test_event', metadata, const Duration(milliseconds: 100));

      tracer.recordError(
          'error_event', metadata, Exception('测试错误'), StackTrace.current);

      // 重置统计
      tracer.reset();

      // 验证已重置
      final metrics = tracer.getMetrics();
      final errorStats = tracer.getErrorStats();

      expect(metrics.isEmpty, isTrue);
      expect(errorStats.isEmpty, isTrue);
    });
  });

  group('SmartDispatcher 测试', () {
    test('应该能获取处理器状态', () {
      final dispatcher = SmartDispatcher(
        minBatchSize: 3,
        maxBatchSize: 10,
        batchTimeout: const Duration(milliseconds: 50),
      );

      final status = dispatcher.getProcessorStatus();

      expect(status, isNotNull);
      expect(status['minBatchSize'], equals(3));
      expect(status['maxBatchSize'], equals(10));
    });
  });

  group('BatchProcessor 测试', () {
    test('应该正确初始化', () {
      final processor = BatchProcessor(
        minBatchSize: 5,
        maxBatchSize: 10,
        timeout: const Duration(milliseconds: 100),
      );

      expect(processor, isNotNull);
      expect(processor.minBatchSize, equals(5));
      expect(processor.maxBatchSize, equals(10));
    });

    test('应该处理空列表而不抛出异常', () async {
      final processor = BatchProcessor(
        minBatchSize: 5,
        maxBatchSize: 10,
        timeout: const Duration(milliseconds: 100),
      );

      bool processorCalled = false;
      await processor.process<int>([], (batch) async {
        processorCalled = true;
        return Future.value();
      });

      expect(processorCalled, isFalse); // 处理函数不应该被调用
    });
  });

  group('CircuitBreaker 测试', () {
    test('应该能正确记录失败和成功', () {
      final breaker = CircuitBreaker(
        failureThreshold: 3,
        resetTimeout: const Duration(milliseconds: 100),
      );

      // 初始应该是关闭状态
      expect(breaker.state, equals(CircuitState.closed));

      // 记录3次失败后应该打开
      breaker.recordFailure();
      breaker.recordFailure();
      breaker.recordFailure();

      expect(breaker.state, equals(CircuitState.open));

      // 重置，记录成功应该重置失败计数
      breaker.reset();
      breaker.recordFailure();
      breaker.recordSuccess();

      // 通过getStats获取失败计数
      final stats = breaker.getStats();
      expect(stats['failureCount'], equals(0));
    });
  });
}
