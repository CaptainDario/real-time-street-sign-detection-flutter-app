import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:tuple/tuple.dart';

import 'sign_detection_isolate.dart';
import 'package:street_sign_detection/tflite/stats.dart';
import 'package:street_sign_detection/tflite/interpreter_utils.dart';
import 'package:street_sign_detection/tflite/object_detection.dart';
import 'package:street_sign_detection/tflite/sign_detection_data.dart';



/// The top level class to create and interact with a TF Lite interperter with
/// a ML model for ObjectDetection (Street Sign Detection) loaded.
/// 
/// It creates a separate isolate to run the preprocessing of the input,
/// the TF Lite inference and the postprocesing of the output. This way those
/// operations are not blocking the main UI-process
class SignDetectionInterpreter with ChangeNotifier{

  /// The interpreter to run the TF Lite model
  late Interpreter interpreter;

  /// A name for this interpreter
  final String name;
  /// If the interpreter was initialized successfully
  bool wasInitialized = false;

  /// The path to the tf lite asset
  final String tfLiteAssetPath;
  /// The path to the labels asset
  final String labelAssetPath;
  /// The asset path to the used asset for creating the interpreter
  late final String _usedTFLiteAssetPath;

  /// the utils for the interpreter's isolate
  SignDetectionIsolate? _inferenceIsolate;
  /// The interpreter instance
  late final SignDetectionData signDetectionData;
  /// The statstics of the last succesful inference
  InferenceStats? inferenceStats;

  /// Message that it printed when the instance accessed but was not initialized
  String _notInitializedMessage =
    "You are trying to use the interpreter before it was initialized!\n"
    "Execute init() first!";


  /// After instantiating the Interpreter `await init()` needs to be called before
  /// using it. This determines the best available backend and spawns the
  /// processing isolate.
  SignDetectionInterpreter({
    this.name = "SignDetectionInterpreter",
    this.tfLiteAssetPath = "detect.tflite",
    this.labelAssetPath = "assets/labelmap.txt"
  });


  /// Initializes this interprerter with the given values
  Future<void> init(
    int inputImageHeight, int inputImageWidth, int inputImagechannels,
    int modelInputHeight, int modelInputWidth, int modelInputChannels, 
    ) async 
  {

    if(wasInitialized){
      debugPrint("Sign detection interpreter already initialized. Skipping init.");
      return;
    }
    
    // load data
    _usedTFLiteAssetPath = tfLiteAssetPath;
    signDetectionData = SignDetectionData(
      inputImageHeight, inputImageWidth, inputImagechannels,
      modelInputWidth, modelInputHeight, modelInputChannels, 
      await loadLabels());
    signDetectionData.setupOutput(await Interpreter.fromAsset(_usedTFLiteAssetPath));

    // find the best available backend and load the model
    interpreter = await Interpreter.fromAsset(tfLiteAssetPath);
    await initOptimalInterpreter(
      _usedTFLiteAssetPath,
      signDetectionData.generateMockInput(),
      signDetectionData.output,
      (Interpreter interpreter, Object input, Object output) => 
        signDetectionData.runInterpreter(
          interpreter,
          input as List<ByteBuffer>,
          output as Map<int, Object>
        )
    );

    // create and setup isolate
    _inferenceIsolate = SignDetectionIsolate();
    await _inferenceIsolate?.start(interpreter.address, signDetectionData);

    wasInitialized = true;
  }

  /// load the labels from file
  Future<List<String>> loadLabels() async {
    var l = await rootBundle.loadString(labelAssetPath);
    return l.split("\n");
  }

  /// Process the input, runs inference on it and returns the processed output
  Future<Tuple2<List<ObjectDetection>, InferenceStats>> runInference(CameraImage input) async {
    if(!wasInitialized) throw Exception(_notInitializedMessage);

    Stopwatch stopwatch = Stopwatch()..start();

    // send the input to the inference isolate and wait for the response
    _inferenceIsolate!.sendPort.send(input);

    // receive detections and stats + emit changed signal
    List<ObjectDetection>_detections =
      await _inferenceIsolate!.messageQueue.next;
    InferenceStats stats = await _inferenceIsolate!.messageQueue.next;
    stats.totalTime = stopwatch.elapsed.inMilliseconds;
    notifyListeners();

    return Tuple2(_detections, stats);
  }

  /// Frees all used resources
  void free() {
    if(!wasInitialized){
      debugPrint(_notInitializedMessage);
      return;
    }

    _inferenceIsolate!.sendPort.send(null);
    _inferenceIsolate!.stopIsolate();
    _inferenceIsolate = null;
    interpreter.close();
    wasInitialized = false;
  }

}

