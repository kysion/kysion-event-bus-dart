import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

// 用于测试的测试对象类
class TestObject {
  int count = 0;
  void increment() => count++;
  void reset() => count = 0;
}

void main() {
  group('ObjectPool 基础测试', () {
    test('应该能够创建ObjectPool实例', () {
      final pool = ObjectPool<String>(
        factory: () => 'test',
        reset: (obj) {},
      );

      expect(pool, isNotNull);
      expect(pool.size, equals(0));
      expect(pool.maxSize, equals(100)); // 默认最大值
    });

    test('应该能够获取和释放对象', () {
      // 创建一个简单对象的对象池
      final pool = ObjectPool<List<int>>(
        factory: () => <int>[],
        reset: (list) => list.clear(),
      );

      // 获取对象
      final obj1 = pool.get();
      expect(obj1, isA<List<int>>());
      expect(obj1.isEmpty, isTrue);

      // 添加数据并释放
      obj1.add(1);
      obj1.add(2);
      pool.release(obj1);

      // 再次获取对象（应该是同一个实例，但被重置）
      final obj2 = pool.get();
      expect(obj2.isEmpty, isTrue); // 应被重置

      // 清理
      pool.clear();
    });

    test('应该有最大容量限制', () {
      final creationCounter = <int>[];

      // 创建最大容量为2的对象池
      final pool = ObjectPool<String>(
        factory: () {
          creationCounter.add(1);
          return 'object ${creationCounter.length}';
        },
        reset: (obj) {},
        maxSize: 2,
      );

      // 获取和释放3个对象
      final obj1 = pool.get();
      final obj2 = pool.get();
      final obj3 = pool.get();

      pool.release(obj1);
      pool.release(obj2);
      pool.release(obj3);

      // 应该只创建了3个对象
      expect(creationCounter.length, equals(3));

      // 池容量应该是2（最大值）
      expect(pool.size, equals(2));

      // 清理
      pool.clear();
    });

    test('应该正确重置对象', () {
      // 创建对象池
      final pool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        reset: (obj) => obj.reset(),
      );

      // 获取对象并修改状态
      final obj = pool.get();
      obj.increment();
      obj.increment();
      expect(obj.count, equals(2));

      // 释放对象
      pool.release(obj);

      // 再次获取，应该被重置
      final sameObj = pool.get();
      expect(sameObj.count, equals(0));

      // 清理
      pool.clear();
    });

    test('应该支持批量操作', () {
      var createCount = 0;

      final pool = ObjectPool<String>(
        factory: () {
          createCount++;
          return 'instance $createCount';
        },
        reset: (obj) {},
        initialSize: 2, // 预创建2个对象
      );

      // 初始池大小应该是2
      expect(pool.size, equals(2));

      // 批量获取
      final batch = pool.getBatch(3); // 应该获取2个池中对象和1个新创建的
      expect(batch.length, equals(3));
      expect(createCount, equals(3)); // 总共创建了3个

      // 批量释放
      pool.releaseBatch(batch);
      expect(pool.size, equals(3)); // 所有对象都返回池中

      // 清理
      pool.clear();
      expect(pool.size, equals(0));
    });

    test('应该支持预热功能', () {
      var createCount = 0;

      final pool = ObjectPool<int>(
        factory: () {
          createCount++;
          return createCount;
        },
        reset: (obj) {},
        maxSize: 10,
      );

      // 初始池为空
      expect(pool.size, equals(0));

      // 预热5个对象
      pool.warmup(5);

      // 池大小应该是5
      expect(pool.size, equals(5));
      expect(createCount, equals(5));

      // 预热超过最大容量的对象
      pool.warmup(10);

      // 池大小应该是最大值
      expect(pool.size, equals(10));
      expect(createCount, equals(10));

      // 清理
      pool.clear();
    });

    test('应该支持调整池大小', () {
      final pool = ObjectPool<int>(
        factory: () => 0,
        reset: (obj) {},
        initialSize: 10,
        maxSize: 20,
      );

      // 初始池大小应该是10
      expect(pool.size, equals(10));

      // 减小池大小
      pool.resize(5);

      // 池应该被调整为5
      expect(pool.size, equals(5));

      // 增加池大小 - 仅改变maxSize不会影响当前size
      pool.resize(15);

      // 池大小仍然是5
      expect(pool.size, equals(5));

      // 清理
      pool.clear();
    });

    test('应该在多次获取和释放时正确维护池', () {
      var createCount = 0;

      final pool = ObjectPool<int>(
        factory: () {
          createCount++;
          return createCount;
        },
        reset: (obj) {},
        maxSize: 3,
      );

      // 进行多次获取和释放操作
      final values = <int>[];

      // 首次获取3个对象
      for (var i = 0; i < 3; i++) {
        values.add(pool.get());
      }

      // 应该创建了3个对象
      expect(createCount, equals(3));
      expect(pool.size, equals(0));

      // 释放所有对象
      for (var value in values) {
        pool.release(value);
      }

      // 池大小应该是3
      expect(pool.size, equals(3));

      // 再次获取5个对象
      values.clear();
      for (var i = 0; i < 5; i++) {
        values.add(pool.get());
      }

      // 应该只新创建了2个对象
      expect(createCount, equals(5));

      // 再次释放，但池最大容量是3
      for (var value in values) {
        pool.release(value);
      }

      // 池大小应该是最大值3
      expect(pool.size, equals(3));

      // 清理
      pool.clear();
    });

    test('应该能处理空的重置函数', () {
      final pool = ObjectPool<String>(
        factory: () => 'test',
        // 不提供重置函数
      );

      final obj = pool.get();
      expect(obj, equals('test'));

      // 释放对象不应抛出异常
      expect(() => pool.release(obj), returnsNormally);

      // 清理
      pool.clear();
    });
  });
}
