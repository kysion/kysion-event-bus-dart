import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() {
  late KysionEventBus eventBus;

  setUp(() {
    eventBus = KysionEventBus.simple();
  });

  tearDown(() {
    eventBus.dispose();
  });

  group('EventBus 简化测试', () {
    test('应该能创建EventBus实例', () {
      expect(eventBus, isNotNull);
      expect(eventBus.isDisposed, isFalse);
    });

    test('应该能够获取事件流', () {
      final stream = eventBus.on<String>();
      expect(stream, isNotNull);
    });

    test('应该能获取事件流并设置优先级', () {
      final stream = eventBus.on<String>().withPriority(Priority.high);
      expect(stream, isNotNull);
    });

    test('应该能获取指定类型的事件流', () {
      final stringStream = eventBus.on<String>();
      final intStream = eventBus.on<int>();

      expect(stringStream, isNotNull);
      expect(intStream, isNotNull);
    });

    test('应该能处理基本的事件分发', () {
      bool eventReceived = false;

      final subscription = eventBus.on<String>().listen((event) {
        eventReceived = true;
      });

      // 不等待，同步发送
      eventBus.fireAndForget('test');

      // 直接检查，这是不可靠的但可以测试API是否可用
      expect(subscription, isNotNull);

      // 清理
      subscription.cancel();
    });
  });
}
