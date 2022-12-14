import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';

import 'package:object_detection/theme.dart';
import 'package:object_detection/ui/bottom_sheet.dart';
import 'package:object_detection/ui/info_page.dart';
import 'package:object_detection/ml_models.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'live_camera_preview.dart';



/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<Recognition> results;

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  MLModels mlModel = MLModels.YOLOV5;

  CameraController cameraController;

  @override
  void initState() {
    cameraController = CameraController(
      GetIt.I<List<CameraDescription>>()[0],
      ResolutionPreset.low,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: dcaitiBlue,
        title: Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: dcaitiGreen,
                  child: IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InfoPage()),
                    ), 
                    icon: Icon(Icons.info)
                  ),
                ),
              ),
            ),
            Spacer(),
            Text("DCAITI - Street Sign Detection "),
          ],
        ),
      ),
      key: scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          
          LiveCameraPreview(
            cameraController: cameraController,
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
        ],
      ),
    );
  }
}
