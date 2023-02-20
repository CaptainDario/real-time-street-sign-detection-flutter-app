import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as Image;
import 'package:street_sign_detection/utils/nms_utils.dart';
import 'package:universal_io/io.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_utils.dart';
import 'object_detection.dart';



/// Class to bundle all data and methods to run the SignDetection TF Lite model.
/// This includes:
/// * pre- / postprocessing of the data
/// * Define how to run the interpreter
class SignDetectionData {

  ImageProcessor? imageProcessor;

  /// A list containing all labels that the model can detect
  final List<String> labels;

  /// The width of the input image (to this image pre processing is applied)
  int inputImageWidth;
  /// The height of the input image (to this image pre processing is applied)
  int inputImageHeight;
  /// The channels of the input image (to this image pre processing is applied)
  int inputImageChannels;
  /// The width of the input for interpreter
  int modelInputWidth;
  /// The height of the input for interpreter
  int modelInputHeight;
  /// The channels of the input for interpreter
  int modelInputChannels;

  /// The raw output of the model, needs to be processed by `processRawOutput`
  late Map<int, List<List<List<double>>>> output;
  /// The shapes of the output tensors of the model
  late List _outputShapes = [];
  /// The types of the output tensors of the TF Lite model
  late List _outputTypes = [];



  /// Setup this SignDetectionData class. The given input width,
  /// height, channels should match the input to the model and the `labels` the
  /// class labels of the model.
  SignDetectionData(
    this.inputImageHeight, this.inputImageWidth, this.inputImageChannels,
    this.modelInputHeight, this.modelInputWidth, this.modelInputChannels,
    this.labels,
  );

  /// Creates a mock input to the TF Lite model and returns it
  List<ByteBuffer> generateMockInput(){
    return [
      TensorImage.fromTensorBuffer(
        TensorBuffer.createFixedSize(
          [1, modelInputWidth, modelInputHeight, modelInputChannels],
          TfLiteType.float32
        )
      ).buffer
    ];
  }

  /// Allocate output buffers using the given `interpreter`
  void setupOutput(Interpreter interpreter){
    _outputShapes = [];
    _outputTypes = [];

    interpreter.getOutputTensors().forEach((tensor) {
      _outputShapes.add(tensor.shape);
      _outputTypes.add(tensor.type);
    });

    output = {
      0 : List.generate(
        _outputShapes[0][0],
          (_) => new List.generate(_outputShapes[0][1],
            (_) => new List.filled(_outputShapes[0][2], 0.0),
          growable: false),
        growable: false
      ),
    };
  }

  /// Pre processes the given [CameraImage] to a `TensorImage` and returns it
  Future<TensorImage> preProcessRawInput(CameraImage input) async {
    Image.Image img = (await convertCameraImage(input));

    // the camera feed on android does not rotate when the device is in portrait
    if (Platform.isAndroid) {
      img = Image.copyRotate(img, 90);
    }
    

    // convert image to tensor and resize + crop it to the input dimension
    // of the model
    TensorImage tensorImg = TensorImage(TfLiteType.float32);
    tensorImg.loadImage(img);
    if(imageProcessor == null){
      int largestSide = max(this.inputImageHeight, this.inputImageWidth);
      imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(modelInputHeight, modelInputWidth))
        //.add(ResizeOp(modelInputHeight, modelInputWidth, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0.0, 255.0))
        .build();
    }
    
    tensorImg = imageProcessor!.process(tensorImg);
    return tensorImg;
  }

  /// Defines the post process procdure for the interpreter given in the
  /// constructor. 
  List<ObjectDetection> postProcessRawOutput(){
    List<ObjectDetection> detections = [];

    // iterate over all detections
    for (int i = 0; i < _outputShapes[0][2]; i++) {
      // iterate over the detection classifications scores
      for (var j = 4; j < _outputShapes[0][1]; j++) {
        /// Drop classifications below threshold
        if(output[0]![0][j][i] > 0.5){
          // Converts the raw output to BBoxs, confidence scores and classes
          detections.add(
            ObjectDetection(
              (j*_outputShapes[0][2] + i).toInt(),
              labels[j-4],
              output[0]![0][j][i],
              imageProcessor!.inverseTransformRect(
                Rect.fromLTWH(
                  output[0]![0][0][i] - output[0]![0][2][i]/2, 
                  output[0]![0][1][i] - output[0]![0][3][i]/2,
                  output[0]![0][2][i], 
                  output[0]![0][3][i], 
                ),
                inputImageHeight, inputImageWidth
              )
            )  
          );
        }  
      }
    }
    // NMS
    print("detections before NMS ${detections.length}");
    var _detections = nms(detections, 0.5);

    print("detections ${_detections.length}");

    return _detections;
  }

  /// Defines how to run the interpreter
  void runInterpreter(
    Interpreter interpreter,
    List<ByteBuffer> input,
    Map<int, Object> outputs
  )
  {
    interpreter.runForMultipleInputs(input, outputs);
  }
}