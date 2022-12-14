import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:object_detection/ml_models.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/tflite/stats.dart';
import 'package:object_detection/ui/box_widget.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';

import 'package:object_detection/theme.dart';
import 'camera_view.dart';

/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<Recognition> results;

  /// Realtime stats
  Stats stats;

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  bool statsOpen = false;

  MLModels mlModel = MLModels.YOLOV5;

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
                    onPressed: () => setState(() => statsOpen = !statsOpen), 
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
          // Camera View
          Center(
            child: CameraView(resultsCallback, statsCallback)
          ),

          // Bounding boxes
          Align(
            alignment: Alignment.topCenter,
            child: boundingBoxes(results)
          ),

          // Bottom Sheet
          stats != null
            ? Positioned(
              top: statsOpen ? null : MediaQuery.of(context).size.height - 50,
              bottom: statsOpen ? 0 : null,
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  color: dcaitiBlue,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatsRow('Inference time:',
                          '${stats.inferenceTime} ms'),
                      StatsRow('Total prediction time:',
                          '${stats.totalElapsedTime} ms'),
                      StatsRow('Pre-processing time:',
                          '${stats.preProcessingTime} ms'),
                      StatsRow('Frame',
                          '${CameraViewSingleton.inputImageSize?.width} X ${CameraViewSingleton.inputImageSize?.height}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [MLModels.YOLOV5, MLModels.YOLOV7, MLModels.CascadeRCNN].map((e) => 
                          Row(
                            children: 
                            [
                              Radio<MLModels>(
                                value: e,
                                groupValue: mlModel,
                                activeColor: dcaitiGreen,
                                onChanged: (MLModels value) {
                                  setState(() {
                                    mlModel = value;
                                  });
                                },
                              ),
                              Text(e.name),
                            ]
                          ,)
                        ).toList()                 
                      ),
                      Text(
                        "\n\nThis project is a research coorporation between DCAITI and the TU Berlin.\n"
                        "Developers: Dario Klepoch, Marvin Beese, Clemens Lotthermoser",
                        textScaleFactor: 0.8,
                      )
                    ],
                  ),
                ),
              ),
            )
          : SizedBox()
        ],
      ),
    );
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
                result: e,
              ))
          .toList(),
    );
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
    });
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  StatsRow(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
