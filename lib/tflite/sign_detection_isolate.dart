import 'dart:isolate';
import 'package:async/async.dart';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'package:street_sign_detection/tflite/sign_detection_data.dart';



/// Manages separate Isolate instance for inference.
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


  /// Instantiates a new `SignDetectionIsolate`. Before using it `start()` needs
  /// to be called
  SignDetectionIsolate(
    {
      this.debugName = "SignDetectionIsolate",
    }
  );

  /// Spawns a new isolate to run inference in. In this isolate an interpreter
  /// with the given address and data is created to run inference.
  Future<void> start(int interpreterAddress, SignDetectionData data,) async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _sendPort = await messageQueue.next;
    sendPort.send(interpreterAddress);
    sendPort.send(data);
  }

  /// Stops this isolate and frees all resources
  void stopIsolate() {
    if (_isolate != null) {
      _receivePort.close();
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  /// The function that is called inside of the isolate.
  /// It sets the isolate up and starts listening for messages.
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
    
    // receive all data
    SignDetectionData data = (await mainMessageQueue.next) as SignDetectionData;
    data.setupOutput(interpreter);

    // wait for messages from the main isolate
    await for (final message in mainMessageQueue.rest) {
      
      // stop listening for messages on a null message
      if(message ==  null) break;


      TensorImage processedImg = await data.preProcessRawInput(message);

      data.runInterpreter(interpreter, [processedImg.buffer], data.output);

      sendPort.send(data.postProcessRawOutput());

    }
  }

}
