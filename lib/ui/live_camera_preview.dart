import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:street_sign_detection/tflite/image_utils.dart';

import 'package:street_sign_detection/tflite/object_detection.dart';
import 'package:street_sign_detection/tflite/sign_detection_interpreter.dart';
import 'package:universal_io/io.dart';



/// A widget that shows a live camera preview of the given `cameraDescription`
class LiveCameraPreview extends StatefulWidget {

  /// The cameraDescription from which the video feed should be read.
  final CameraDescription cameraDescription;
  /// The child widget of the camera view
  final Widget? child;

  const LiveCameraPreview(
    {
      this.child,
      required this.cameraDescription,
      super.key
    }
  );

  @override
  State<LiveCameraPreview> createState() => _LiveCameraPreviewState();
}

class _LiveCameraPreviewState extends State<LiveCameraPreview> with WidgetsBindingObserver {

  late CameraController cameraController;

  bool runningInference = false;


  @override
  void initState() {

    cameraController = CameraController(
      widget.cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888
    );

    cameraController.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      await cameraController.startImageStream(onLatestImageAvailable);
      setState(() {});
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
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  /// Callback to receive each frame `CameraImage` perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    
    if(!runningInference){

      runningInference = true;

      GetIt.I<ObjectDetections>().objectDetections =
        (await GetIt.I<SignDetectionInterpreter>().runInference(cameraImage));

        runningInference = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // check that the camera has been initialized
    if (!cameraController.value.isInitialized) {
      return Container(
        child: Text("Camera not initialized"),
      );
    }
    return CameraPreview(
      cameraController,
      child: widget.child,
    ); 
  }

  /// Converts the given `CameraImage` to `Image.Image` and saves it to the 
  /// DocumentsDirectory
  void writeImageToDocsDir(CameraImage cameraImage) async {

    var c = convertCameraImage(cameraImage);
    Directory appDocDirectory = await getApplicationDocumentsDirectory();

    await new Directory(appDocDirectory.path+'/'+'sign_detection').create(recursive: true);
    
    await File(appDocDirectory.path+'/sign_detection/thumbnail.png').writeAsBytes(encodeJpg(c));
    print(appDocDirectory.path+'/'+'sign_detection');
  }

}
