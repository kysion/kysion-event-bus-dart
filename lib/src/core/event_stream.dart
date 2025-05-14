import 'dart:async';

import 'package:meta/meta.dart';
import '../models/emit_options.dart';
import '../models/event_metadata.dart';
import '../models/priority.dart';

/// 事件流接口
///
/// 定义了事件流的基本操作和转换方法
@immutable
abstract class EventStream<T> {
  /// 获取底层的事件流
  Stream<T> get stream;

  /// 发送事件到流中
  ///
  /// [event] 要发送的事件
  /// [options] 发送选项
  /// 返回发送是否成功
  Future<bool> emit(T event, {EmitOptions? options});

  /// 使用条件过滤事件流
  ///
  /// [predicate] 过滤条件
  /// 返回新的过滤后的事件流
  EventStream<T> where(bool Function(T event) predicate);

  /// 转换事件流中的事件类型
  ///
  /// [transformer] 转换函数
  /// 返回转换后的新事件流
  EventStream<R> transform<R>(R Function(T event) transformer);

  /// 添加事件元数据
  ///
  /// [metadata] 要添加的元数据
  /// 返回带有元数据的新事件流
  EventStream<T> withMetadata(EventMetadata metadata);

  /// 设置事件优先级
  ///
  /// [priority] 优先级
  /// 返回带有优先级的新事件流
  EventStream<T> withPriority(Priority priority);

  /// 限制事件数量
  ///
  /// [count] 最大事件数量
  /// 返回限制数量后的新事件流
  EventStream<T> take(int count);

  /// 跳过指定数量的事件
  ///
  /// [count] 要跳过的事件数量
  /// 返回跳过事件后的新事件流
  EventStream<T> skip(int count);

  /// 限制事件流时间
  ///
  /// [duration] 限制的时间
  /// 返回限制时间后的新事件流
  EventStream<T> takeForDuration(Duration duration);

  /// 防抖操作，在指定时间段内只发射最后一个事件
  ///
  /// [duration] 防抖时间
  /// 返回防抖处理后的新事件流
  EventStream<T> debounce(Duration duration);

  /// 节流操作，在指定时间段内最多发射一个事件
  ///
  /// [duration] 节流时间
  /// 返回节流处理后的新事件流
  EventStream<T> throttle(Duration duration);

  /// 与另一个事件流合并
  ///
  /// [other] 要合并的事件流
  /// 返回合并后的新事件流
  EventStream<T> mergeWith(Stream<T> other);

  /// 与另一个事件流级联合并
  ///
  /// [other] 要合并的事件流
  /// 返回合并后的新事件流
  EventStream<dynamic> concat(Stream<dynamic> other);

  /// 获取事件流的第一个事件
  ///
  /// 返回一个Future，表示第一个事件
  Future<T> get first;

  /// 获取事件流的最后一个事件
  ///
  /// 返回一个Future，表示最后一个事件
  Future<T> get last;

  /// 转换为列表
  ///
  /// 返回一个Future，表示事件列表
  Future<List<T>> toList();

  /// 当事件流完成时执行操作
  ///
  /// [action] 要执行的操作
  /// 返回事件流
  EventStream<T> doOnDone(void Function() action);

  /// 当事件流出错时执行操作
  ///
  /// [action] 要执行的操作
  /// 返回事件流
  EventStream<T> doOnError(
      void Function(Object error, StackTrace stackTrace) action);

  /// 当事件流收到数据时执行操作
  ///
  /// [action] 要执行的操作
  /// 返回事件流
  EventStream<T> doOnData(void Function(T event) action);

  /// 异步映射操作
  ///
  /// [mapper] 异步映射函数
  /// 返回映射后的新事件流
  EventStream<R> asyncMap<R>(FutureOr<R> Function(T event) mapper);

  /// 监听事件流
  ///
  /// [onData] 数据处理函数
  /// [onError] 错误处理函数
  /// [onDone] 完成处理函数
  /// [cancelOnError] 是否在错误时取消订阅
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });

  /// 关闭事件流
  Future<void> close();
}

/// 创建事件流的扩展方法
extension EventStreamCreator on Stream<dynamic> {
  /// 将普通流转换为事件流
  EventStream<T> asEventStream<T>() {
    if (this is EventStream<T>) {
      return this as EventStream<T>;
    }
    throw UnsupportedError(
        '直接转换为EventStream未实现。请使用KysionEventBus.on<T>()获取EventStream');
  }
}
