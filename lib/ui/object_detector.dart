import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:street_sign_detection/tflite/object_detection.dart';

import 'object_detection_painter.dart';
import 'package:street_sign_detection/ui/live_camera_preview.dart';




class ObjectDetector extends StatefulWidget {
  const ObjectDetector({super.key});

  @override
  State<ObjectDetector> createState() => _ObjectDetectorState();
}

class _ObjectDetectorState extends State<ObjectDetector> {

  @override
  void initState() {
    super.initState();
    GetIt.I.registerSingleton(ObjectDetections());
  }

  @override
  void dispose() {
    GetIt.I.unregister<ObjectDetections>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: GetIt.I<ObjectDetections>(),
      builder: (context, child) => Stack(
        children: <Widget>[
          
          SizedBox(
            child: LiveCameraPreview(
              cameraDescription: GetIt.I<List<CameraDescription>>()[0],
            ),
          ),
          Container(
            height: 240,
            width: 320,
            child: CustomPaint(painter: ObjectDetectionPainter(
              context.watch<ObjectDetections>().objectDetections
            ))
          ),
          
          /*
          // change camera button
          Positioned(
            bottom: 50,
            right: 50,
            child: Container(
              height: 100,
              child: IconButton(
                icon: Icon(Icons.cameraswitch),
                onPressed: () {},
              ),
            ),
          ),
          */
    
          // Bottom Sheet
          /*
          Positioned(
            bottom: 0,
            width: MediaQuery.of(context).size.width,
            child: BottomInfoSheet(
              mlModel: mlModel,
              onChanged: (value) => setState(() {
                mlModel = value;
              }),
            )
          )
          */
        ],
      ),
    );
  }
}