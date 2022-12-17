import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:street_sign_detection/tflite/IsolateData.dart';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'sign_detection_isolate.dart';
import 'base_interpreter.dart';



/// The tf lite interpreter to recognize the hand drawn kanji characters.
/// 
/// Notifies listeners when the predictions changed.
class SignDetectionInterpreter with ChangeNotifier{

  
  late List<ByteBuffer> input;

  late Map<int, ByteBuffer> output;

  late final String usedTFLiteAssetPath;

  late final Interpreter? interpreter;

  final String name;

  /// The path to the tf lite asset
  final String _tfLiteAssetPath = "detect.tflite";
  
  /// The path to the labels asset
  final String _labelAssetPath = "assets/labelmap.txt";

  // the utils for the interpreter's isolate
  SignDetectionIsolate? _inferenceIsolate;

  /// If the interpreter was initialized successfully
  bool wasInitialized = false;

  /// The list of all labels the model can recognize.
  late List<String> labels;

  /// height of the input image (image used for inference)
  int height = 300;

  /// width of the input image (image used for inference)
  int width = 300;

  /// number of channels of the input image
  int channels = 3;

  /// [ImageProcessor] used to pre-process the image
  late ImageProcessor imageProcessor;

  // TensorBuffers for output tensors
  late TensorBuffer outputLocations;
  late TensorBuffer outputClasses;
  late TensorBuffer outputScores;
  late TensorBuffer numLocations;

  late List _outputShapes = [];

  late List _outputTypes = [];

  /// the prediction the CNN made
  List<String> predictions = List.generate(10, (index) => " ");



  SignDetectionInterpreter({
    this.name = "SignDetectionInterpreter"
  });


  Future<void> init() async {

    if(wasInitialized){
      debugPrint("Sign detection interpreter already initialized. Skipping init.");
    }
    else{
      //  load the model
      await Interpreter.fromAsset(_tfLiteAssetPath);
      usedTFLiteAssetPath = _tfLiteAssetPath;

      await loadLabels();
      await allocateInputOutput();
      //await initInterpreter(
      //  usedTFLiteAssetPath,

      //);

      _inferenceIsolate = SignDetectionIsolate(
        interpreterAddress: interpreter!.address);
      await _inferenceIsolate?.start();

      wasInitialized = true;
    }
  }

  /// load the labels from file
  Future<void> loadLabels() async {
    var l = await rootBundle.loadString(_labelAssetPath);
    labels = l.split("");
  }

  /// allocate memory for inference in / output
  Future<void> allocateInputOutput() async {

    imageProcessor = ImageProcessorBuilder()
      //.add(ResizeWithCropOrPadOp(padSize, padSize))
      .add(ResizeOp(width, height, ResizeMethod.BILINEAR))
      .build();

    input = [imageProcessor.process(
      TensorImage.fromTensorBuffer(
        TensorBuffer.createFixedSize([1, width, height, channels], TfLiteType.float32)
      )
    ).buffer];

    interpreter = await Interpreter.fromAsset(this._tfLiteAssetPath);

    interpreter!.getOutputTensors().forEach((tensor) {
      _outputShapes.add(tensor.shape);
      _outputTypes.add(tensor.type);
    });

    outputLocations = TensorBufferFloat(_outputShapes[0]);
    outputClasses = TensorBufferFloat(_outputShapes[1]);
    outputScores = TensorBufferFloat(_outputShapes[2]);
    numLocations = TensorBufferFloat(_outputShapes[3]);
  
    output = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };
  }


  /// Process the input, runs inference on it and returns the output
  /// 
  /// Note: Afterwards, the output is also available as `.output`
  Future<Map<int, ByteBuffer>> runInference(List<ByteBuffer> input) async {
    if(!wasInitialized) {
      throw Exception(
        "You are trying to use the interpreter before it was initialized!\n"
        "Execute init() first!"
      );
    }

    _inferenceIsolate!.sendPort.send(IsolateData(input: input, output: output));
    output = await _inferenceIsolate!.messageQueue.next;

    notifyListeners();

    return output;
  }

  
  void free() {
    if(!wasInitialized){
      debugPrint("Has not been initialized");
      return;
    }

    interpreter!.close();
    output = {};
    input = [];
    interpreter = null;
    wasInitialized = false;
  }

}

///
Future<void> runInterpreter(
  Interpreter interpreter,
  List<ByteBuffer> input,
  Map<int, Object> outputs
) async {
  interpreter.runForMultipleInputs(input, outputs);
}