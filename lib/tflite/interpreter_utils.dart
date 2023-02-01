import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:universal_io/io.dart';

import 'inference_backend.dart';



/// Checks for the available backends and uses the best available backend.
/// For this a valid `input`, `output` and function `runInterpreter` (defines
/// how to run the given TF Lite model at `tfLiteAssetPath)` needs to be provided
/// With `exclude` certain delegates can be excluded.
/// `iterations` denotes how many times the time for running inference should be
/// measured.
/// A map containing the backends with their
/// time is returned. If a backend is not included that means that this backend
/// is not available on this device with this model.
/// 
/// Delegate support and order: 
/// * iOS    : CoreML > Metal > XNNPack > CPU <br/>
/// * Android: NNApi > GPU > XNNPack > CPU <br/>
/// * Windows: GPU (OpenCL) > XNNPack > CPU <br/>
/// * Mac    : GPU (OpenCL) > XNNPack > CPU <br/>
/// * Linux  : GPU (OpenCL) > XNNPack > CPU <br/>
Future<Map<InferenceBackend, double>> getBestBackend(
  String tfLiteAssetPath,
  Object input,
  Object output,
  void Function(Interpreter interpreter, Object input, Object output) runInterpreter,
  {
    List<InferenceBackend> exclude = const [],
    int iterations = 1
  }
  ) async 
{

  Map<InferenceBackend, double> backendStats;

  
  if (Platform.isAndroid) {
    backendStats = await _testInterpreterAndroid(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output),
      exclude: exclude,
      iterations: iterations
    );
  }
  
  else if (Platform.isIOS) {
    backendStats = await _testInterpreterIOS(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output),
      exclude: exclude,
      iterations: iterations
    );
  }
  else if(Platform.isWindows) {
    backendStats = await _testInterpreterWindows(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output),
      exclude: exclude,
      iterations: iterations
    );
  }
  else if(Platform.isLinux) {
    backendStats = await _testInterpreterLinux(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output),
      exclude: exclude,
      iterations: iterations
    );
  }
  else if(Platform.isMacOS) {
    backendStats = await _testInterpreterMac(
      tfLiteAssetPath,
      (Interpreter interpreter) => runInterpreter(interpreter, input, output),
      exclude: exclude,
      iterations: iterations
    );
  }
  else {
    throw Exception("Platform not supported.");
  }
  

  return backendStats;
}

/// Instantiates an interpereter using the given TF Lite model asset and 
/// backend
Future<Interpreter> initInterpreterFromBackend(
  InferenceBackend inferenceBackend,
  String assetPath
  ) async
{
  if(inferenceBackend == InferenceBackend.CPU){
    return _cpuInterpreter(assetPath);
  }
  else if(inferenceBackend == InferenceBackend.XNNPack){
    return await _xxnPackInterpreter(assetPath);
  }
  else if(inferenceBackend == InferenceBackend.GPU){
    return await _gpuInterpreter(assetPath);
  }
  else if(inferenceBackend == InferenceBackend.NNApi){
    return await _nnapiInterpreter(assetPath);
  }
  else if(inferenceBackend == InferenceBackend.Metal){
    return await _metalInterpreterIOS(assetPath);
  }
  else if(inferenceBackend == InferenceBackend.CoreML2){
    return await _coreMLInterpreterIOS(assetPath, CoreMLVersion: 2);
  }
  else if(inferenceBackend == InferenceBackend.CoreML3){
    return await _coreMLInterpreterIOS(assetPath, CoreMLVersion: 3);
  }
  else{
    throw Exception("Unknown inference backend");
  }
}

/// Initializes the TFLite interpreter on android. Uses either NNAPI, GPU,
/// XNNPack or CPU delegate. For each backend an interpreter is created and
/// the time to run inference measured. 
/// 
/// See `initOptimalInterpreter()` for parameter usage
Future<Map<InferenceBackend, double>> _testInterpreterAndroid(
  String assetPath,
  void Function(Interpreter interpreter) runInterpreter,
  {
    List<InferenceBackend> exclude = const [],
    int iterations = 1
  }
  ) async 
{

  Map<InferenceBackend, double> inferenceBackend = {}; Stopwatch s = Stopwatch();
  Function testBackend = (Interpreter interpreter, InferenceBackend i){
    s.start(); runInterpreter(interpreter); s.stop();
    inferenceBackend.putIfAbsent(i, () => 0);
    inferenceBackend[i] =
      inferenceBackend[i]! + s.elapsed.inMilliseconds / iterations;
    s.reset();
  };

  for (var i = 0; i < iterations; i++) {
    // NNAPI delegate
    if(!exclude.contains(InferenceBackend.NNApi)){
      try{
        Interpreter interpreter = await _nnapiInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.NNApi);
      }
      catch (e){}
    }
    // GPU delegate
    if(!exclude.contains(InferenceBackend.GPU)){
      try {
        Interpreter interpreter = await _gpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.GPU);
      }
      catch (e){}
    }
    // XNNPack delegate
    if(!exclude.contains(InferenceBackend.XNNPack)){
      try{
        Interpreter interpreter = await _xxnPackInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.XNNPack);
      }
      catch (e) {}
    }
    // CPU delegate
    if(!exclude.contains(InferenceBackend.CPU)){
      try{
        Interpreter interpreter = await _cpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.CPU);
      }
      catch (e){}
    }
  }

  return inferenceBackend;
}

/// Initializes the TFLite interpreter on iOS.
///
/// Uses either CoreML (2|3), Metal, XNNPack or CPU delegate
Future<Map<InferenceBackend, double>> _testInterpreterIOS(
    String assetPath,
    void Function(Interpreter interpreter) runInterpreter,
    {
      List<InferenceBackend> exclude = const [],
      int iterations = 1
    }
  ) async 
{

  Map<InferenceBackend, double> inferenceBackend = {}; Stopwatch s = Stopwatch();

  Function testBackend = (Interpreter interpreter, InferenceBackend i){
    s.start(); runInterpreter(interpreter); s.stop();
    inferenceBackend.putIfAbsent(i, () => 0);
    inferenceBackend[i] =
      inferenceBackend[i]! + s.elapsed.inMilliseconds / iterations;
    s.reset();
  };

  for (var i = 0; i < iterations; i++) {
    // CoreML 3 delegate
    if(!exclude.contains(InferenceBackend.CoreML3)){
      try{
        Interpreter interpreter = await _coreMLInterpreterIOS(assetPath, CoreMLVersion: 3);
        testBackend(interpreter, InferenceBackend.CoreML3);
      }
      catch (e){}
    }
    // CoreML 2 delegate
    if(!exclude.contains(InferenceBackend.CoreML2)){
      try{
        Interpreter interpreter = await _coreMLInterpreterIOS(assetPath, CoreMLVersion: 2);
        testBackend(interpreter, InferenceBackend.CoreML2);
      }
      catch (e){}
    }
    // Metal delegate
    if(!exclude.contains(InferenceBackend.GPU)){
      try {
        Interpreter interpreter = await _metalInterpreterIOS(assetPath);
        testBackend(interpreter, InferenceBackend.Metal);
      }
      catch (e){}
    }
    // XNNPack delegate
    if(!exclude.contains(InferenceBackend.XNNPack)){
      try{
        Interpreter interpreter = await _xxnPackInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.XNNPack);
      }
      catch (e) {}
    }
    // CPU delegate
    if(!exclude.contains(InferenceBackend.CPU)){
      try{
        Interpreter interpreter = await _cpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.CPU);
      }
      catch (e){}
    }
  }

  return inferenceBackend;
}


/// Initializes the TFLite interpreter on Windows.
///
/// Uses the GPU (OpenCL), XNNPack or CPU mode
Future<Map<InferenceBackend, double>> _testInterpreterWindows(
  String assetPath,
  void Function(Interpreter interpreter) runInterpreter,
  {
    List<InferenceBackend> exclude = const [],
    int iterations = 1
  }
  ) async 
{
  Map<InferenceBackend, double> inferenceBackend = {}; Stopwatch s = Stopwatch();
  Function testBackend = (Interpreter interpreter, InferenceBackend i){
    s.start(); runInterpreter(interpreter); s.stop();
    inferenceBackend.putIfAbsent(i, () => 0);
    inferenceBackend[i] =
      inferenceBackend[i]! + s.elapsed.inMilliseconds / iterations;
    s.reset();
  };

  for (var i = 0; i < iterations; i++) {
    // GPU delegate
    if(!exclude.contains(InferenceBackend.GPU)){
      try {
        Interpreter interpreter = await _gpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.GPU);
      }
      catch (e){}
    }
    // XNNPack delegate
    if(!exclude.contains(InferenceBackend.XNNPack)){
      try{
        Interpreter interpreter = await _xxnPackInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.XNNPack);
      }
      catch (e) {}
    }
    // CPU delegate
    if(!exclude.contains(InferenceBackend.CPU)){
      try{
        Interpreter interpreter = await _cpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.CPU);
      }
      catch (e){}
    }
  }

  return inferenceBackend;
}

/// Initializes the TFLite interpreter on Linux.
///
/// Uses the GPU (OpenCL), XNNPack or CPU mode
Future<Map<InferenceBackend, double>> _testInterpreterLinux(
  String assetPath,
  void Function(Interpreter interpreter) runInterpreter,
  {
    List<InferenceBackend> exclude = const [],
    int iterations = 1
  }
  ) async 
{
  Map<InferenceBackend, double> inferenceBackend = {}; Stopwatch s = Stopwatch();
  Function testBackend = (Interpreter interpreter, InferenceBackend i){
    s.start(); runInterpreter(interpreter); s.stop();
    inferenceBackend.putIfAbsent(i, () => 0);
    inferenceBackend[i] =
      inferenceBackend[i]! + s.elapsed.inMilliseconds / iterations;
    s.reset();
  };

  for (var i = 0; i < iterations; i++) {
    // GPU delegate
    if(!exclude.contains(InferenceBackend.GPU)){
      try {
        Interpreter interpreter = await _gpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.GPU);
      }
      catch (e){}
    }
    // XNNPack delegate
    if(!exclude.contains(InferenceBackend.XNNPack)){
      try{
        Interpreter interpreter = await _xxnPackInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.XNNPack);
      }
      catch (e) {}
    }
    // CPU delegate
    if(!exclude.contains(InferenceBackend.CPU)){
      try{
        Interpreter interpreter = await _cpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.CPU);
      }
      catch (e){}
    }
  }

  return inferenceBackend;
}

/// Initializes the TFLite interpreter on Mac.
///
/// Uses the GPU (OpenCL), XNNPack or CPU mode
Future<Map<InferenceBackend, double>> _testInterpreterMac(
  String assetPath,
  void Function(Interpreter interpreter) runInterpreter,
  {
    List<InferenceBackend> exclude = const [],
    int iterations = 1
  }
  ) async 
{
  Map<InferenceBackend, double> inferenceBackend = {}; Stopwatch s = Stopwatch();
  Function testBackend = (Interpreter interpreter, InferenceBackend i){
    s.start(); runInterpreter(interpreter); s.stop();
    inferenceBackend.putIfAbsent(i, () => 0);
    inferenceBackend[i] =
      inferenceBackend[i]! + s.elapsed.inMilliseconds / iterations;
    s.reset();
  };

  for (var i = 0; i < iterations; i++) {
    // GPU delegate
    if(!exclude.contains(InferenceBackend.GPU)){
      try {
        Interpreter interpreter = await _gpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.GPU);
      }
      catch (e){}
    }
    // XNNPack delegate
    if(!exclude.contains(InferenceBackend.XNNPack)){
      try{
        Interpreter interpreter = await _xxnPackInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.XNNPack);
      }
      catch (e) {}
    }
    // CPU delegate
    if(!exclude.contains(InferenceBackend.CPU)){
      try{
        Interpreter interpreter = await _cpuInterpreter(assetPath);
        testBackend(interpreter, InferenceBackend.CPU);
      }
      catch (e){}
    }
  }

  return inferenceBackend;
}


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
Future<Interpreter> _coreMLInterpreterIOS(
  String assetPath,
  {
    int CoreMLVersion = 1
  }
  ) async 
{

  var interpreterOptions = InterpreterOptions()..addDelegate(
    CoreMlDelegate(
      options: CoreMlDelegateOptions(
        coremlVersion: CoreMLVersion,
      )
    )
  );
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

