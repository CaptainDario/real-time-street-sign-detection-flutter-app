import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';
import 'package:camera/camera.dart';

import 'package:street_sign_detection/settings.dart';
import 'package:street_sign_detection/tflite/stats.dart';
import 'package:street_sign_detection/ui/home_view.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await setupGetIt();

  runApp(SignDetectionApp());
}

Future<void> setupGetIt() async {
  /// current configuration and stats
  GetIt.I.registerSingleton<Settings>(Settings());
  GetIt.I.registerSingleton<InferenceStats>(InferenceStats());

  /// list of all cameras
  GetIt.I.registerSingleton<List<CameraDescription>>(await availableCameras());
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
