import 'dart:isolate';
import 'dart:typed_data';



/// Bundles data to pass between Isolate
class SignDetectionIsolateData {

  Uint8List image;
  int interpreterAddress;
  List<String> labels;
  SendPort ?responsePort;

  SignDetectionIsolateData(
    this.image,
    this.interpreterAddress,
    this.labels,
  );
}