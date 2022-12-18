import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as Image;
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

  ///
  final List<String> labels;

  /// The width of the input for interpreter
  int modelInputWidth;
  /// The height of the input for interpreter
  int modelInputHeight;
  /// The channels of the input for interpreter
  int modelInputChannels;

  /// The raw output of the model, needs to be processed by `processRawOutput`
  late Map<int, ByteBuffer> output;
  /// The shapes of the output tensors of the model
  late List _outputShapes = [];
  /// The types of the output tensors of the TF Lite model
  late List _outputTypes = [];
  /// Output of the model of all locations
  late TensorBuffer outputLocations;
  /// Output of the model for the classes of the  locations
  late TensorBuffer outputClasses;
  /// Output of the model for the objectness scores of locations
  late TensorBuffer outputScores;
  /// Output of the model for the number of locations
  late TensorBuffer numLocations;




  /// Setup this SignDetectionData class. The given input width,
  /// height, channels should match the input to the model and the `labels` the
  /// class labels of the model.
  SignDetectionData(
    this.modelInputHeight,
    this.modelInputWidth,
    this.modelInputChannels,
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

    // TensorBuffers for output tensors
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

  /// Pre processes the given [CameraImage] to a `TensorImage` and returns it
  Future<TensorImage> preProcessRawInput(CameraImage input) async {
    Image.Image img = (await convertCameraImage(input));

    if (Platform.isAndroid) {
      img = Image.copyRotate(img, 90);
    }

    // convert image to tensor and resize + crop it to the input dimension
    // of the model
    TensorImage tensorImg = TensorImage.fromImage(img);
    if(imageProcessor == null)
      imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(320, 320))
        .add(ResizeOp(300, 300, ResizeMethod.BILINEAR))
        .build();
    tensorImg = imageProcessor!.process(tensorImg);

    return tensorImg;
  }

  /// Defines the post process procdure for the interpreter given in the
  /// constructor. 
  List<ObjectDetection> postProcessRawOutput(){
    List<ObjectDetection> detections = [];

    /// Converts the raw output to BBoxs, confidence scores and classes
    /// Drops classifications below threshold
    List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputLocations,
      valueIndex: [1, 0, 3, 2],
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.BOUNDARIES,
      coordinateType: CoordinateType.RATIO,
      height: modelInputHeight,
      width: modelInputWidth,
    );

    for (int i = 0; i < numLocations.getIntValue(0); i++) {
      // Prediction score
      var score = outputScores.getDoubleValue(i);

      // Label string
      var labelIndex = outputClasses.getIntValue(i) + 1;
      var label = labels.elementAt(labelIndex);

      if (score > 0.5) {
        // inverse of rect
        // [locations] corresponds to the image size 300 X 300
        // inverseTransformRect transforms it our [inputImage]
        Rect transformedRect = imageProcessor!.inverseTransformRect(
          locations[i], 240, 320);

        detections.add(
          ObjectDetection(i, label, score, transformedRect),
        );
      }
    }

    return detections;
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