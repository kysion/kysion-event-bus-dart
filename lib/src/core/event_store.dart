import '../models/event_metadata.dart';
import '../utils/platform_checker.dart';

/// 事件存储接口
///
/// 定义了事件存储的基本操作，仅支持内存存储
abstract class EventStore {
  /// 是否启用历史记录
  bool get historyEnabled;

  /// 存储事件
  ///
  /// [event] 要存储的事件
  /// [metadata] 事件元数据
  Future<void> store<T>(T event, EventMetadata metadata);

  /// 获取事件历史
  ///
  /// [type] 事件类型
  /// [limit] 限制返回的事件数量
  /// [offset] 跳过的事件数量
  Future<List<Map<String, dynamic>>> getHistory<T>({
    int? limit,
    int? offset,
  });

  /// 清除事件历史
  ///
  /// [type] 事件类型，如果为null则清除所有类型的事件
  /// [before] 清除该时间之前的事件
  Future<void> clearHistory<T>({DateTime? before});

  /// 获取事件统计信息
  ///
  /// [type] 事件类型
  Future<Map<String, dynamic>> getStats<T>();

  /// 关闭存储
  Future<void> close();
}

/// 内存事件存储
///
/// 使用内存存储事件，适用于临时存储和测试
class MemoryEventStore implements EventStore {
  final Map<Type, List<Map<String, dynamic>>> _store = {};
  final int _maxSize;
  final bool _historyEnabled;

  /// 创建内存事件存储
  ///
  /// [maxSize] 最大存储大小
  /// [historyEnabled] 是否启用历史记录，默认为false
  MemoryEventStore({
    int? maxSize,
    bool historyEnabled = false,
  })  : _maxSize =
            maxSize ?? PlatformChecker.getPlatformConfig()['maxHistorySize'],
        _historyEnabled = historyEnabled &&
            PlatformChecker.isFeatureSupported(Feature.eventHistory);

  @override
  bool get historyEnabled => _historyEnabled;

  @override
  Future<void> store<T>(T event, EventMetadata metadata) async {
    if (!_historyEnabled) return;

    final events = _store.putIfAbsent(T, () => []);
    events.add({
      'event': event,
      'metadata': metadata.toJson(),
    });

    // 保持存储大小
    if (events.length > _maxSize) {
      events.removeAt(0);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory<T>({
    int? limit,
    int? offset,
  }) async {
    if (!_historyEnabled) return [];

    final events = _store[T] ?? [];
    final start = offset ?? 0;
    final end = limit != null ? start + limit : events.length;
    return events.sublist(start, end);
  }

  @override
  Future<void> clearHistory<T>({DateTime? before}) async {
    if (!_historyEnabled) return;

    if (before == null) {
      if (T == dynamic) {
        _store.clear();
      } else {
        _store.remove(T);
      }
      return;
    }

    final events = _store[T];
    if (events != null) {
      events.removeWhere((e) {
        final metadata = EventMetadata.fromJson(e['metadata']);
        return metadata.createdAt.isBefore(before);
      });
    }
  }

  @override
  Future<Map<String, dynamic>> getStats<T>() async {
    if (!_historyEnabled) {
      return {
        'total': 0,
        'type': T.toString(),
        'historyEnabled': false,
      };
    }

    final events = _store[T] ?? [];
    return {
      'total': events.length,
      'type': T.toString(),
      'historyEnabled': true,
      'maxSize': _maxSize,
      'platform': PlatformChecker.currentPlatform.toString(),
    };
  }

  @override
  Future<void> close() async {
    _store.clear();
  }
}

/// 持久化事件存储
///
/// 使用文件系统或数据库持久化存储事件
abstract class PersistentEventStore implements EventStore {
  /// 初始化存储
  Future<void> initialize();

  /// 压缩存储
  Future<void> compact();

  /// 备份存储
  Future<void> backup(String path);

  /// 从备份恢复
  Future<void> restore(String path);
}
