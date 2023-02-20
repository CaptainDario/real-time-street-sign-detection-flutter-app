import 'dart:math';
import 'package:flutter/material.dart';

import 'package:street_sign_detection/tflite/object_detection.dart';



// non-maximum suppression
List<ObjectDetection> nms(List<ObjectDetection> detections, double threshold) 
{
    List<ObjectDetection> nmsList = <ObjectDetection>[];

    // sort detections by confidence
    detections.sort((a, b) => b.score.compareTo(a.score));

    while (detections.isNotEmpty) {
      nmsList.add(detections.removeAt(0));

      List<ObjectDetection> detsCopy = List<ObjectDetection> .from(detections);
      for (int i=detections.length-1; i>=0; i--) {
        if (boxIou(nmsList.last.location, detections[i].location) > threshold) {
          detsCopy.removeAt(i);
        }
      }
      detections = detsCopy;
        
    }

    return nmsList;
}

/// Returns the intersection over union of two bounding boxes.
double boxIou(Rect a, Rect b) {
  double interArea = boxIntersection(a, b);
  double unionArea = boxUnion(a, b);
  return interArea / unionArea;
}

/// Calcualtes the intersection of two rects
double boxIntersection(Rect a, Rect b) {
  double w = (min(a.right, b.right) - max(a.left, b.left)).clamp(0.0, double.infinity);
  double h = (min(a.bottom, b.bottom) - max(a.top, b.top)).clamp(0.0, double.infinity);
  return w * h;
}

/// Calculates the union of two rects
double boxUnion(Rect a, Rect b) {
  double i = boxIntersection(a, b);
  return boxArea(a) + boxArea(b) - i;
}

/// Returns the area of this Rect.
double boxArea(Rect a) {
  return a.width * a.height;
}