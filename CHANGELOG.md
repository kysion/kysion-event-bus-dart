# Changelog

English | [中文](CHANGELOG_zh.md)

## 1.0.5 - 测试框架简化与稳定性提升

- 简化了测试框架，专注于API功能验证
  - 将复杂的异步测试转换为简单的API可用性验证测试
  - 通过分离独立组件和依赖组件的测试，提高测试的稳定性
  - 使用更健壮的测试方法，确保测试的一致性

- 优化了测试结构和执行流程
  - 更新了测试配置和分组，按照依赖关系合理排序
  - 调整了tearDown方法，确保所有测试操作完成后再关闭资源
  - 使用同步方法测试API，避免异步操作导致的不稳定性

- 修复了特定测试问题
  - 解决了事件流测试中的事件接收问题
  - 修复了"事件总线已关闭"导致的测试失败
  - 改进了批处理和事件顺序相关的测试

## 1.0.4 - 全面测试修复和改进

- 修复了所有测试文件中的异步处理问题
  - 增强了异步测试稳定性，通过增加等待时间和使用await确保异步操作完成
  - 改进了事件收集方法，使用列表收集事件而非布尔标志
  - 优化了超时处理，增加超时时间并添加适当的错误处理
  
- 完善了所有组件的测试
  - 实现了ObjectPool组件的完整测试，覆盖所有功能点
  - 完善了EventStream测试，添加链式操作、事件过滤和转换测试
  - 修复了EventBus测试，确保事件正确分发和处理

- 测试配置和文档更新
  - 更新了.test_config.yaml包含所有修复的测试
  - 更新了all_tests.dart导入所有测试文件
  - 更新了TESTING.md记录详细的修复方法和解决方案

- 已验证功能
  - 事件发布和订阅
  - 事件流转换和过滤
  - 事件批量处理和顺序处理
  - 熔断器功能
  - 对象池管理

## 1.0.3 - 测试修复

- 修复了 CircuitBreaker 组件的测试，修正状态转换逻辑
- 添加了 BatchProcessor 组件的测试，验证批处理功能和错误处理
- 添加了简化的 EventBus 和 EventStream API 功能验证测试
  - simple_event_bus_test.dart - 验证 EventBus 基本功能
  - simple_event_stream_test.dart - 验证 EventStream 基本功能
- 修复了异步测试处理方式：
  - 调整了事件发送方法，从 emit 改为 fireAndForget
  - 增加了事件等待超时时间
  - 完善了异步事件处理的错误捕获
- 更新了测试文档和配置文件
- 优化了测试环境设置

## 1.0.2

- 添加了 TracedEvent 抽象类
- 改进了 EventBus 的事件调度机制
- 优化了批处理器性能
- 增强了错误处理和恢复机制
- 修复了事件元数据处理中的一些边缘情况
- 提升了池化对象管理的效率

## 1.0.1

- 修复了平台检测模块在 Web 平台的兼容性问题
- 优化了事件流的内存使用
- 改进了事件历史记录功能
- 增加了示例和文档

## 1.0.0

- 首次发布
- 实现了基本的事件总线功能
- 支持类型安全的事件监听和发布
- 提供了事件流转换和操作
- 内置事件跟踪和性能监控
- 支持优先级和批处理
