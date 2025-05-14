import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 平台类型枚举
enum PlatformType {
  web,
  android,
  ios,
  macOS,
  windows,
  linux,
  unknown,
}

/// 功能特性枚举
enum Feature {
  eventHistory,
  batchProcessing,
  priorityQueue,
  tracing,
  persistence,
  encryption,
  compression,
  remoteLogging,
}

/// 平台性能等级
enum PerformanceTier {
  low, // 低性能设备
  medium, // 中等性能设备
  high, // 高性能设备
}

/// 平台配置
class PlatformConfig {
  /// 最大历史记录大小
  final int maxHistorySize;

  /// 最小批处理大小
  final int minBatchSize;

  /// 最大批处理大小
  final int maxBatchSize;

  /// 批处理超时
  final Duration batchTimeout;

  /// 是否启用事件跟踪
  final bool enableTracing;

  /// 是否使用轻量级元数据
  final bool useLightweightMetadata;

  /// 是否启用压缩
  final bool enableCompression;

  /// 是否启用远程日志
  final bool enableRemoteLogging;

  /// 创建平台配置
  const PlatformConfig({
    required this.maxHistorySize,
    required this.minBatchSize,
    required this.maxBatchSize,
    required this.batchTimeout,
    this.enableTracing = true,
    this.useLightweightMetadata = false,
    this.enableCompression = false,
    this.enableRemoteLogging = false,
  });

  /// 创建配置副本
  PlatformConfig copyWith({
    int? maxHistorySize,
    int? minBatchSize,
    int? maxBatchSize,
    Duration? batchTimeout,
    bool? enableTracing,
    bool? useLightweightMetadata,
    bool? enableCompression,
    bool? enableRemoteLogging,
  }) {
    return PlatformConfig(
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
      minBatchSize: minBatchSize ?? this.minBatchSize,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      batchTimeout: batchTimeout ?? this.batchTimeout,
      enableTracing: enableTracing ?? this.enableTracing,
      useLightweightMetadata:
          useLightweightMetadata ?? this.useLightweightMetadata,
      enableCompression: enableCompression ?? this.enableCompression,
      enableRemoteLogging: enableRemoteLogging ?? this.enableRemoteLogging,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'maxHistorySize': maxHistorySize,
      'minBatchSize': minBatchSize,
      'maxBatchSize': maxBatchSize,
      'batchTimeout': batchTimeout.inMilliseconds,
      'enableTracing': enableTracing,
      'useLightweightMetadata': useLightweightMetadata,
      'enableCompression': enableCompression,
      'enableRemoteLogging': enableRemoteLogging,
    };
  }
}

/// 平台支持检查工具
class PlatformChecker {
  /// 自定义平台配置
  static PlatformConfig? _customConfig;

  /// 设置自定义平台配置
  static void setCustomConfig(PlatformConfig config) {
    _customConfig = config;
  }

  /// 清除自定义平台配置
  static void clearCustomConfig() {
    _customConfig = null;
  }

  /// 是否是 Web 平台
  static bool get isWeb => kIsWeb;

  /// 是否是移动平台
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 是否是桌面平台
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// 是否是iOS平台
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// 是否是Android平台
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// 是否是macOS平台
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// 是否是Windows平台
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// 是否是Linux平台
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// 获取当前平台类型
  static PlatformType get currentPlatform {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isMacOS) return PlatformType.macOS;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }

  /// 检查特定功能是否支持
  static bool isFeatureSupported(Feature feature) {
    switch (feature) {
      case Feature.eventHistory:
        // Web 平台限制历史记录大小
        if (kIsWeb) return true;
        // 移动平台支持但需要注意内存
        if (isMobile) return true;
        // 桌面平台完全支持
        if (isDesktop) return true;
        return false;

      case Feature.batchProcessing:
        // 所有平台都支持批处理
        return true;

      case Feature.priorityQueue:
        // 所有平台都支持优先级队列
        return true;

      case Feature.tracing:
        // 所有平台都支持追踪
        return true;

      case Feature.persistence:
        // Web平台通过localStorage支持有限的持久化
        if (kIsWeb) return true;
        // 移动和桌面平台支持完整持久化
        return true;

      case Feature.encryption:
        // 所有平台都支持加密
        return true;

      case Feature.compression:
        // Web平台可能有性能限制
        if (kIsWeb) return true;
        // 其他平台完全支持
        return true;

      case Feature.remoteLogging:
        // 所有平台都支持远程日志
        return true;
    }
  }

  /// 获取平台性能等级
  static PerformanceTier getPerformanceTier() {
    if (kIsWeb) {
      // Web平台按中等性能处理
      return PerformanceTier.medium;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台按中等性能处理，实际项目中可以根据设备型号判断
      return PerformanceTier.medium;
    }

    // 桌面平台按高性能处理
    return PerformanceTier.high;
  }

  /// 获取平台特定的配置
  static Map<String, dynamic> getPlatformConfig() {
    // 如果有自定义配置，优先使用
    if (_customConfig != null) {
      return _customConfig!.toMap();
    }

    final performanceTier = getPerformanceTier();

    if (kIsWeb) {
      switch (performanceTier) {
        case PerformanceTier.low:
          return {
            'maxHistorySize': 200,
            'minBatchSize': 3,
            'maxBatchSize': 20,
            'batchTimeout': const Duration(milliseconds: 100),
            'enableTracing': false,
            'useLightweightMetadata': true,
            'enableCompression': false,
            'enableRemoteLogging': false,
          };
        case PerformanceTier.medium:
          return {
            'maxHistorySize': 500,
            'minBatchSize': 5,
            'maxBatchSize': 50,
            'batchTimeout': const Duration(milliseconds: 50),
            'enableTracing': true,
            'useLightweightMetadata': true,
            'enableCompression': false,
            'enableRemoteLogging': false,
          };
        case PerformanceTier.high:
          return {
            'maxHistorySize': 1000,
            'minBatchSize': 10,
            'maxBatchSize': 100,
            'batchTimeout': const Duration(milliseconds: 30),
            'enableTracing': true,
            'useLightweightMetadata': false,
            'enableCompression': true,
            'enableRemoteLogging': true,
          };
      }
    }

    if (isMobile) {
      switch (performanceTier) {
        case PerformanceTier.low:
          return {
            'maxHistorySize': 500,
            'minBatchSize': 5,
            'maxBatchSize': 50,
            'batchTimeout': const Duration(milliseconds: 150),
            'enableTracing': false,
            'useLightweightMetadata': true,
            'enableCompression': false,
            'enableRemoteLogging': false,
          };
        case PerformanceTier.medium:
          return {
            'maxHistorySize': 1000,
            'minBatchSize': 10,
            'maxBatchSize': 100,
            'batchTimeout': const Duration(milliseconds: 100),
            'enableTracing': true,
            'useLightweightMetadata': true,
            'enableCompression': false,
            'enableRemoteLogging': true,
          };
        case PerformanceTier.high:
          return {
            'maxHistorySize': 2000,
            'minBatchSize': 20,
            'maxBatchSize': 200,
            'batchTimeout': const Duration(milliseconds: 50),
            'enableTracing': true,
            'useLightweightMetadata': false,
            'enableCompression': true,
            'enableRemoteLogging': true,
          };
      }
    }

    if (isDesktop) {
      switch (performanceTier) {
        case PerformanceTier.low:
          return {
            'maxHistorySize': 2000,
            'minBatchSize': 10,
            'maxBatchSize': 100,
            'batchTimeout': const Duration(milliseconds: 250),
            'enableTracing': true,
            'useLightweightMetadata': true,
            'enableCompression': false,
            'enableRemoteLogging': true,
          };
        case PerformanceTier.medium:
          return {
            'maxHistorySize': 5000,
            'minBatchSize': 20,
            'maxBatchSize': 200,
            'batchTimeout': const Duration(milliseconds: 200),
            'enableTracing': true,
            'useLightweightMetadata': false,
            'enableCompression': true,
            'enableRemoteLogging': true,
          };
        case PerformanceTier.high:
          return {
            'maxHistorySize': 10000,
            'minBatchSize': 50,
            'maxBatchSize': 500,
            'batchTimeout': const Duration(milliseconds: 100),
            'enableTracing': true,
            'useLightweightMetadata': false,
            'enableCompression': true,
            'enableRemoteLogging': true,
          };
      }
    }

    // 默认配置
    return {
      'maxHistorySize': 1000,
      'minBatchSize': 10,
      'maxBatchSize': 100,
      'batchTimeout': const Duration(milliseconds: 100),
      'enableTracing': true,
      'useLightweightMetadata': false,
      'enableCompression': false,
      'enableRemoteLogging': false,
    };
  }

  /// 获取配置对象
  static PlatformConfig getConfig() {
    final map = getPlatformConfig();
    return PlatformConfig(
      maxHistorySize: map['maxHistorySize'],
      minBatchSize: map['minBatchSize'],
      maxBatchSize: map['maxBatchSize'],
      batchTimeout: Duration(
          milliseconds: map['batchTimeout'] is Duration
              ? (map['batchTimeout'] as Duration).inMilliseconds
              : map['batchTimeout']),
      enableTracing: map['enableTracing'] ?? true,
      useLightweightMetadata: map['useLightweightMetadata'] ?? false,
      enableCompression: map['enableCompression'] ?? false,
      enableRemoteLogging: map['enableRemoteLogging'] ?? false,
    );
  }
}
