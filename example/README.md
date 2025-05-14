# Kysion Event Bus 示例

这个目录包含 Kysion Event Bus 的使用示例，展示了库的主要功能和用法。

## 运行示例

```bash
dart run kysion_event_bus_example.dart
```

## 示例内容

示例代码展示了以下功能：

1. **基本功能**
   - 创建事件总线
   - 获取平台信息
   - 设置错误处理器
   - 订阅和发布事件
   - 延迟发送和 fire-and-forget 操作

2. **历史记录功能**
   - 启用历史记录
   - 存储和获取历史事件

3. **批处理与优先级**
   - 使用优先级队列
   - 批量发送事件

4. **高级功能**
   - 防抖和节流操作
   - 事件流转换
   - 事件序列工作流

## 事件类型

示例中定义了多种事件类型：

- `UserLoginEvent` - 用户登录事件
- `SearchEvent` - 搜索事件（用于演示防抖）
- `ScrollEvent` - 滚动事件（用于演示节流）
- `WorkflowEvent` - 工作流事件（用于演示顺序事件）

## 完整应用示例

如需查看在实际 Flutter 应用中的使用示例，请参考主 README 中的应用示例部分。
