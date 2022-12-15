import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';

import 'package:camera/camera.dart';
import 'package:object_detection/ui/home_view.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await setupGetIt();

  runApp(MyApp());
}

Future<void> setupGetIt() async {

  /// list of all cameras
  GetIt.I.registerSingleton<List<CameraDescription>>(await availableCameras());

  /// the object detection model
  //GetIt.I.registerSingleton<Classifier>(Classifier());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DCAITI - Street Sign Detection',
      theme: ThemeData.dark(),
      home: HomeView(),
    );
  }
}
