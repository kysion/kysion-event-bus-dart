import 'package:meta/meta.dart';
import 'event_metadata.dart';

/// 可追踪事件基类
///
/// 为事件提供追踪功能，包含事件元数据和序列化能力
@immutable
abstract class TracedEvent {
  /// 事件元数据
  final EventMetadata metadata;

  /// 创建可追踪事件
  ///
  /// [metadata] 事件元数据
  const TracedEvent({
    required this.metadata,
  });

  /// 转换为JSON格式
  ///
  /// 子类需要实现此方法以提供事件数据的序列化
  Map<String, dynamic> toJson();

  /// 从JSON创建事件实例
  ///
  /// 子类需要实现此方法以提供事件数据的反序列化
  factory TracedEvent.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('TracedEvent.fromJson() must be implemented');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TracedEvent &&
          runtimeType == other.runtimeType &&
          metadata == other.metadata;

  @override
  int get hashCode => metadata.hashCode;
}

/// 示例：用户登录事件
class UserLoginEvent extends TracedEvent {
  /// 用户ID
  final String userId;

  /// 登录时间
  final DateTime loginTime;

  /// 登录设备
  final String device;

  /// 创建用户登录事件
  ///
  /// [userId] 用户ID
  /// [loginTime] 登录时间
  /// [device] 登录设备
  /// [metadata] 事件元数据
  const UserLoginEvent({
    required this.userId,
    required this.loginTime,
    required this.device,
    required super.metadata,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'loginTime': loginTime.toIso8601String(),
      'device': device,
      'metadata': metadata.toJson(),
    };
  }

  /// 从JSON创建用户登录事件
  factory UserLoginEvent.fromJson(Map<String, dynamic> json) {
    return UserLoginEvent(
      userId: json['userId'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      device: json['device'] as String,
      metadata:
          EventMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is UserLoginEvent &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          loginTime == other.loginTime &&
          device == other.device;

  @override
  int get hashCode =>
      super.hashCode ^ userId.hashCode ^ loginTime.hashCode ^ device.hashCode;
}
