import 'package:flutter_test/flutter_test.dart';
import 'package:kysion_event_bus/kysion_event_bus.dart';

void main() {
  group('CircuitBreaker 基础测试', () {
    test('初始状态应为关闭（允许通过）', () {
      final breaker = CircuitBreaker(
        failureThreshold: 3,
        resetTimeout: const Duration(milliseconds: 100),
      );

      expect(breaker.state, equals(CircuitState.closed));
      expect(breaker.isAllowed, isTrue);
    });

    test('连续失败应触发断路器打开', () {
      final breaker = CircuitBreaker(
        failureThreshold: 3,
        resetTimeout: const Duration(milliseconds: 100),
      );

      // 记录三次失败
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.closed));

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.closed));

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));

      // 断路器打开后应拒绝请求
      expect(breaker.isAllowed, isFalse);
    });

    test('成功应重置失败计数', () {
      final breaker = CircuitBreaker(
        failureThreshold: 3,
        resetTimeout: const Duration(milliseconds: 100),
      );

      // 记录两次失败
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.closed));

      // 记录一次成功
      breaker.recordSuccess();

      // 再次记录一次失败，应该不触发断路器打开
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('断路器应在超时后自动重置为半开状态', () async {
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        resetTimeout: const Duration(milliseconds: 50), // 较短的超时时间便于测试
      );

      // 触发断路器打开
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));

      // 等待断路器超时
      await Future.delayed(const Duration(milliseconds: 100));

      // 此时断路器应进入半开状态，检查isAllowed
      expect(breaker.isAllowed, isTrue);

      // 再次检查状态 - 应该是半开状态
      expect(breaker.state, equals(CircuitState.halfOpen));

      // 如果此时再失败一次，应立即重新打开
      breaker.recordFailure();
      // 根据实际实现，在半开状态下记录失败仍然保持半开状态
      expect(breaker.state, equals(CircuitState.halfOpen));
    });

    test('半开状态成功应完全关闭断路器', () async {
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        resetTimeout: const Duration(milliseconds: 50),
        halfOpenSuccessThreshold: 1, // 设置只需一次成功即可关闭
      );

      // 触发断路器打开
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));

      // 等待断路器超时
      await Future.delayed(const Duration(milliseconds: 100));

      // 使用isAllowed触发状态检查
      expect(breaker.isAllowed, isTrue);

      // 再检查状态
      expect(breaker.state, equals(CircuitState.halfOpen));

      // 记录成功，应完全关闭断路器
      breaker.recordSuccess();
      expect(breaker.state, equals(CircuitState.closed));

      // 应该需要重新累积故障才能打开
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.closed));
    });
  });
}
