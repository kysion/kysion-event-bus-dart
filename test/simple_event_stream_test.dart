import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() {
  late KysionEventBus eventBus;
  late EventStream<int> eventStream;

  setUp(() {
    eventBus = KysionEventBus.simple();
    // 获取一个EventStream实例
    eventStream = eventBus.on<int>();
  });

  tearDown(() {
    eventBus.dispose();
  });

  group('EventStream 简化测试', () {
    test('应该能够获取EventStream实例', () {
      expect(eventStream, isNotNull);
      expect(eventStream.stream, isNotNull);
    });

    test('应该能够使用where过滤方法', () {
      final filteredStream = eventStream.where((event) => event % 2 == 0);
      expect(filteredStream, isNotNull);
    });

    test('应该能够使用transform转换方法', () {
      final transformedStream = eventStream.transform((event) => event * 2);
      expect(transformedStream, isNotNull);
    });

    test('应该能够使用withMetadata添加元数据', () {
      final metadata = EventMetadata(priority: Priority.high);
      final streamWithMetadata = eventStream.withMetadata(metadata);
      expect(streamWithMetadata, isNotNull);
    });

    test('应该能够使用withPriority设置优先级', () {
      final streamWithPriority = eventStream.withPriority(Priority.high);
      expect(streamWithPriority, isNotNull);
    });

    test('应该能够使用take方法', () {
      final limitedStream = eventStream.take(5);
      expect(limitedStream, isNotNull);
    });

    test('应该能够使用skip方法', () {
      final skippedStream = eventStream.skip(3);
      expect(skippedStream, isNotNull);
    });

    test('应该能够使用listen方法', () {
      final subscription = eventStream.listen((event) {
        // 空实现
      });
      expect(subscription, isNotNull);
      subscription.cancel();
    });
  });
}
