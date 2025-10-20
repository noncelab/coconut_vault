import 'dart:async';
import 'dart:isolate';

class IsolateHandler<T, R> {
  final FutureOr<R> Function(T) _handler;

  IsolateHandler(this._handler);

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
