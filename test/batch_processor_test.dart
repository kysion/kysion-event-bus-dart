import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() {
  group('BatchProcessor 基础测试', () {
    test('应该使用指定的配置创建实例', () {
      final processor = BatchProcessor(
        minBatchSize: 5,
        maxBatchSize: 20,
        timeout: const Duration(seconds: 1),
      );

      expect(processor.minBatchSize, equals(5));
      expect(processor.maxBatchSize, equals(20));
      expect(processor.timeout, equals(const Duration(seconds: 1)));
      expect(processor.currentBatchSize, equals(5)); // 初始值应该是minBatchSize
    });

    test('应该抛出异常如果参数无效', () {
      expect(
        () => BatchProcessor(
          minBatchSize: 0, // 无效的最小批处理大小
          maxBatchSize: 10,
          timeout: const Duration(seconds: 1),
        ),
        throwsAssertionError,
      );

      expect(
        () => BatchProcessor(
          minBatchSize: 10,
          maxBatchSize: 5, // 最大值小于最小值
          timeout: const Duration(seconds: 1),
        ),
        throwsAssertionError,
      );
    });

    test('应该处理空列表而不抛出异常', () async {
      final processor = BatchProcessor(
        minBatchSize: 3,
        maxBatchSize: 10,
        timeout: const Duration(seconds: 1),
      );

      bool processorCalled = false;
      await processor.process<int>([], (batch) async {
        processorCalled = true;
        return Future.value();
      });

      expect(processorCalled, isFalse); // 处理函数不应该被调用
    });

    test('应该正确处理小于最小批次大小的列表', () async {
      final processor = BatchProcessor(
        minBatchSize: 5,
        maxBatchSize: 10,
        timeout: const Duration(seconds: 1),
      );

      final items = [1, 2, 3];
      final processedItems = <int>[];

      await processor.process<int>(items, (batch) async {
        processedItems.addAll(batch);
        return Future.value();
      });

      expect(processedItems, equals([1, 2, 3]));
      expect(processor.currentBatchSize, equals(5)); // 批处理大小应保持为最小值
    });

    test('应该按批次处理大列表', () async {
      final processor = BatchProcessor(
        minBatchSize: 3,
        maxBatchSize: 5,
        timeout: const Duration(seconds: 1),
      );

      final items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final processedBatches = <List<int>>[];

      await processor.process<int>(items, (batch) async {
        processedBatches.add(List.from(batch)); // 复制批次
        return Future.value();
      });

      // 验证分批处理
      expect(processedBatches.length, greaterThan(1)); // 应该有多个批次

      // 验证所有项目都被处理了
      final allProcessedItems =
          processedBatches.expand((batch) => batch).toList();
      expect(allProcessedItems, equals(items));
    });
  });
}
