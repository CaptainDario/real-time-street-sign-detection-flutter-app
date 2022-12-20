import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';

import 'package:street_sign_detection/settings.dart';
import 'package:street_sign_detection/tflite/sign_detection_interpreter.dart';
import 'package:street_sign_detection/tflite/stats.dart';
import 'package:street_sign_detection/ui/home_view.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await setupGetIt();

  runApp(SignDetectionApp());
}

Future<void> setupGetIt() async {

  /// list of all cameras
  GetIt.I.registerSingleton<List<CameraDescription>>(await availableCameras());

  /// the object detection model
  GetIt.I.registerSingleton<SignDetectionInterpreter>(
    SignDetectionInterpreter(name: "StreetSignDetectionInterpreter")
  );
  await GetIt.I<SignDetectionInterpreter>().init(
    1280, 720, 3,
    300, 300, 3
  );

  /// current configuration and stats
  GetIt.I.registerSingleton<Settings>(Settings());
  GetIt.I.registerSingleton<InferenceStats>(InferenceStats());
}

class SignDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DCAITI - Street Sign Detection',
      theme: ThemeData.dark(),
      home: HomeView(),
    );
  }
}
