import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';

import 'package:object_detection/ui/home_view.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await setupGetIt();

  runApp(MyApp());
}

void setupGetIt() async{

  GetIt.I.registerSingleton<List<CameraDescription>>(await availableCameras());
  
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
