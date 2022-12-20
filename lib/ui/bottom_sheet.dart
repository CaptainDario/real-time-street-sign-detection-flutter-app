import 'package:flutter/material.dart';
import 'package:street_sign_detection/tflite/stats.dart';


import 'stats_row.dart';
import 'package:street_sign_detection/tflite/inference_backend.dart';
import 'package:street_sign_detection/theme.dart';
import 'package:street_sign_detection/ml_models.dart';



class BottomInfoSheet extends StatefulWidget {

  /// The inference stats that should be shown in the info sheet
  final InferenceStats stats;

  /// the currently selected TF Lite model
  final MLModels mlModel;
  /// a list of all available TF lite models
  final List<MLModels> availablemlModels;
  /// the callback that is executed when the model should change
  final void Function(MLModels? mlModel)? onChangedModel;

  /// the backend that should be used for inference
  final InferenceBackend backend;
  /// a list of all available inference backends
  final List<InferenceBackend> availableBackends;
  /// the callback that is executed when the model should change
  final void Function(InferenceBackend? backend)? onChangedBackend;

  /// the callback that should be invoked when the users drags the bottom sheet
  final void Function(DragUpdateDetails details)? onDragged;


  const BottomInfoSheet(
    {
      required this.stats,
      required this.mlModel,
      required this.availablemlModels,
      this.onChangedModel,
      required this.backend,
      required this.availableBackends,
      this.onChangedBackend,
      this.onDragged,
      super.key
    }
  );

  @override
  State<BottomInfoSheet> createState() => _BottomInfoSheetState();
}

class _BottomInfoSheetState extends State<BottomInfoSheet> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: widget.onDragged,
      child: Container(
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
              SizedBox(
                height: 20,
                child: Icon(Icons.drag_handle_rounded)
              ),
              SizedBox(height: 8,),
              StatsRow('Pre-processing time:','${widget.stats.preProcessingTime} ms'),
              StatsRow('Inference time:', '${widget.stats.inferenceTime} ms'),
              StatsRow('Pre-processing time:','${widget.stats.postProcessingTime} ms'),
              StatsRow('Total isolate time:','${widget.stats.totalIsolateTime} ms'),
              StatsRow('Isolate communication:','${widget.stats.communicationOverhead} ms'),
              StatsRow('Total prediction time:','${widget.stats.totalTime} ms'),
              
              StatsRow('Image size','${1280} X ${720}'),
              
              // ML models
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: widget.availablemlModels.map((e) => 
                  Row(
                    children: 
                    [
                      Radio<MLModels>(
                        value: e,
                        groupValue: widget.mlModel,
                        activeColor: dcaitiGreen,
                        onChanged: (MLModels? value) {
                          if(widget.onChangedModel != null)
                            widget.onChangedModel!(value);
                        },
                      ),
                      Text(e.name),
                    ]
                  ,)
                ).toList()                 
              ),

              // Inference backends
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: widget.availableBackends.map((e) => 
                  Row(
                    children: 
                    [
                      Radio<InferenceBackend>(
                        value: e,
                        groupValue: widget.backend,
                        activeColor: dcaitiGreen,
                        onChanged: (InferenceBackend? value) {
                          if(widget.onChangedBackend != null)
                            widget.onChangedBackend!(value);
                        }
                      ),
                      Text(e.name),
                    ]
                  ,)
                ).toList()                 
              ),
            ],
          ),
        ),
      ),
    );
  }
}