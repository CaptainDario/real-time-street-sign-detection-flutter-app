
# DCAITI-street-sign-detection-app

The source code for the flutter app of the DCAITI project: KI-basierte Algorithmen zur Objektdetektion und Klassifizierung für mobile Plattformen

## Installation

**Note** Flutter needs to be installed on this system.

1. Clone this repo `git clone https://github.com/CaptainDario/street_sign_detection_app`
2. Change in this directory `cd street_sign_detection_app`
3. Clone the fork of tflite_flutter_plugin into the plugins folder `git clone https://github.com/CaptainDario/tflite_flutter_plugin plugins/`.
   1. Follow the [install instructions of the plugin](https://github.com/CaptainDario/tflite_flutter_plugin#initial-setup--add-dynamic-libraries-to-your-app)
   2. Get dependencies in the directory of tflite_flutter_plugin `cd plugins/tflite_flutter_plugin; flutter pub get`
4. Run `cd ../../; flutter pub get` in this app's directory

Now you should be able to run the app.
