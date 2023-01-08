import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:street_sign_detection/tflite/object_detection.dart';



/// Paints the given detections 
class ObjectDetectionPainter extends CustomPainter {

  /// All detections to draws
  ObjectDetections detections;
  /// The resolution of the camera feed
  Size cameraFeedSize;

  ObjectDetectionPainter(this.detections, this.cameraFeedSize);

  @override
  void paint(Canvas canvas, Size size) {
    
    for (ObjectDetection detection in detections.objectDetections) {
      // resize the detection to fit canvas size
      Rect l = Rect.fromLTRB(
        detection.location.left   / cameraFeedSize.width  * size.width, 
        detection.location.top    / cameraFeedSize.height * size.height, 
        detection.location.right  / cameraFeedSize.width  * size.width, 
        detection.location.bottom / cameraFeedSize.height * size.height
      );

      canvas.drawLine(
        l.topLeft,
        l.bottomLeft,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        l.bottomLeft,
        l.bottomRight,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        l.bottomRight,
        l.topRight,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
      canvas.drawLine(
        l.topRight,
        l.topLeft,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 5
      );
    
      TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: " " + detection.label + " " + detection.score.toStringAsFixed(2),
          style: new TextStyle(color: Colors.red),
        )
      )..layout()
      ..paint(canvas, l.topLeft);
    }
    
  }


  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(ObjectDetectionPainter oldDelegate) => 
    listEquals(oldDelegate.detections.objectDetections, detections.objectDetections);
  @override
  bool shouldRebuildSemantics(ObjectDetectionPainter oldDelegate) => false;
}