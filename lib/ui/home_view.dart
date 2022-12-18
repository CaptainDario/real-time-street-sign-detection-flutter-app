import 'package:flutter/material.dart';

import 'package:street_sign_detection/tflite/object_detection.dart';

import 'package:street_sign_detection/theme.dart';
import 'package:street_sign_detection/ui/info_page.dart';
import 'package:street_sign_detection/ml_models.dart';
import 'package:street_sign_detection/ui/object_detector.dart';



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
        title: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [dcaitiGreen.withAlpha(50), dcaitiBlue, dcaitiBlue]),
          ),
          child: Row(
            children: [
              Container(
                height: AppBar().preferredSize.height,
                width: AppBar().preferredSize.height,
                color: dcaitiGreen,
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InfoPage()),
                  ), 
                  icon: Icon(Icons.info)
                ),
              ),
              Spacer(),
              Container(
                height: AppBar().preferredSize.height*0.8,
                child: Image.asset("assets/icon/dcaiti.png")
              ),
            ],
          ),
        ),
      ),
      key: scaffoldKey,
      backgroundColor: dcaitiBlack,
      body: ObjectDetector()
    );
  }
}
