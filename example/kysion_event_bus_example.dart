import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() async {
  print('\n===== 基本功能演示 =====');

  // 创建事件总线实例（使用工厂方法）
  final eventBus = KysionEventBus.forCurrentPlatform();

  // 获取平台信息
  final platformInfo = eventBus.getPlatformInfo();
  print('\n平台信息:');
  print('当前平台: ${platformInfo['platform']}');
  print('是否Web平台: ${platformInfo['isWeb']}');
  print('是否移动平台: ${platformInfo['isMobile']}');
  print('是否桌面平台: ${platformInfo['isDesktop']}');
  print('功能支持: ${platformInfo['features']}');
  print('平台配置: ${platformInfo['config']}');
  print('调度器状态: ${platformInfo['dispatcherStatus']}');

  // 设置全局错误处理器
  eventBus.setErrorHandler((error, stackTrace) {
    print('\n全局错误处理:');
    print('错误: $error');
    print('堆栈: $stackTrace');
  });

  // 启用轻量级元数据以提高性能
  eventBus.enableLightweightMetadata(true);
  print('\n轻量级元数据已启用: ${eventBus.getPlatformInfo()['useLightweightMetadata']}');

  // 定义用户登录事件
  final loginEvent = UserLoginEvent(
    userId: 'user123',
    username: 'zhangsan',
    loginMethod: 'password',
    timestamp: DateTime.now(),
    metadata: EventMetadata(
      priority: Priority.high,
      source: 'mobile_app',
      extra: {'version': '1.0.0'},
    ),
  );

  // 订阅用户登录事件
  final subscription = eventBus
      .on<UserLoginEvent>()
      .where((event) => event.loginMethod == 'password')
      .listen(
    (event) {
      print('\n收到事件:');
      print('用户登录: ${event.userId}');
      print('用户名: ${event.username}');
      print('登录方式: ${event.loginMethod}');
      print('时间: ${event.timestamp}');
      print('元数据: ${event.metadata.toJson()}');
    },
    onError: (error) {
      print('处理事件错误: $error');
    },
  );

  // 发送事件
  await eventBus.emit(
    loginEvent,
    options: EmitOptions(
      priority: Priority.high,
      enableTracing: true,
    ),
  );

  // 延迟发送事件
  print('\n延迟发送事件 (1秒后)...');
  await eventBus.fireDelayed(
    UserLoginEvent(
      userId: 'user456',
      username: 'lisi',
      loginMethod: 'password',
      timestamp: DateTime.now(),
      metadata: EventMetadata(priority: Priority.normal),
    ),
    Duration(seconds: 1),
  );

  // 不等待结果的发送
  print('\n发送并忘记...');
  eventBus.fireAndForget(
    UserLoginEvent(
      userId: 'user789',
      username: 'wangwu',
      loginMethod: 'password',
      timestamp: DateTime.now(),
      metadata: EventMetadata(priority: Priority.low),
    ),
  );

  // 获取性能指标
  await Future.delayed(Duration(milliseconds: 500)); // 等待指标收集
  final metrics = eventBus.getMetrics('UserLoginEvent');
  print('\n性能指标:');
  print(metrics);

  // 获取错误统计
  final errorStats = eventBus.getErrorStats('UserLoginEvent');
  print('\n错误统计:');
  print(errorStats);

  print('\n===== 历史记录功能演示 =====');

  // 创建启用历史记录的事件总线
  final eventBusWithHistory = KysionEventBus.withHistory();
  print(
      '\n历史记录是否启用: ${eventBusWithHistory.getPlatformInfo()['historyEnabled']}');

  // 发送事件并检查历史记录
  await eventBusWithHistory.emit(loginEvent);
  await eventBusWithHistory.emit(
    UserLoginEvent(
      userId: 'historyUser',
      username: 'history',
      loginMethod: 'oauth',
      timestamp: DateTime.now(),
      metadata: EventMetadata(priority: Priority.normal),
    ),
  );

  final history = await eventBusWithHistory.getHistory<UserLoginEvent>();
  print('\n事件历史记录:');
  print('历史记录数量: ${history.length}');
  for (var i = 0; i < history.length; i++) {
    final record = history[i];
    final event = record['event'];
    print(
        '${i + 1}. 用户: ${event['userId']}, 用户名: ${event['username']}, 方式: ${event['loginMethod']}');
  }

  print('\n===== 批处理与优先级演示 =====');

  // 创建高性能事件总线
  final perfBus = KysionEventBus.forPerformance();
  print('\n批处理配置:');
  print(perfBus.getPlatformInfo()['dispatcherStatus']);

  // 发送批量事件
  print('\n发送批量事件 (50个)...');
  final batchEvents = <UserLoginEvent>[];
  for (var i = 0; i < 50; i++) {
    final priority = i % 10 == 0
        ? Priority.high
        : (i % 5 == 0 ? Priority.critical : Priority.normal);

    batchEvents.add(UserLoginEvent(
      userId: 'batch_user_$i',
      username: 'batch$i',
      loginMethod: 'batch',
      timestamp: DateTime.now(),
      metadata: EventMetadata(priority: priority),
    ));
  }

  // 使用批量发送API
  final results = await perfBus.emitBatch(batchEvents);
  print('批量发送结果: ${results.where((r) => r).length}/${results.length} 成功');

  print('\n===== 高级功能演示 =====');

  // 创建调试模式事件总线
  final debugBus = KysionEventBus.forDebugging();

  // 使用防抖和节流
  final searchSubscription = debugBus
      .on<SearchEvent>()
      .debounce(Duration(milliseconds: 300))
      .listen((event) {
    print('\n搜索事件 (防抖后): ${event.keyword}');
  });

  final scrollSubscription = debugBus
      .on<ScrollEvent>()
      .throttle(Duration(milliseconds: 200))
      .listen((event) {
    print('\n滚动事件 (节流后): ${event.position}');
  });

  // 发送多个快速连续的搜索事件
  print('\n发送连续搜索事件 (应该只收到最后一个)...');
  for (var i = 0; i < 5; i++) {
    debugBus.emit(SearchEvent('关键词 $i'));
    await Future.delayed(Duration(milliseconds: 50));
  }

  // 发送多个快速连续的滚动事件
  print('\n发送连续滚动事件 (应该收到部分)...');
  for (var i = 0; i < 10; i++) {
    debugBus.emit(ScrollEvent(i * 100.0));
    await Future.delayed(Duration(milliseconds: 50));
  }

  // 使用事件流转换
  final userNameSubscription = debugBus
      .onTransform<UserLoginEvent, String>((event) => '用户: ${event.username}')
      .listen((username) {
    print('\n转换后的事件数据: $username');
  });

  debugBus.emit(UserLoginEvent(
    userId: 'transform123',
    username: 'transform_user',
    loginMethod: 'social',
    timestamp: DateTime.now(),
    metadata: EventMetadata(priority: Priority.normal),
  ));

  // 演示工作流顺序事件
  print('\n===== 工作流顺序事件演示 =====');
  final workflowBus = KysionEventBus.simple();

  workflowBus.on<WorkflowEvent>().listen((event) {
    print('工作流步骤 ${event.sequence}: ${event.step}');
  });

  final workflowSuccess = await workflowBus.emitSequence([
    WorkflowEvent('开始处理', 1),
    WorkflowEvent('验证数据', 2),
    WorkflowEvent('保存结果', 3),
    WorkflowEvent('完成', 4),
  ]);

  print('工作流完成状态: ${workflowSuccess ? "成功" : "失败"}');

  // 等待完成所有异步操作
  await Future.delayed(Duration(seconds: 2));

  // 清理资源
  await subscription.cancel();
  await searchSubscription.cancel();
  await scrollSubscription.cancel();
  await userNameSubscription.cancel();
  await eventBus.dispose();
  await eventBusWithHistory.dispose();
  await perfBus.dispose();
  await debugBus.dispose();
  await workflowBus.dispose();
}

// 用户登录事件
class UserLoginEvent {
  final String userId;
  final String username;
  final String loginMethod;
  final DateTime timestamp;
  final EventMetadata metadata;

  const UserLoginEvent({
    required this.userId,
    required this.username,
    required this.loginMethod,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'loginMethod': loginMethod,
        'timestamp': timestamp.toIso8601String(),
      };

  // 工厂构造函数
  factory UserLoginEvent.password(String userId, String username) {
    return UserLoginEvent(
      userId: userId,
      username: username,
      loginMethod: 'password',
      timestamp: DateTime.now(),
      metadata: EventMetadata(priority: Priority.high),
    );
  }
}

// 搜索事件
class SearchEvent {
  final String keyword;

  SearchEvent(this.keyword);
}

// 滚动事件
class ScrollEvent {
  final double position;

  ScrollEvent(this.position);
}

// 工作流事件
class WorkflowEvent {
  final String step;
  final int sequence;

  WorkflowEvent(this.step, this.sequence);
}
