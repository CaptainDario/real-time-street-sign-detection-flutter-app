import 'dart:isolate';
import 'dart:typed_data';

import 'sign_detection_isolate_data.dart';
import 'sign_detection_interpreter.dart';



/// Manages separate Isolate instance for inference
class SignDetectionIsolateUtils {
  static const String debugName = "DrawingInferenceIsolate";

  late Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _sendPort = await _receivePort.first;
  }

  void stopIsolate() {
    if (_isolate != null) {
      _receivePort.close();
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final SignDetectionIsolateData isolateData in port) {

      SignDetectionInterpreter classifier = SignDetectionInterpreter("DrawScreen");
      classifier.initIsolate(
        isolateData.interpreterAddress,
        isolateData.labels
      );
      
      classifier.runInference(isolateData.image, runInIsolate: false);
      isolateData.responsePort!.send(classifier.predictions);
      
    }
  }

  Future<dynamic> runInference (
    Uint8List image, int interpreterAddress, List<String> labels) async {
    
    var data = SignDetectionIsolateData(image, interpreterAddress, labels);

    ReceivePort responsePort = ReceivePort();
    sendPort.send(data..responsePort = responsePort.sendPort);
    return responsePort.first;
  }
}
