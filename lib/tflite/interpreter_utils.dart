import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:universal_io/io.dart';

import 'inference_backend.dart';



/// Checks for the available backends and uses the best available backend.
/// For this a valid `input`, `output` and function `runInterpreter` (defines
/// how to run the given TF Lite model at `tfLiteAssetPath)` needs to be provided
/// With `exclude` certain delegates can be excluded.
/// 
/// Delegate support and order: 
/// * iOS    : CoreML > Metal > XNNPack > CPU <br/>
/// * Android: NNApi > GPU > XNNPack > CPU <br/>
/// * Windows: GPU (OpenCL) > XNNPack > CPU <br/>
/// * Mac    : GPU (OpenCL) > XNNPack > CPU <br/>
/// * Linux  : GPU (OpenCL) > XNNPack > CPU <br/>
Future<Interpreter> initOptimalInterpreter(
  String tfLiteAssetPath,
  Object input,
  Object output,
  void Function(Interpreter interpreter, Object input, Object output) runInterpreter,
  {
    List<InferenceBackend>? exclude
  }
) async {

  /// TODO use the exclude parameter

  Interpreter interpreter;

  if (Platform.isAndroid) {
    interpreter = await _initInterpreterAndroid(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output)
    );
  }
  /*
  else if (Platform.isIOS) {
    interpreter = await _initInterpreterIOS();
  }
  else if(Platform.isWindows) {
    interpreter = await _initInterpreterWindows();
  }
  else if(Platform.isLinux) {
    interpreter = await _initInterpreterLinux();
  }
  else if(Platform.isMacOS) {
    interpreter = await _initInterpreterMac();
  }
  */
  else {
    throw PlatformException(code: "Platform not supported.");
  }

  return interpreter;
}


/// Initializes the TFLite interpreter on android.
///
/// Uses either NNAPI, GPU, XNNPack or CPU delegate
Future<Interpreter> _initInterpreterAndroid(
    String assetPath,
    void Function(Interpreter interpreter) runInterpreter,
  ) async {

  Interpreter interpreter;

  // get platform information
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  /// check that the device is not running on an emulator
  if(androidInfo.isPhysicalDevice){
    // try NNAPI delegate
    try{
      interpreter = await _nnapiInterpreter(assetPath);
      runInterpreter(interpreter);
      debugPrint("Interpreter uses NNAPI delegate");
    }
    // on exception try GPU delegate
    catch (e){ 
      try {
        interpreter = await _gpuInterpreter(assetPath);
        runInterpreter(interpreter);
        debugPrint("Interpreter uses GPU v2 delegate");
      }
      // on exception try XNNPack CPU delegate
      catch (e){
        try{
          interpreter = await _xxnPackInterpreter(assetPath);
          runInterpreter(interpreter);
          debugPrint("Interpreter uses XNNPack delegate");
        }
        // on exception use CPU delegate
        catch (e) {
          interpreter = await _cpuInterpreter(assetPath);
          runInterpreter(interpreter);
          debugPrint("Interpreter uses CPU");
        }
      }
    }
  }
  // if emulator only allow cpu inference
  else{
    interpreter = await _cpuInterpreter(assetPath);
  }

  return interpreter;
}

/*
/// Initializes the TFLite interpreter on iOS.
///
/// Uses either CoreML, Metal, XNNPack or CPU delegate
Future<Interpreter> _initInterpreterIOS() async {

  Interpreter interpreter;

  // get platform information
  //DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

  // try CoreML delegate
  try{
    interpreter = await _coreMLInterpreterIOS();
    runInterpreter(input, output);
    debugPrint("Interpreter uses CoreML delegate");
  }
  // on exception try Metal delegate
  catch (e){ 
    try {
      interpreter = await _metalInterpreterIOS();
      runInterpreter(input, output);
      debugPrint("Interpreter uses Metal delegate");
    }
    // on exception use XNNPack CPU delegate
    catch (e){
      try{
        interpreter = await _xxnPackInterpreter();
        runInterpreter(input, output);
        debugPrint("Interpreter uses XNNPack delegate");
      }
      // on exception use CPU delegate
      catch (e) {
        interpreter = await _cpuInterpreter();
        runInterpreter(input, output);
        debugPrint("Interpreter uses CPU");
      }
    }
  }
  
  return interpreter;

}

/// Initializes the TFLite interpreter on Windows.
///
/// Uses the GPU mode if open CL is avail CPU mode.
Future<Interpreter> _initInterpreterWindows() async {

  Interpreter interpreter;

  // get platform information
  //DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //IosDeviceInfo desktopInfo = await deviceInfo.iosInfo;

  try {
    interpreter = await _gpuInterpreter();
    runInterpreter(input, output);
    debugPrint("Interpreter uses GPU open-cl delegate");
  }
  // on exception try XNNPack CPU delegate
  catch (e){
    try{
      interpreter = await _xxnPackInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses XNNPack delegate");
    }
    // on exception use CPU delegate
    catch (e) {
      interpreter = await _cpuInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses CPU");
    }
  }
      
  return interpreter;
}

/// Initializes the TFLite interpreter on Linux.
///
/// Uses the uses CPU mode.
Future<Interpreter> _initInterpreterLinux() async {

  Interpreter interpreter;

  // get platform information
  //DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //IosDeviceInfo desktopInfo = await deviceInfo.iosInfo;

  try {
    interpreter = await _gpuInterpreter();
    runInterpreter(input, output);
    debugPrint("Interpreter uses GPU open-cl delegate");
  }
  // on exception try XNNPack CPU delegate
  catch (e){
    try{
      interpreter = await _xxnPackInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses XNNPack delegate");
    }
    // on exception use CPU delegate
    catch (e) {
      interpreter = await _cpuInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses CPU");
    }
  }
      
  return interpreter;

}

/// Initializes the TFLite interpreter on Mac.
///
/// Uses the uses CPU mode.
Future<Interpreter> _initInterpreterMac() async {

  Interpreter interpreter;

  // get platform information
  //DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //IosDeviceInfo desktopInfo = await deviceInfo.iosInfo;

  try {
    interpreter = await _gpuInterpreter();
    runInterpreter(input, output);
    debugPrint("Interpreter uses GPU open-cl delegate");
  }
  // on exception try XNNPack CPU delegate
  catch (e){
    try{
      interpreter = await _xxnPackInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses XNNPack delegate");
    }
    // on exception use CPU delegate
    catch (e) {
      interpreter = await _cpuInterpreter();
      runInterpreter(input, output);
      debugPrint("Interpreter uses CPU");
    }
  }
      
  return interpreter;
  
}
*/


/// Initializes the interpreter with NPU acceleration for Android.
Future<Interpreter> _nnapiInterpreter(String assetPath) async {
  final options = InterpreterOptions()..useNnApiForAndroid = true;
  Interpreter i = await Interpreter.fromAsset(
    assetPath, 
    options: options
  );

  return i; 
}

/// Initializes the interpreter with GPU acceleration.
Future<Interpreter> _gpuInterpreter(String assetPath) async {
  final gpuDelegateV2 = GpuDelegateV2();
  final options = InterpreterOptions()..addDelegate(gpuDelegateV2);
  Interpreter i = await Interpreter.fromAsset(
    assetPath,
    options: options
  );

  return i;
}

/// Initializes the interpreter with metal acceleration for iOS.
Future<Interpreter> _metalInterpreterIOS(String assetPath) async {

  final gpuDelegate = GpuDelegate(
    options: GpuDelegateOptions(
      allowPrecisionLoss: true, 
      waitType: TFLGpuDelegateWaitType.active),
  );
  var interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegate);
  Interpreter i = await Interpreter.fromAsset(
    assetPath,
    options: interpreterOptions
  );
  
  return i;
}

/// Initializes the interpreter with coreML acceleration for iOS.
Future<Interpreter> _coreMLInterpreterIOS(String assetPath) async {

  var interpreterOptions = InterpreterOptions()..addDelegate(CoreMlDelegate());
  Interpreter i = await Interpreter.fromAsset(
    assetPath,
    options: interpreterOptions
  );

  return i;
}

/// Initializes the interpreter with CPU mode set.
Future<Interpreter> _cpuInterpreter(String assetPath) async {
  final options = InterpreterOptions()
    ..threads = Platform.numberOfProcessors - 1;
  Interpreter i = await Interpreter.fromAsset(
    assetPath, options: options);

  return i;
}

/// Initializes the interpreter with XNNPack-CPU mode set.
Future<Interpreter> _xxnPackInterpreter(String assetPath) async {

  Interpreter interpreter;
  final options = InterpreterOptions()..addDelegate(
    XNNPackDelegate(
      options: XNNPackDelegateOptions(
        numThreads: Platform.numberOfProcessors >= 4 ? 4 : Platform.numberOfProcessors 
      )
    )
  );
  interpreter = await Interpreter.fromAsset(
    assetPath,
    options: options
  );

  return interpreter;
}

