import 'dart:async';
import 'dart:isolate';

/// isolate_handler.dart 리팩토링이 필요한 상태여서 계속 사용할 수가 없어서
/// 우선 isolate_handler2.dart를 생성, isolate가 필요한 새로운 코드에서 사용합니다.
class IsolateHandler2<T, R> {
  final FutureOr<R> Function(T) _handler;

  IsolateHandler2(this._handler);

  Future<R> execute(T data) async {
    final receivePort = ReceivePort();
    late final Isolate isolate;

    try {
      isolate = await Isolate.spawn<_IsolatePayload<T, R>>(
        _isolateFunction<T, R>,
        _IsolatePayload(receivePort.sendPort, data, _handler),
      );

      final result = await receivePort.first;
      if (result is _IsolateError) {
        throw result.error;
      }
      return result as R;
    } finally {
      receivePort.close();
      isolate.kill();
    }
  }

  /// 새로 생성된 isolate에서 실행될 함수
  static void _isolateFunction<T, R>(_IsolatePayload<T, R> payload) {
    try {
      final result = payload.handler(payload.data);
      payload.sendPort.send(result);
    } catch (e) {
      payload.sendPort.send(_IsolateError(e));
    }
  }
}

class _IsolatePayload<T, R> {
  final SendPort sendPort;
  final T data;
  final FutureOr<R> Function(T) handler;

  _IsolatePayload(this.sendPort, this.data, this.handler);
}

class _IsolateError {
  final Object error;
  _IsolateError(this.error);
}
