import 'dart:isolate';
import 'package:async/async.dart';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:street_sign_detection/tflite/IsolateData.dart';
import 'sign_detection_interpreter.dart';



/// Manages separate Isolate instance for inference
class SignDetectionIsolate {

  /// The name of this isolate (used for debugging)
  String debugName;
  /// The isolate instance
  late Isolate? _isolate;
  /// The receive port of the main thread
  final ReceivePort _receivePort = ReceivePort();
  /// A queue of messages that are send from the isolate
  late final StreamQueue<dynamic> messageQueue = StreamQueue<dynamic>(_receivePort);
  /// The port on which the isolate is listening
  late SendPort _sendPort;
  SendPort get sendPort => _sendPort;

  int? interpreterAddress;


  SignDetectionIsolate(
    {
      this.debugName = "SignDetectionIsolate",
      required this.interpreterAddress,
    }
  );

  /// Spawns a new isolate to run inference in
  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _sendPort = await messageQueue.next;
    sendPort.send(interpreterAddress);
  }

  /// Stops this isolate and fress all resources
  void stopIsolate() {
    if (_isolate != null) {
      _receivePort.close();
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  static void entryPoint(SendPort sendPort) async {

    // send the port of this isolate to the main thread
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    /// a queue a of messages that are send from the main isolate
    StreamQueue mainMessageQueue = StreamQueue(port);

    // create a interpreter inside of the isolate
    Interpreter interpreter = Interpreter.fromAddress(
      (await mainMessageQueue.next) as int
    );


    await for (final message in mainMessageQueue.rest) {
      
      if(message is IsolateData){
        print(message.output);

        //runInterpreter(interpreter, message.input, message.output);
        sendPort.send(message.output);

        print(message.output);
      }
      else if (message == null){
        break;
      }

    }
  }

}
