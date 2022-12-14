import 'package:flutter/material.dart';

import 'package:camera/camera.dart';



class LiveCameraPreview extends StatefulWidget {

  /// The camera controller from which the video feed should be read.
  final CameraController cameraController;

  const LiveCameraPreview(
    {
      @required this.cameraController,
      Key key
    }
  ) : super(key : key);

  @override
  State<LiveCameraPreview> createState() => _LiveCameraPreviewState();
}

class _LiveCameraPreviewState extends State<LiveCameraPreview> {

  @override
  void initState() {

    widget.cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
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
  Widget build(BuildContext context) {
    if (!widget.cameraController.value.isInitialized) {
      return Container();
    }
    return CameraPreview(widget.cameraController);
  }
}