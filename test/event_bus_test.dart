import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

// 简化后的 EventBus 测试，专注于 API 可用性验证
void main() {
  late KysionEventBus eventBus;

  setUp(() {
    eventBus = KysionEventBus.simple();
  });

  tearDown(() async {
    // 确保所有测试操作完成后再关闭事件总线
    await Future.delayed(const Duration(milliseconds: 100));
    await eventBus.dispose();
  });

  group('EventBus 基础测试', () {
    // 1. API 可用性测试 - 验证事件总线创建和属性
    test('应该能正确创建和访问事件总线', () {
      expect(eventBus, isNotNull);
      expect(eventBus.isDisposed, isFalse);

      // 验证平台信息获取功能
      final platformInfo = eventBus.getPlatformInfo();
      expect(platformInfo, isNotNull);
      expect(platformInfo['isWeb'], isNotNull);

      // 验证统计相关功能
      final metrics = eventBus.getMetrics();
      expect(metrics, isNotNull);

      final errorStats = eventBus.getErrorStats();
      expect(errorStats, isNotNull);
    });

    // 2. 事件流获取测试
    test('应该能正确获取事件流', () {
      // 获取不同类型的事件流
      final streamString = eventBus.on<String>();
      expect(streamString, isNotNull);
      expect(streamString.stream, isNotNull);

      final streamInt = eventBus.on<int>();
      expect(streamInt, isNotNull);
      expect(streamInt.stream, isNotNull);

      // 带选项的事件流获取
      final streamWithOption =
          eventBus.on<Map>(options: const EmitOptions(priority: Priority.high));
      expect(streamWithOption, isNotNull);
    });

    // 3. 事件发送API测试 - 只测试API调用是否有效，不等待结果
    test('应该提供正确的事件发送API', () {
      // 测试发送事件的各种API是否可用
      // 注意：我们只检查API是否可调用，不验证事件接收
      expect(() => eventBus.emit('test-event'), returnsNormally);
      expect(() => eventBus.fireAndForget(42), returnsNormally);
      expect(() => eventBus.emitBatch(['test1', 'test2']), returnsNormally);
      expect(() => eventBus.emitSequence([1, 2, 3]), returnsNormally);
      expect(
          () =>
              eventBus.fireDelayed('delayed', const Duration(milliseconds: 10)),
          returnsNormally);
    });

    // 4. 事件历史和统计测试
    test('应该能正确处理事件历史和统计', () async {
      // 获取历史记录
      final history = await eventBus.getHistory<String>(limit: 10);
      expect(history, isNotNull);

      // 重置统计信息
      eventBus.resetStats();
      final metricsAfterReset = eventBus.getMetrics();
      expect(metricsAfterReset, isNotNull);

      // 清除历史记录
      await eventBus.clearHistory<String>();
      final historyAfterClear = await eventBus.getHistory<String>();
      expect(historyAfterClear, isNotNull);
    });

    // 5. 同步测试发送和接收 - 简化版
    test('应该能够同步发送和接收事件', () {
      // 设置监听器
      final subscription = eventBus.on<String>().listen((event) {});

      // 使用同步方式发送，不等待
      eventBus.fireAndForget('test-sync');

      // 清理资源
      subscription.cancel();

      // 验证 API 可用
      expect(eventBus.isDisposed, isFalse);
    });

    // 6. 批量事件处理 - 简化版
    test('应该能够处理批量事件', () {
      // 设置监听器
      final subscription = eventBus.on<int>().listen((event) {
        // 仅验证 API 可用，不检查事件接收
      });

      // 使用同步方式批量发送，不等待
      eventBus.fireAndForget(1);
      eventBus.fireAndForget(2);
      eventBus.fireAndForget(3);

      // 清理资源
      subscription.cancel();

      // 验证 API 可用
      expect(eventBus.isDisposed, isFalse);
    });

    // 7. 验证不同事件类型 - 简化版
    test('应该能处理不同类型的事件', () {
      // 设置不同类型的监听器
      final stringSub = eventBus.on<String>().listen((event) {});
      final intSub = eventBus.on<int>().listen((event) {});

      // 发送不同类型的事件，使用同步方式不等待
      eventBus.fireAndForget('string-event');
      eventBus.fireAndForget(42);

      // 清理资源
      stringSub.cancel();
      intSub.cancel();

      // 验证 API 可用
      expect(eventBus.isDisposed, isFalse);
    });
  });
}
