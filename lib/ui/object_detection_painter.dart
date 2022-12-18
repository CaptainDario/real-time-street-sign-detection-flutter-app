import 'package:flutter/material.dart';
import 'package:street_sign_detection/tflite/object_detection.dart';



/// Paints the given detections 
class ObjectDetectionPainter extends CustomPainter {

  /// All detections to draws
  ObjectDetections detections;

  ObjectDetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    
    for (ObjectDetection detection in detections.objectDetections) {
      canvas.drawLine(
        detection.location.topLeft,
        detection.location.bottomLeft,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        detection.location.bottomLeft,
        detection.location.bottomRight,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        detection.location.bottomRight,
        detection.location.topRight,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        detection.location.topRight,
        detection.location.topLeft,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
    }
    
  }


  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(ObjectDetectionPainter oldDelegate) => 
    oldDelegate.detections.objectDetections != detections.objectDetections;
  @override
  bool shouldRebuildSemantics(ObjectDetectionPainter oldDelegate) => false;
}