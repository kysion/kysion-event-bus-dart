import 'package:meta/meta.dart';
import 'priority.dart';
import 'event_metadata.dart';

/// 事件发送选项
///
/// 定义了事件发送时的各种选项，如优先级、超时、重试等
@immutable
class EmitOptions {
  /// 事件优先级
  final Priority priority;

  /// 发送超时时间
  final Duration? timeout;

  /// 是否启用追踪
  final bool enableTracing;

  /// 最大重试次数
  final int maxRetries;

  /// 重试间隔
  final Duration retryInterval;

  /// 事件元数据
  final EventMetadata? metadata;

  /// 创建发送选项
  ///
  /// [priority] 事件优先级，默认为普通优先级
  /// [timeout] 发送超时时间
  /// [enableTracing] 是否启用追踪，默认为false
  /// [maxRetries] 最大重试次数，默认为3次
  /// [retryInterval] 重试间隔，默认为1秒
  /// [metadata] 事件元数据
  const EmitOptions({
    this.priority = Priority.normal,
    this.timeout,
    this.enableTracing = false,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 1),
    this.metadata,
  });

  /// 创建新的选项实例，并覆盖指定的属性
  EmitOptions copyWith({
    Priority? priority,
    Duration? timeout,
    bool? enableTracing,
    int? maxRetries,
    Duration? retryInterval,
    EventMetadata? metadata,
  }) {
    return EmitOptions(
      priority: priority ?? this.priority,
      timeout: timeout ?? this.timeout,
      enableTracing: enableTracing ?? this.enableTracing,
      maxRetries: maxRetries ?? this.maxRetries,
      retryInterval: retryInterval ?? this.retryInterval,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 合并两个选项实例
  EmitOptions merge(EmitOptions other) {
    return copyWith(
      priority: other.priority,
      timeout: other.timeout,
      enableTracing: other.enableTracing,
      maxRetries: other.maxRetries,
      retryInterval: other.retryInterval,
      metadata: other.metadata,
    );
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'priority': priority.toString(),
      if (timeout != null) 'timeout': timeout!.inMilliseconds,
      'enableTracing': enableTracing,
      'maxRetries': maxRetries,
      'retryInterval': retryInterval.inMilliseconds,
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }

  /// 从JSON创建选项实例
  factory EmitOptions.fromJson(Map<String, dynamic> json) {
    return EmitOptions(
      priority: Priority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => Priority.normal,
      ),
      timeout: json['timeout'] != null
          ? Duration(milliseconds: json['timeout'] as int)
          : null,
      enableTracing: json['enableTracing'] as bool? ?? false,
      maxRetries: json['maxRetries'] as int? ?? 3,
      retryInterval:
          Duration(milliseconds: json['retryInterval'] as int? ?? 1000),
      metadata: json['metadata'] != null
          ? EventMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmitOptions &&
          runtimeType == other.runtimeType &&
          priority == other.priority &&
          timeout == other.timeout &&
          enableTracing == other.enableTracing &&
          maxRetries == other.maxRetries &&
          retryInterval == other.retryInterval &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      priority.hashCode ^
      timeout.hashCode ^
      enableTracing.hashCode ^
      maxRetries.hashCode ^
      retryInterval.hashCode ^
      metadata.hashCode;
}
