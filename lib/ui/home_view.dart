import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';
import 'package:street_sign_detection/tflite/object_detection.dart';

import 'package:street_sign_detection/theme.dart';
import 'package:street_sign_detection/ui/info_page.dart';
import 'package:street_sign_detection/ml_models.dart';
import 'live_camera_preview.dart';



/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<ObjectDetection> results = [];

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  /// currently selected ML model
  MLModels mlModel = MLModels.YOLOV5;

  @override
  void initState() {
    
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
                      MaterialPageRoute(builder: (context) => InfoPage()),
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
      backgroundColor: dcaitiBlack,
      body: Stack(
        children: <Widget>[
          
          LiveCameraPreview(
            cameraDescription: GetIt.I<List<CameraDescription>>()[0],
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
