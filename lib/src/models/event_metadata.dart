import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'priority.dart';

/// 事件元数据类型
enum MetadataType {
  /// 完整元数据
  full,

  /// 轻量级元数据
  lightweight,

  /// 追踪元数据
  trace,

  /// 调试元数据
  debug,
}

/// 事件元数据
///
/// 包含事件的追踪信息、优先级、时间戳等元数据
@immutable
class EventMetadata {
  /// 事件唯一标识符
  final String id;

  /// 事件优先级
  final Priority priority;

  /// 事件创建时间
  final DateTime createdAt;

  /// 事件处理时间
  final DateTime? processedAt;

  /// 事件来源
  final String? source;

  /// 事件追踪ID
  final String? traceId;

  /// 父事件ID
  final String? parentId;

  /// 额外的元数据
  final Map<String, dynamic>? extra;

  /// 事件类型名称
  final String? eventTypeName;

  /// 元数据类型
  final MetadataType type;

  /// 创建事件元数据
  ///
  /// [priority] 事件优先级，默认为普通优先级
  /// [source] 事件来源
  /// [traceId] 事件追踪ID
  /// [parentId] 父事件ID
  /// [extra] 额外的元数据
  /// [eventTypeName] 事件类型名称
  /// [type] 元数据类型
  EventMetadata({
    String? id,
    this.priority = Priority.normal,
    this.source,
    this.traceId,
    this.parentId,
    this.extra,
    this.eventTypeName,
    DateTime? createdAt,
    this.processedAt,
    this.type = MetadataType.full,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 创建轻量级元数据
  factory EventMetadata.lightweight({
    required Priority priority,
  }) {
    return EventMetadata(
      priority: priority,
      type: MetadataType.lightweight,
    );
  }

  /// 创建追踪元数据
  factory EventMetadata.forTracing({
    required Priority priority,
    required String source,
    String? traceId,
    String? parentId,
  }) {
    return EventMetadata(
      priority: priority,
      source: source,
      traceId: traceId ?? const Uuid().v4(),
      parentId: parentId,
      type: MetadataType.trace,
    );
  }

  /// 创建调试元数据
  factory EventMetadata.forDebugging({
    required Priority priority,
    required String source,
    required String eventTypeName,
    Map<String, dynamic>? extra,
  }) {
    return EventMetadata(
      priority: priority,
      source: source,
      eventTypeName: eventTypeName,
      extra: extra,
      traceId: const Uuid().v4(),
      type: MetadataType.debug,
    );
  }

  /// 从事件对象创建元数据
  static EventMetadata fromEvent(
    dynamic event, {
    Priority priority = Priority.normal,
    MetadataType type = MetadataType.full,
  }) {
    return EventMetadata(
      priority: priority,
      eventTypeName: event.runtimeType.toString(),
      type: type,
    );
  }

  /// 创建新的元数据实例，并更新处理时间
  EventMetadata copyWithProcessed() {
    return EventMetadata(
      id: id,
      priority: priority,
      source: source,
      traceId: traceId,
      parentId: parentId,
      extra: extra,
      eventTypeName: eventTypeName,
      createdAt: createdAt,
      processedAt: DateTime.now(),
      type: type,
    );
  }

  /// 创建新的元数据实例，并合并额外的元数据
  EventMetadata copyWithExtra(Map<String, dynamic> newExtra) {
    return EventMetadata(
      id: id,
      priority: priority,
      source: source,
      traceId: traceId,
      parentId: parentId,
      extra: {...?extra, ...newExtra},
      eventTypeName: eventTypeName,
      createdAt: createdAt,
      processedAt: processedAt,
      type: type,
    );
  }

  /// 创建链接的元数据（用于事件级联）
  EventMetadata createLinked({String? newSource}) {
    return EventMetadata(
      priority: priority,
      source: newSource ?? source,
      traceId: traceId,
      parentId: id, // 当前ID变为父ID
      eventTypeName: eventTypeName,
      type: type,
    );
  }

  /// 获取处理延迟
  Duration? get processingDelay {
    if (processedAt == null) return null;
    return processedAt!.difference(createdAt);
  }

  /// 检查元数据是否为轻量级
  bool get isLightweight => type == MetadataType.lightweight;

  /// 检查元数据是否包含追踪信息
  bool get hasTracing => traceId != null;

  /// 检查是否为高优先级
  bool get isHighPriority => priority.index >= Priority.high.index;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'priority': priority.toString(),
      'createdAt': createdAt.toIso8601String(),
      'type': type.toString(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (source != null) 'source': source,
      if (traceId != null) 'traceId': traceId,
      if (parentId != null) 'parentId': parentId,
      if (eventTypeName != null) 'eventTypeName': eventTypeName,
      if (extra != null) 'extra': extra,
    };
  }

  /// 从JSON创建元数据实例
  factory EventMetadata.fromJson(Map<String, dynamic> json) {
    return EventMetadata(
      id: json['id'] as String,
      priority: Priority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => Priority.normal,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      source: json['source'] as String?,
      traceId: json['traceId'] as String?,
      parentId: json['parentId'] as String?,
      eventTypeName: json['eventTypeName'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
      type: json['type'] != null
          ? MetadataType.values.firstWhere(
              (t) => t.toString() == json['type'],
              orElse: () => MetadataType.full,
            )
          : MetadataType.full,
    );
  }

  /// 转换为简化版本的Map
  Map<String, dynamic> toSimpleMap() {
    if (type == MetadataType.lightweight) {
      return {
        'id': id,
        'priority': priority.toString(),
        'createdAt': createdAt.toIso8601String(),
      };
    }

    return {
      'id': id,
      'priority': priority.toString(),
      'createdAt': createdAt.toIso8601String(),
      if (source != null) 'source': source,
      if (traceId != null) 'traceId': traceId,
      if (eventTypeName != null) 'type': eventTypeName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          priority == other.priority &&
          createdAt == other.createdAt &&
          processedAt == other.processedAt &&
          source == other.source &&
          traceId == other.traceId &&
          parentId == other.parentId &&
          eventTypeName == other.eventTypeName &&
          type == other.type;

  @override
  int get hashCode =>
      id.hashCode ^
      priority.hashCode ^
      createdAt.hashCode ^
      processedAt.hashCode ^
      source.hashCode ^
      traceId.hashCode ^
      parentId.hashCode ^
      (eventTypeName?.hashCode ?? 0) ^
      type.hashCode;

  @override
  String toString() {
    if (type == MetadataType.lightweight) {
      return 'EventMetadata(id: $id, priority: $priority)';
    }

    return 'EventMetadata(id: $id, priority: $priority, '
        'createdAt: $createdAt, source: $source, '
        'traceId: $traceId, type: $type${eventTypeName != null ? ', eventType: $eventTypeName' : ''})';
  }
}
