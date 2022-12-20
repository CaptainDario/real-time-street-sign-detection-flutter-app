import 'package:flutter/material.dart';

import 'package:street_sign_detection/ml_models.dart';
import 'package:street_sign_detection/tflite/inference_backend.dart';
import 'package:universal_io/io.dart';



/// Class to bundle all settings
class Settings with ChangeNotifier{

  /// the currently selected inference backend
  InferenceBackend inferenceBackend = InferenceBackend.CPU;
  /// The currently selected ml model
  MLModels mlModel = MLModels.YOLOV5;

  List<InferenceBackend> inferenceBackends = [InferenceBackend.CPU];

  List<InferenceBackend> inferenceBackendsAndroid = [
    InferenceBackend.NNApi, InferenceBackend.GPU, InferenceBackend.XNNPack
  ];

  List<InferenceBackend> inferenceBackendsIos = [
    InferenceBackend.CoreML, InferenceBackend.Metal, InferenceBackend.XNNPack
  ];


  Settings(){
    if(Platform.isAndroid)
      inferenceBackends.addAll(inferenceBackendsAndroid);
    else if(Platform.isIOS)
      inferenceBackends.addAll(inferenceBackendsIos);
  }
}