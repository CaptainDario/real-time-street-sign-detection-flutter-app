import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:get_it/get_it.dart';

import 'package:street_sign_detection/tflite/object_detection.dart';
import 'package:street_sign_detection/tflite/stats.dart';
import 'package:street_sign_detection/theme.dart';
import 'package:street_sign_detection/ui/bottom_sheet.dart';
import 'package:street_sign_detection/ui/info_page.dart';
import 'package:street_sign_detection/ml_models.dart';
import 'package:street_sign_detection/ui/camera_object_detector.dart';
import 'package:street_sign_detection/settings.dart';



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

  /// the current y position of the bottom sheet
  double bottomSheetY = 0;
  /// The height of the bottom sheet
  double? bottomSheetHeight;
  /// The minimum y value until where the bottom sheet can be dragged
  double? bottomSheetMinY;
  /// The maximumy value until where the bottom sheet can be draggeds
  double? bottomSheetMaxY;
  /// The minimum size of the bottom sheet
  double bottomSheetMinHeight = 2*8 + 20;
  /// The key to access the bottoms sheets render context
  GlobalKey bottomSheetKey = GlobalKey();

  /// the camera from which the life preview should be shown
  int noSelectedCamera = 0;
  /// The currently used camera controller
  CameraController? currentCameraController;
  /// If the preview is currently running
  bool isPreviewing = true;


  @override
  void initState() {
    super.initState();
    // get the height of the bottom sheet from the last rendered frame and
    // max and min drag values
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        bottomSheetHeight = bottomSheetKey.currentContext!.size!.height;
        bottomSheetY = -bottomSheetHeight! + bottomSheetMinHeight;
        bottomSheetMinY = -bottomSheetHeight! + bottomSheetMinHeight;
        bottomSheetMaxY = 0;
      });
    });
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
      body: Stack(
        children: [
          CameraObjectDetector(
            GetIt.I<List<CameraDescription>>()[noSelectedCamera],
            onCameraControllerCreated: (cameraController) =>
              currentCameraController = cameraController,
          ),

          // change camera button
          Positioned(
            bottom: 50 + (bottomSheetHeight == null ? 0 : bottomSheetMinHeight),
            right: MediaQuery.of(context).size.width / 2 - 40/2,
            child: Container(
              child: IconButton(
                icon: Icon(
                  isPreviewing ? Icons.videocam_off : Icons.videocam,
                  size: 40
                ),
                onPressed: () {
                  setState(() {
                    if(currentCameraController != null && isPreviewing){
                      currentCameraController!.pausePreview();
                      isPreviewing = false;
                    }
                    else if(currentCameraController != null && !isPreviewing){
                      currentCameraController!.resumePreview();
                      isPreviewing = true;
                    }
                  });
                },
              ),
            ),
          ),

          // change camera button
          Positioned(
            bottom: 50 + (bottomSheetHeight == null ? 0 : bottomSheetMinHeight),
            right: 50,
            child: Container(
              child: IconButton(
                icon: Icon(
                  Icons.cameraswitch,
                  size: 40
                ),
                onPressed: () {
                  setState(() {
                    noSelectedCamera += 1;
                    if(noSelectedCamera == GetIt.I<List<CameraDescription>>().length)
                      noSelectedCamera = 0;
                    print("camera index $noSelectedCamera");
                  });
                },
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: bottomSheetHeight == null ? double.infinity : bottomSheetY,
            width: MediaQuery.of(context).size.width,
            child: ChangeNotifierProvider.value(
              value: GetIt.I<InferenceStats>(),
              builder: (context, child) {
                return BottomInfoSheet(
                  key: bottomSheetKey,
                  stats: context.watch<InferenceStats>(),

                  mlModel: GetIt.I<Settings>().mlModel,
                  availablemlModels: MLModels.values,
                  onChangedModel: (value) => setState(() {
                    if(value != null)
                      GetIt.I<Settings>().mlModel = value;
                  }),

                  backend: GetIt.I<Settings>().inferenceBackend,
                  availableBackends: GetIt.I<Settings>().inferenceBackends,
                  onChangedBackend: (backend) => setState(() {
                    if(backend != null)
                      GetIt.I<Settings>().inferenceBackend = backend;
                  }),

                  onDragged: (details) {
                    if(bottomSheetY - details.delta.dy < bottomSheetMinY! || 
                      bottomSheetY - details.delta.dy > bottomSheetMaxY!)
                      return;
                    setState(() {
                      bottomSheetY -= details.delta.dy;
                    });
                  },
                );
              }
            )
          )
        ],
      )
        
      
    );
  }
}
