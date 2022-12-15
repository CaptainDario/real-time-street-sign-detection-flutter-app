import 'package:flutter/material.dart';

import 'stats_row.dart';
import 'package:street_sign_detection/theme.dart';
import 'package:street_sign_detection/tflite/stats.dart';
import 'package:street_sign_detection/ml_models.dart';



class BottomInfoSheet extends StatefulWidget {

  final MLModels mlModel;

  final void Function(MLModels? mlModel)? onChanged;

  const BottomInfoSheet(
    {
      required this.mlModel,
      this.onChanged,
      super.key
    }
  );

  @override
  State<BottomInfoSheet> createState() => _BottomInfoSheetState();
}

class _BottomInfoSheetState extends State<BottomInfoSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            //StatsRow('Inference time:',
            //    '${stats.inferenceTime} ms'),
            //StatsRow('Total prediction time:',
            //    '${stats.totalElapsedTime} ms'),
            //StatsRow('Pre-processing time:',
            //    '${stats.preProcessingTime} ms'),
            //StatsRow('Frame',
            //    '${CameraViewSingleton.inputImageSize?.width} X ${CameraViewSingleton.inputImageSize?.height}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [MLModels.YOLOV5, MLModels.YOLOV7, MLModels.CascadeRCNN].map((e) => 
                Row(
                  children: 
                  [
                    Radio<MLModels>(
                      value: e,
                      groupValue: widget.mlModel,
                      activeColor: dcaitiGreen,
                      onChanged: (MLModels? value) {
                        if(widget.onChanged != null)
                          widget.onChanged!(value);
                      },
                    ),
                    Text(e.name),
                  ]
                ,)
              ).toList()                 
            ),
          ],
        ),
      ),
    );
  }
}