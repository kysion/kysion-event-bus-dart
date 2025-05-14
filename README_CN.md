# Kysion Event Bus

[English](README.md) | 中文

高性能、响应式的事件总线库，为Flutter应用提供强大的事件处理能力。Kysion Event Bus采用响应式设计，支持优先级队列、智能批处理、跨平台自适应和完整的事件追踪功能，是构建复杂Flutter应用的理想选择。

## 主要特性

- **响应式设计**：基于Stream的完全响应式API，支持链式调用和声明式编程风格
- **智能事件调度**：优先级管理与批处理自动优化，确保关键事件优先处理
- **平台自适应**：自动检测并适配Web、移动和桌面平台，针对不同平台优化配置
- **高性能**：类型缓存、轻量级元数据、批处理和并发控制等多重性能优化
- **事件追踪**：内置事件追踪和性能监控，方便调试和性能分析
- **功能丰富的流API**：支持防抖、节流、过滤、转换、合并等多种流操作
- **强大的错误处理**：全局和本地错误处理机制，内置智能重试策略和熔断保护
- **类型安全**：完全类型安全的事件订阅和发布，编译时类型检查

## 最近优化

- **增强API设计**：添加了丰富的工厂方法和便捷方法
- **强化事件流功能**：添加了防抖、节流、过滤、变换等流操作
- **改进平台检测**：增强了平台检测，支持性能等级适配
- **优化元数据管理**：添加了多种元数据类型，支持轻量级和调试模式
- **增强安全性**：添加了状态检查和资源管理功能
- **增强配置系统**：支持自定义配置和多种预设配置

## 安装

在`pubspec.yaml`文件中添加依赖：

```yaml
dependencies:
  kysion_event_bus: ^1.0.2
```

然后运行：

```bash
flutter pub get
```

## 核心概念

### 事件总线

事件总线是中央事件处理器，负责事件的发布、订阅、调度和存储。

### 事件流

事件流是特定类型事件的观察者，支持过滤、转换和其他流操作。

### 事件元数据

元数据包含事件的附加信息，如优先级、时间戳和来源等。

### 优先级

事件优先级决定处理顺序，高优先级事件会优先处理。

## 快速开始

### 创建事件总线

```dart
import 'package:kysion_event_bus/kysion_event_bus.dart';

// 创建基本事件总线
final eventBus = KysionEventBus.simple();

// 创建适合当前平台的事件总线
final eventBus = KysionEventBus.forCurrentPlatform();

// 创建高性能事件总线
final eventBus = KysionEventBus.forPerformance();

// 创建调试版本事件总线
final eventBus = KysionEventBus.forDebugging();
```

### 定义事件类

```dart
// 用户事件基类
abstract class UserEvent {
  final String userId;
  
  UserEvent(this.userId);
}

// 用户登录事件
class UserLoggedInEvent extends UserEvent {
  final String username;
  final DateTime loginTime;
  
  UserLoggedInEvent(String userId, this.username)
      : loginTime = DateTime.now(),
        super(userId);
}

// 用户退出事件
class UserLoggedOutEvent extends UserEvent {
  final DateTime logoutTime;
  
  UserLoggedOutEvent(String userId)
      : logoutTime = DateTime.now(),
        super(userId);
}
```

### 订阅事件

```dart
// 基本订阅
final subscription = eventBus.on<UserLoggedInEvent>().listen((event) {
  print('用户登录: ${event.username}, 用户ID: ${event.userId}');
});

// 使用过滤器
eventBus.onWhere<UserEvent>(
  (event) => event.userId == '123'
).listen((event) {
  print('用户123的事件: ${event.runtimeType}');
});

// 转换事件
eventBus.onTransform<UserLoggedInEvent, String>(
  (event) => '${event.username}|${event.userId}'
).listen((userInfo) {
  print('用户信息: $userInfo');
});

// 事件防抖（例如搜索输入）
class SearchEvent {
  final String keyword;
  SearchEvent(this.keyword);
}

eventBus.on<SearchEvent>()
  .debounce(Duration(milliseconds: 300))
  .listen((event) {
    print('搜索: ${event.keyword}');
    // 执行实际搜索操作
  });
  
// 事件节流（例如滚动事件）
class ScrollEvent {
  final double position;
  ScrollEvent(this.position);
}

eventBus.on<ScrollEvent>()
  .throttle(Duration(milliseconds: 100))
  .listen((event) {
    print('滚动位置: ${event.position}');
    // 更新UI或加载更多内容
  });
  
// 组合操作
eventBus.on<UserEvent>()
  .where((event) => event is UserLoggedInEvent)
  .transform((event) => event as UserLoggedInEvent)
  .where((event) => event.username.contains('admin'))
  .listen((adminEvent) {
    print('管理员登录: ${adminEvent.username}');
  });
```

### 发布事件

```dart
// 基本发布
eventBus.emit(UserLoggedInEvent('user123', 'zhangsan'));

// 发布高优先级事件
class SystemErrorEvent {
  final String message;
  SystemErrorEvent(this.message);
}

eventBus.emit(
  SystemErrorEvent('连接失败'),
  options: const EmitOptions(priority: Priority.critical)
);

// 延迟发布
class NotificationEvent {
  final String message;
  NotificationEvent(this.message);
}

eventBus.fireDelayed(
  NotificationEvent('会议提醒'),
  Duration(minutes: 5)
);

// 批量发布
class OrderCreatedEvent {
  final String orderId;
  OrderCreatedEvent(this.orderId);
}

eventBus.emitBatch([
  OrderCreatedEvent('ORDER-001'),
  OrderCreatedEvent('ORDER-002'),
  OrderCreatedEvent('ORDER-003'),
]);

// 顺序发布（如果其中一个失败则停止）
class WorkflowEvent {
  final String step;
  final int sequence;
  
  WorkflowEvent(this.step, this.sequence);
}

final workflowSuccess = await eventBus.emitSequence([
  WorkflowEvent('开始处理', 1),
  WorkflowEvent('验证数据', 2),
  WorkflowEvent('保存结果', 3),
  WorkflowEvent('完成', 4),
]);

if (workflowSuccess) {
  print('工作流程完成');
} else {
  print('工作流程失败');
}
```

### 使用元数据

```dart
// 使用自定义元数据
final metadata = EventMetadata(
  priority: Priority.high,
  source: 'payment_service',
  traceId: 'tx-${DateTime.now().millisecondsSinceEpoch}',
  extra: {'region': 'CN', 'channel': 'mobile'},
);

class PaymentEvent {
  final String orderId;
  final double amount;
  
  PaymentEvent(this.orderId, this.amount);
}

// 使用元数据发布事件
eventBus.emit(
  PaymentEvent('ORDER-001', 99.9),
  options: EmitOptions(metadata: metadata)
);

// 轻量级元数据（减少内存占用）
final lightMetadata = EventMetadata.lightweight(
  priority: Priority.normal,
);

// 调试元数据（包含更多信息）
final debugMetadata = EventMetadata.forDebugging(
  priority: Priority.high,
  source: 'debug_service',
  eventTypeName: 'PaymentEvent',
  extra: {'debug': true, 'testCase': 'TC-001'},
);
```

## 实际应用示例

### 表单验证

```dart
// 表单事件
class FormFieldChangedEvent {
  final String fieldName;
  final dynamic value;
  
  FormFieldChangedEvent(this.fieldName, this.value);
}

class FormValidationService {
  final KysionEventBus _eventBus = KysionEventBus.simple();
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};
  
  FormValidationService() {
    // 监听字段变化并进行验证
    _eventBus.on<FormFieldChangedEvent>()
      .debounce(Duration(milliseconds: 300)) // 防抖，避免频繁验证
      .listen(_validateField);
  }
  
  void updateField(String fieldName, dynamic value) {
    _formData[fieldName] = value;
    _eventBus.emit(FormFieldChangedEvent(fieldName, value));
  }
  
  void _validateField(FormFieldChangedEvent event) {
    // 根据字段名称验证
    switch (event.fieldName) {
      case 'email':
        _validateEmail(event.value as String?);
        break;
      case 'password':
        _validatePassword(event.value as String?);
        break;
      // 其他字段...
    }
    
    // 通知UI更新
    _eventBus.emit(FormValidationResultEvent(_errors));
  }
  
  void _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      _errors['email'] = '请输入邮箱';
    } else if (!email.contains('@')) {
      _errors['email'] = '邮箱格式不正确';
    } else {
      _errors.remove('email');
    }
  }
  
  void _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      _errors['password'] = '请输入密码';
    } else if (password.length < 6) {
      _errors['password'] = '密码长度不能少于6位';
    } else {
      _errors.remove('password');
    }
  }
}

class FormValidationResultEvent {
  final Map<String, String?> errors;
  FormValidationResultEvent(this.errors);
}
```

### 状态管理

```dart
// 简单状态管理器
class EventBusStore<T> {
  final KysionEventBus _eventBus;
  final T _initialState;
  T _state;
  
  EventBusStore(this._eventBus, this._initialState) : _state = _initialState;
  
  T get state => _state;
  
  // 监听特定事件并更新状态
  void on<E>(T Function(T currentState, E event) reducer) {
    _eventBus.on<E>().listen((event) {
      final newState = reducer(_state, event);
      if (newState != _state) {
        _state = newState;
        _eventBus.emit(StateChangedEvent<T>(_state));
      }
    });
  }
  
  // 派发状态变更
  void dispatch<E>(E event) {
    _eventBus.emit(event);
  }
}

// 使用示例: 购物车
class CartState {
  final List<CartItem> items;
  final double totalPrice;
  
  CartState(this.items, this.totalPrice);
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  
  CartItem(this.id, this.name, this.price, this.quantity);
}

// 购物车事件
class AddToCartEvent {
  final CartItem item;
  AddToCartEvent(this.item);
}

class RemoveFromCartEvent {
  final String itemId;
  RemoveFromCartEvent(this.itemId);
}

class UpdateQuantityEvent {
  final String itemId;
  final int quantity;
  UpdateQuantityEvent(this.itemId, this.quantity);
}

class StateChangedEvent<T> {
  final T state;
  StateChangedEvent(this.state);
}

// 初始化购物车
final eventBus = KysionEventBus.simple();
final cartStore = EventBusStore<CartState>(eventBus, CartState([], 0.0));

// 设置状态更新逻辑
void initCartStore() {
  // 添加商品
  cartStore.on<AddToCartEvent>((state, event) {
    final items = List<CartItem>.from(state.items);
    final existingIndex = items.indexWhere((i) => i.id == event.item.id);
    
    if (existingIndex >= 0) {
      // 更新数量
      final existing = items[existingIndex];
      items[existingIndex] = CartItem(
        existing.id, 
        existing.name, 
        existing.price, 
        existing.quantity + event.item.quantity
      );
    } else {
      // 添加新商品
      items.add(event.item);
    }
    
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return CartState(items, totalPrice);
  });
  
  // 移除商品
  cartStore.on<RemoveFromCartEvent>((state, event) {
    final items = List<CartItem>.from(state.items)
        ..removeWhere((item) => item.id == event.itemId);
    
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return CartState(items, totalPrice);
  });
  
  // 更新数量
  cartStore.on<UpdateQuantityEvent>((state, event) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((i) => i.id == event.itemId);
    
    if (index >= 0) {
      final item = items[index];
      items[index] = CartItem(item.id, item.name, item.price, event.quantity);
    }
    
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return CartState(items, totalPrice);
  });
  
  // 监听状态变化
  eventBus.on<StateChangedEvent<CartState>>().listen((event) {
    print('购物车更新: ${event.state.items.length}件商品, 总价: ${event.state.totalPrice}');
    // 更新UI
  });
}
```

### 网络请求管理

```dart
// 网络请求事件
class ApiRequestEvent {
  final String endpoint;
  final Map<String, dynamic> data;
  final String requestId;
  
  ApiRequestEvent(this.endpoint, this.data)
      : requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
}

class ApiResponseEvent {
  final String requestId;
  final Map<String, dynamic>? data;
  final String? error;
  
  ApiResponseEvent(this.requestId, {this.data, this.error});
}

class ApiService {
  final KysionEventBus _eventBus;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  
  ApiService(this._eventBus) {
    // 监听API请求
    _eventBus.on<ApiRequestEvent>().listen(_handleApiRequest);
    
    // 监听API响应
    _eventBus.on<ApiResponseEvent>().listen(_handleApiResponse);
  }
  
  // 发送API请求并返回Future
  Future<Map<String, dynamic>> request(String endpoint, Map<String, dynamic> data) {
    final requestEvent = ApiRequestEvent(endpoint, data);
    final completer = Completer<Map<String, dynamic>>();
    
    _pendingRequests[requestEvent.requestId] = completer;
    
    // 使用高优先级发送API请求
    _eventBus.emit(
      requestEvent,
      options: const EmitOptions(
        priority: Priority.high,
        enableTracing: true, // 启用追踪便于调试
      ),
    );
    
    return completer.future;
  }
  
  // 处理API请求
  void _handleApiRequest(ApiRequestEvent event) async {
    try {
      // 模拟网络请求
      await Future.delayed(Duration(milliseconds: 500));
      
      // 模拟响应数据
      final responseData = {
        'success': true,
        'data': {'id': 123, 'timestamp': DateTime.now().toIso8601String()},
        'endpoint': event.endpoint,
      };
      
      // 发送响应事件
      _eventBus.emit(ApiResponseEvent(event.requestId, data: responseData));
    } catch (e) {
      // 发送错误响应
      _eventBus.emit(ApiResponseEvent(event.requestId, error: e.toString()));
    }
  }
  
  // 处理API响应
  void _handleApiResponse(ApiResponseEvent event) {
    final completer = _pendingRequests.remove(event.requestId);
    
    if (completer != null) {
      if (event.error != null) {
        completer.completeError(event.error!);
      } else if (event.data != null) {
        completer.complete(event.data!);
      } else {
        completer.completeError('无效响应');
      }
    }
  }
}

// 使用示例
void apiExample() async {
  final eventBus = KysionEventBus.forPerformance();
  final apiService = ApiService(eventBus);
  
  try {
    final result = await apiService.request('/users', {'name': 'zhangsan'});
    print('API请求成功: $result');
  } catch (e) {
    print('API请求失败: $e');
  }
}
```

## 高级功能

### 事件追踪和性能监控

```dart
// 获取性能指标
final metrics = eventBus.getMetrics();
print('平均处理时间: ${metrics['averageProcessingTimeMs']}ms');
print('处理事件数: ${metrics['totalProcessed']}');
print('最慢事件: ${metrics['slowestEvent']}');

// 获取错误统计
final errorStats = eventBus.getErrorStats();
print('错误总数: ${errorStats['total']}');
print('按类型统计: ${errorStats['byType']}');

// 按事件类型获取指标
final userEventMetrics = eventBus.getMetrics('UserLoggedInEvent');
print('用户登录事件平均处理时间: ${userEventMetrics['averageProcessingTimeMs']}ms');
```

### 事件历史

```dart
// 获取特定类型的事件历史
final history = await eventBus.getHistory<UserLoggedInEvent>(limit: 10);

for (final item in history) {
  print('用户登录: ${item['event']['username']}');
  print('时间: ${item['metadata']['createdAt']}');
}

// 清除历史记录
await eventBus.clearHistory<UserLoggedInEvent>(
  before: DateTime.now().subtract(Duration(days: 7))
);
```

### 自定义配置

```dart
// 设置自定义平台配置
PlatformChecker.setCustomConfig(
  PlatformConfig(
    maxHistorySize: 2000,
    minBatchSize: 20,
    maxBatchSize: 200,
    batchTimeout: Duration(milliseconds: 100),
    useLightweightMetadata: true,
    enableTracing: true,
    enableCompression: false,
    enableRemoteLogging: false,
  )
);

// 使用自定义配置创建事件总线
final customConfig = EventBusConfig(
  historyEnabled: true,
  dispatcherConfig: SmartDispatcherConfig(
    minBatchSize: 15,
    maxBatchSize: 150,
    batchTimeout: Duration(milliseconds: 75),
    adaptiveThreshold: true,
  ),
  errorHandler: (error, stackTrace) {
    print('自定义错误处理: $error');
    // 记录到日志系统
  },
);

final eventBus = KysionEventBus.withConfig(customConfig);
```

## 最佳实践

### 组件生命周期管理

在Flutter组件中使用事件总线时，确保正确管理订阅生命周期：

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final KysionEventBus _eventBus;
  late final List<StreamSubscription> _subscriptions;
  
  @override
  void initState() {
    super.initState();
    _eventBus = KysionEventBus.forCurrentPlatform();
    _subscriptions = [];
    
    // 添加订阅
    _subscriptions.add(
      _eventBus.on<UserEvent>().listen((event) {
        // 处理事件
      })
    );
    
    _subscriptions.add(
      _eventBus.on<NotificationEvent>().listen((event) {
        // 处理通知
      })
    );
  }
  
  @override
  void dispose() {
    // 取消所有订阅
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 构建UI
    return Container();
  }
}
```

### 优先级使用建议

- **关键优先级 (Priority.critical)**
  - 安全相关操作：用户认证、权限变更
  - 核心状态改变：应用状态重置、重要配置更改
  - 系统错误：连接中断、数据损坏

- **高优先级 (Priority.high)**
  - 用户交互反馈：表单提交、按钮点击响应
  - 关键业务逻辑：支付处理、订单确认
  - 数据同步：本地到服务器的重要数据同步

- **普通优先级 (Priority.normal)**
  - 一般UI更新：列表刷新、非关键视图更新
  - 常规业务逻辑：非核心功能的处理
  - 默认优先级：大多数应用事件

- **低优先级 (Priority.low)**
  - 日志记录：应用使用统计、行为跟踪
  - 分析数据收集：用户行为分析、性能指标采集
  - 后台任务：预加载、缓存清理

### 高效事件设计

定义良好的事件类能提高代码可读性和可维护性：

```dart
// 良好的事件设计
class UserLoginEvent extends TracedEvent {
  final String userId;
  final String username;
  final String loginMethod;
  final DateTime timestamp;
  
  const UserLoginEvent({
    required this.userId,
    required this.username,
    required this.loginMethod,
    required this.timestamp,
    required super.metadata,
  });
  
  @override
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
  
  factory UserLoginEvent.socialMedia(String userId, String username, String provider) {
    return UserLoginEvent(
      userId: userId,
      username: username,
      loginMethod: provider,
      timestamp: DateTime.now(),
      metadata: EventMetadata(
        priority: Priority.high,
        extra: {'provider': provider},
      ),
    );
  }
}
```

## 排错指南

### 常见问题

1. **事件没有被接收**
   - 检查类型是否匹配
   - 确认事件总线实例是否相同
   - 验证订阅是否在发送前创建

2. **内存泄漏**
   - 确保在dispose中取消所有订阅
   - 避免在全局作用域创建大量永久订阅

3. **性能问题**
   - 使用轻量级元数据减少内存使用
   - 对高频事件使用throttle或debounce
   - 考虑使用onWhere代替在监听回调中过滤

### 调试技巧

```dart
// 启用调试模式
final eventBus = KysionEventBus.forDebugging();

// 获取平台信息
final platformInfo = eventBus.getPlatformInfo();
print('平台: ${platformInfo['platform']}');
print('特性支持: ${platformInfo['features']}');

// 监控调度器状态
final dispatcherStatus = platformInfo['dispatcherStatus'];
print('批处理状态: $dispatcherStatus');
```

## 贡献

欢迎提交 Issue 和 Pull Request！项目地址：<https://github.com/kysion/kysion-event-bus-dart>

## 许可证

本项目采用 MIT 许可证
