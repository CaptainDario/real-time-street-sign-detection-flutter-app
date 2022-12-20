import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import 'package:street_sign_detection/tflite/object_detection.dart';
import 'object_detection_painter.dart';
import 'package:street_sign_detection/tflite/sign_detection_interpreter.dart';
import 'package:street_sign_detection/tflite/stats.dart';




/// A widget to show a live camera feed and draw object detections on top of it
class CameraObjectDetector extends StatefulWidget {

  /// the camera description of the camera that should be used for the live preview
  final CameraDescription cameraDescription;
  /// Called when the cameraController was created and provides it as argument
  final void Function(CameraController cameraController)? onCameraControllerCreated;


  const CameraObjectDetector(
    this.cameraDescription,
    {
      this.onCameraControllerCreated,
      super.key
    }
  );

  @override
  State<CameraObjectDetector> createState() => _CameraObjectDetectorState();
}

class _CameraObjectDetectorState extends State<CameraObjectDetector> with WidgetsBindingObserver {

  /// The cameraController which is used for live object detection
  late CameraController cameraController;
  /// Is currently inference running
  bool runningInference = false;


  @override
  void initState() {
    super.initState();

    GetIt.I.registerSingleton(ObjectDetections());

    initCameraController(widget.cameraDescription);
  }

  @override
  void dispose() {
    GetIt.I.unregister<ObjectDetections>();
    cameraController.dispose();
    super.dispose();
  }

  /// Resume/stop camera stream when opening/sclosing the app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!cameraController.value.isStreamingImages) {
          await cameraController.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  /// Initializes the `cameraController`with the given `CameraDescription` by
  /// This is done by starting a life view and subscribing to the image stream
  /// with `onLatestImageAvailable`
  Future<void> initCameraController(CameraDescription desc) async {
    cameraController = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888
    );

    cameraController.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      await cameraController.startImageStream(onLatestImageAvailable);
      setState(() {
        if(widget.onCameraControllerCreated != null)
          widget.onCameraControllerCreated!(cameraController);
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  /// Callback to receive each frame `CameraImage` perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
    
    if(!runningInference){

      runningInference = true;

      var result =
        (await GetIt.I<SignDetectionInterpreter>().runInference(cameraImage));

      GetIt.I<ObjectDetections>().objectDetections = result.item1;
      GetIt.I<InferenceStats>().copy(result.item2);

      runningInference = false;
    }
  }

  @override
  Widget build(BuildContext context) {

    // if the user changed the current camera create a new camera controller
    if(cameraController.description != widget.cameraDescription)
      initCameraController(widget.cameraDescription);

    return ChangeNotifierProvider.value(
      value: GetIt.I<ObjectDetections>(),
      builder: (context, child) {

         // check that the camera has been initialized
        if (!cameraController.value.isInitialized) {
          return Container(
            child: Text("Camera not initialized"),
          );
        }
        return CameraPreview(
          cameraController,
          child: CustomPaint(
            painter: ObjectDetectionPainter(
              context.watch<ObjectDetections>(),
              Size(720, 1280)
            )
          ),
        ); 

      }
    );
  }
}