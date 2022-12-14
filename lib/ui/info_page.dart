import 'package:flutter/material.dart';
import 'package:object_detection/theme.dart';



/// Simple info page that shows information about this project
class InfoPage extends StatelessWidget {
  const InfoPage(
    {
      Key key
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dcaitiBlack,
      appBar: AppBar(
        backgroundColor: dcaitiBlue,
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "\n\nThis project is a research coorporation between DCAITI and the TU Berlin.\n"
          "Developers: Dario Klepoch, Marvin Beese, Clemens Lotthermoser",
        ),
      ),
    );
  }
}