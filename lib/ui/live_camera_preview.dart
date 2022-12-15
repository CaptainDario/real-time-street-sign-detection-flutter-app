import 'package:flutter/material.dart';

import 'package:camera/camera.dart';



class LiveCameraPreview extends StatefulWidget {

  /// The camera controller from which the video feed should be read.
  final CameraDescription cameraDescription;

  const LiveCameraPreview(
    {
      required this.cameraDescription,
      super.key
    }
  );

  @override
  State<LiveCameraPreview> createState() => _LiveCameraPreviewState();
}

class _LiveCameraPreviewState extends State<LiveCameraPreview> with WidgetsBindingObserver {

  late CameraController cameraController;

  bool predicting = false;

  @override
  void initState() {

    cameraController = CameraController(
      widget.cameraDescription,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888
    );

    cameraController.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      //await cameraController.startImageStream(onLatestImageAvailable);
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

  /// Resume/stop camera stream when closing the app
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

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    // convert image to UINT 8
    
  }

  @override
  Widget build(BuildContext context) {
    // check that the camera has been initialized
    if (!cameraController.value.isInitialized) {
      return Container();
    }
    return CameraPreview(cameraController); 
  }

}