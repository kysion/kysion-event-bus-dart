# Kysion Event Bus

English | [中文](README_CN.md)

A high-performance, reactive event bus library providing powerful event handling capabilities for Flutter applications. Kysion Event Bus employs a reactive design, supports priority queuing, smart batching, cross-platform adaptation, and complete event tracking functionality, making it an ideal choice for building complex Flutter applications.

## Key Features

- **Reactive Design**: Fully reactive API based on Streams, supporting chained calls and declarative programming style
- **Intelligent Event Scheduling**: Priority management and automatic batch optimization ensuring critical events are handled first
- **Platform Adaptation**: Automatic detection and adaptation for Web, mobile, and desktop platforms with optimized configuration
- **High Performance**: Multiple performance optimizations including type caching, lightweight metadata, batching, and concurrency control
- **Event Tracking**: Built-in event tracking and performance monitoring for debugging and performance analysis
- **Feature-rich Stream API**: Support for debouncing, throttling, filtering, transformation, merging, and other stream operations
- **Powerful Error Handling**: Global and local error handling mechanisms with built-in smart retry strategies and circuit protection
- **Type Safety**: Completely type-safe event subscription and publishing with compile-time type checking

## Recent Optimizations

- **Enhanced API Design**: Added rich factory methods and convenience methods
- **Strengthened Event Stream Functionality**: Added debouncing, throttling, filtering, transformation, and other stream operations
- **Improved Platform Detection**: Enhanced platform detection with performance tier adaptation
- **Optimized Metadata Management**: Added various metadata types supporting lightweight and debug modes
- **Enhanced Security**: Added state checking and resource management capabilities
- **Enhanced Configuration System**: Support for custom configurations and multiple preset configurations

## Installation

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  kysion_event_bus: ^1.0.2
```

Then run:

```bash
flutter pub get
```

## Core Concepts

### Event Bus

The event bus is a central event processor responsible for event publishing, subscription, scheduling, and storage.

### Event Stream

An event stream is an observer for events of a specific type, supporting filtering, transformation, and other stream operations.

### Event Metadata

Metadata contains additional information about events, such as priority, timestamp, and source.

### Priority

Event priority determines the processing order, with high-priority events being processed first.

## Quick Start

### Creating an Event Bus

```dart
import 'package:kysion_event_bus/kysion_event_bus.dart';

// Create a basic event bus
final eventBus = KysionEventBus.simple();

// Create an event bus suitable for the current platform
final eventBus = KysionEventBus.forCurrentPlatform();

// Create a high-performance event bus
final eventBus = KysionEventBus.forPerformance();

// Create a debugging version of the event bus
final eventBus = KysionEventBus.forDebugging();
```

### Defining Event Classes

```dart
// User event base class
abstract class UserEvent {
  final String userId;
  
  UserEvent(this.userId);
}

// User login event
class UserLoggedInEvent extends UserEvent {
  final String username;
  final DateTime loginTime;
  
  UserLoggedInEvent(String userId, this.username)
      : loginTime = DateTime.now(),
        super(userId);
}

// User logout event
class UserLoggedOutEvent extends UserEvent {
  final DateTime logoutTime;
  
  UserLoggedOutEvent(String userId)
      : logoutTime = DateTime.now(),
        super(userId);
}
```

### Subscribing to Events

```dart
// Basic subscription
final subscription = eventBus.on<UserLoggedInEvent>().listen((event) {
  print('User login: ${event.username}, User ID: ${event.userId}');
});

// Using filters
eventBus.onWhere<UserEvent>(
  (event) => event.userId == '123'
).listen((event) {
  print('User 123 event: ${event.runtimeType}');
});

// Transforming events
eventBus.onTransform<UserLoggedInEvent, String>(
  (event) => '${event.username}|${event.userId}'
).listen((userInfo) {
  print('User info: $userInfo');
});

// Event debouncing (e.g., search input)
class SearchEvent {
  final String keyword;
  SearchEvent(this.keyword);
}

eventBus.on<SearchEvent>()
  .debounce(Duration(milliseconds: 300))
  .listen((event) {
    print('Search: ${event.keyword}');
    // Perform actual search operation
  });
  
// Event throttling (e.g., scroll events)
class ScrollEvent {
  final double position;
  ScrollEvent(this.position);
}

eventBus.on<ScrollEvent>()
  .throttle(Duration(milliseconds: 100))
  .listen((event) {
    print('Scroll position: ${event.position}');
    // Update UI or load more content
  });
  
// Combined operations
eventBus.on<UserEvent>()
  .where((event) => event is UserLoggedInEvent)
  .transform((event) => event as UserLoggedInEvent)
  .where((event) => event.username.contains('admin'))
  .listen((adminEvent) {
    print('Admin login: ${adminEvent.username}');
  });
```

### Publishing Events

```dart
// Basic publishing
eventBus.emit(UserLoggedInEvent('user123', 'zhangsan'));

// Publishing a high-priority event
class SystemErrorEvent {
  final String message;
  SystemErrorEvent(this.message);
}

eventBus.emit(
  SystemErrorEvent('Connection failed'),
  options: const EmitOptions(priority: Priority.critical)
);

// Delayed publishing
class NotificationEvent {
  final String message;
  NotificationEvent(this.message);
}

eventBus.fireDelayed(
  NotificationEvent('Meeting reminder'),
  Duration(minutes: 5)
);

// Batch publishing
class OrderCreatedEvent {
  final String orderId;
  OrderCreatedEvent(this.orderId);
}

eventBus.emitBatch([
  OrderCreatedEvent('ORDER-001'),
  OrderCreatedEvent('ORDER-002'),
  OrderCreatedEvent('ORDER-003'),
]);

// Sequential publishing (stops if one fails)
class WorkflowEvent {
  final String step;
  final int sequence;
  
  WorkflowEvent(this.step, this.sequence);
}

final workflowSuccess = await eventBus.emitSequence([
  WorkflowEvent('Start processing', 1),
  WorkflowEvent('Validate data', 2),
  WorkflowEvent('Save results', 3),
  WorkflowEvent('Complete', 4),
]);

if (workflowSuccess) {
  print('Workflow completed');
} else {
  print('Workflow failed');
}
```

### Using Metadata

```dart
// Using custom metadata
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

// Publishing an event with metadata
eventBus.emit(
  PaymentEvent('ORDER-001', 99.9),
  options: EmitOptions(metadata: metadata)
);

// Lightweight metadata (reducing memory usage)
final lightMetadata = EventMetadata.lightweight(
  priority: Priority.normal,
);

// Debug metadata (containing more information)
final debugMetadata = EventMetadata.forDebugging(
  priority: Priority.high,
  source: 'debug_service',
  eventTypeName: 'PaymentEvent',
  extra: {'debug': true, 'testCase': 'TC-001'},
);
```

## Practical Application Examples

### Form Validation

```dart
// Form event
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
    // Listen for field changes and validate
    _eventBus.on<FormFieldChangedEvent>()
      .debounce(Duration(milliseconds: 300)) // Debounce to avoid frequent validation
      .listen(_validateField);
  }
  
  void updateField(String fieldName, dynamic value) {
    _formData[fieldName] = value;
    _eventBus.emit(FormFieldChangedEvent(fieldName, value));
  }
  
  void _validateField(FormFieldChangedEvent event) {
    // Validate based on field name
    switch (event.fieldName) {
      case 'email':
        _validateEmail(event.value as String?);
        break;
      case 'password':
        _validatePassword(event.value as String?);
        break;
      // Other fields...
    }
    
    // Notify UI to update
    _eventBus.emit(FormValidationResultEvent(_errors));
  }
  
  void _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      _errors['email'] = 'Please enter an email';
    } else if (!email.contains('@')) {
      _errors['email'] = 'Invalid email format';
    } else {
      _errors.remove('email');
    }
  }
  
  void _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      _errors['password'] = 'Please enter a password';
    } else if (password.length < 6) {
      _errors['password'] = 'Password must be at least 6 characters';
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

### State Management

```dart
// Simple state manager
class EventBusStore<T> {
  final KysionEventBus _eventBus;
  final T _initialState;
  T _state;
  
  EventBusStore(this._eventBus, this._initialState) : _state = _initialState;
  
  T get state => _state;
  
  // Listen for specific events and update state
  void on<E>(T Function(T currentState, E event) reducer) {
    _eventBus.on<E>().listen((event) {
      final newState = reducer(_state, event);
      if (newState != _state) {
        _state = newState;
        _eventBus.emit(StateChangedEvent<T>(_state));
      }
    });
  }
  
  // Dispatch state change
  void dispatch<E>(E event) {
    _eventBus.emit(event);
  }
}

// Usage example: Shopping cart
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

// Shopping cart events
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

// Initialize shopping cart
final eventBus = KysionEventBus.simple();
final cartStore = EventBusStore<CartState>(eventBus, CartState([], 0.0));

// Set up state update logic
void initCartStore() {
  // Add item
  cartStore.on<AddToCartEvent>((state, event) {
    final items = List<CartItem>.from(state.items);
    final existingIndex = items.indexWhere((i) => i.id == event.item.id);
    
    if (existingIndex >= 0) {
      // Update quantity
      final existing = items[existingIndex];
      items[existingIndex] = CartItem(
        existing.id, 
        existing.name, 
        existing.price, 
        existing.quantity + event.item.quantity
      );
    } else {
      // Add new item
      items.add(event.item);
    }
    
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return CartState(items, totalPrice);
  });
  
  // Remove item
  cartStore.on<RemoveFromCartEvent>((state, event) {
    final items = List<CartItem>.from(state.items)
        ..removeWhere((item) => item.id == event.itemId);
    
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return CartState(items, totalPrice);
  });
  
  // Update quantity
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
  
  // Listen for state changes
  eventBus.on<StateChangedEvent<CartState>>().listen((event) {
    print('Cart updated: ${event.state.items.length} items, total: ${event.state.totalPrice}');
    // Update UI
  });
}
```

### API Request Management

```dart
// API request event
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
    // Listen for API requests
    _eventBus.on<ApiRequestEvent>().listen(_handleApiRequest);
    
    // Listen for API responses
    _eventBus.on<ApiResponseEvent>().listen(_handleApiResponse);
  }
  
  // Send API request and return Future
  Future<Map<String, dynamic>> request(String endpoint, Map<String, dynamic> data) {
    final requestEvent = ApiRequestEvent(endpoint, data);
    final completer = Completer<Map<String, dynamic>>();
    
    _pendingRequests[requestEvent.requestId] = completer;
    
    // Send API request with high priority
    _eventBus.emit(
      requestEvent,
      options: const EmitOptions(
        priority: Priority.high,
        enableTracing: true, // Enable tracing for debugging
      ),
    );
    
    return completer.future;
  }
  
  // Handle API request
  void _handleApiRequest(ApiRequestEvent event) async {
    try {
      // Simulate network request
      await Future.delayed(Duration(milliseconds: 500));
      
      // Simulate response data
      final responseData = {
        'success': true,
        'data': {'id': 123, 'timestamp': DateTime.now().toIso8601String()},
        'endpoint': event.endpoint,
      };
      
      // Send response event
      _eventBus.emit(ApiResponseEvent(event.requestId, data: responseData));
    } catch (e) {
      // Send error response
      _eventBus.emit(ApiResponseEvent(event.requestId, error: e.toString()));
    }
  }
  
  // Handle API response
  void _handleApiResponse(ApiResponseEvent event) {
    final completer = _pendingRequests.remove(event.requestId);
    
    if (completer != null) {
      if (event.error != null) {
        completer.completeError(event.error!);
      } else if (event.data != null) {
        completer.complete(event.data!);
      } else {
        completer.completeError('Invalid response');
      }
    }
  }
}

// Usage example
void apiExample() async {
  final eventBus = KysionEventBus.forPerformance();
  final apiService = ApiService(eventBus);
  
  try {
    final result = await apiService.request('/users', {'name': 'zhangsan'});
    print('API request successful: $result');
  } catch (e) {
    print('API request failed: $e');
  }
}
```

## Advanced Features

### Event Tracking and Performance Monitoring

```dart
// Get performance metrics
final metrics = eventBus.getMetrics();
print('Average processing time: ${metrics['averageProcessingTimeMs']}ms');
print('Processed events: ${metrics['totalProcessed']}');
print('Slowest event: ${metrics['slowestEvent']}');

// Get error statistics
final errorStats = eventBus.getErrorStats();
print('Total errors: ${errorStats['total']}');
print('By type: ${errorStats['byType']}');

// Get metrics by event type
final userEventMetrics = eventBus.getMetrics('UserLoggedInEvent');
print('User login event average processing time: ${userEventMetrics['averageProcessingTimeMs']}ms');
```

### Event History

```dart
// Get history for a specific event type
final history = await eventBus.getHistory<UserLoggedInEvent>(limit: 10);

for (final item in history) {
  print('User login: ${item['event']['username']}');
  print('Time: ${item['metadata']['createdAt']}');
}

// Clear history
await eventBus.clearHistory<UserLoggedInEvent>(
  before: DateTime.now().subtract(Duration(days: 7))
);
```

### Custom Configuration

```dart
// Set custom platform configuration
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

// Create event bus with custom configuration
final customConfig = EventBusConfig(
  historyEnabled: true,
  dispatcherConfig: SmartDispatcherConfig(
    minBatchSize: 15,
    maxBatchSize: 150,
    batchTimeout: Duration(milliseconds: 75),
    adaptiveThreshold: true,
  ),
  errorHandler: (error, stackTrace) {
    print('Custom error handler: $error');
    // Record to logging system
  },
);

final eventBus = KysionEventBus.withConfig(customConfig);
```

## Best Practices

### Component Lifecycle Management

When using the event bus in Flutter components, ensure proper subscription lifecycle management:

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
    
    // Add subscriptions
    _subscriptions.add(
      _eventBus.on<UserEvent>().listen((event) {
        // Handle event
      })
    );
    
    _subscriptions.add(
      _eventBus.on<NotificationEvent>().listen((event) {
        // Handle notification
      })
    );
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Build UI
    return Container();
  }
}
```

### Priority Usage Recommendations

- **Critical Priority (Priority.critical)**
  - Security-related operations: User authentication, permission changes
  - Core state changes: Application state reset, important configuration changes
  - System errors: Connection interruption, data corruption

- **High Priority (Priority.high)**
  - User interaction feedback: Form submission, button click response
  - Critical business logic: Payment processing, order confirmation
  - Data synchronization: Important data synchronization from local to server

- **Normal Priority (Priority.normal)**
  - General UI updates: List refreshing, non-critical view updates
  - Regular business logic: Processing of non-core functionalities
  - Default priority: Most application events

- **Low Priority (Priority.low)**
  - Logging: Application usage statistics, behavior tracking
  - Analytics data collection: User behavior analysis, performance metrics collection
  - Background tasks: Preloading, cache cleaning

### Efficient Event Design

Well-defined event classes can improve code readability and maintainability:

```dart
// Good event design
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
  
  // Factory constructors
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

## Troubleshooting Guide

### Common Issues

1. **Events not being received**
   - Check if types match
   - Confirm the event bus instance is the same
   - Verify subscriptions are created before sending

2. **Memory leaks**
   - Ensure all subscriptions are canceled in dispose
   - Avoid creating many permanent subscriptions in global scope

3. **Performance issues**
   - Use lightweight metadata to reduce memory usage
   - Use throttle or debounce for high-frequency events
   - Consider using onWhere instead of filtering in listener callbacks

### Debugging Tips

```dart
// Enable debug mode
final eventBus = KysionEventBus.forDebugging();

// Get platform information
final platformInfo = eventBus.getPlatformInfo();
print('Platform: ${platformInfo['platform']}');
print('Feature support: ${platformInfo['features']}');

// Monitor dispatcher status
final dispatcherStatus = platformInfo['dispatcherStatus'];
print('Batch status: $dispatcherStatus');
```

## Contribution

Issues and Pull Requests are welcome! Project link: <https://github.com/kysion/kysion-event-bus-dart>

## License

This project is licensed under the MIT License
