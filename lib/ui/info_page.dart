import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:street_sign_detection/theme.dart';



/// Simple info page that shows information about this project
class InfoPage extends StatelessWidget {
  const InfoPage(
    {
      super.key
    }
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dcaitiBlack,
      appBar: AppBar(
        backgroundColor: dcaitiBlue,
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: MediaQuery.of(context).size.width*0.2,
                  child: Image.asset("assets/icon/tu.png"),
                ),
                Container(
                  color: Colors.green,
                  height: MediaQuery.of(context).size.width*0.2,
                  child: SvgPicture.asset("assets/icon/dcaiti.svg"),
                  //color: Colors.white,
                )
              ],
            ),
            Text(
              "\n\nThis project is a research coorporation between DCAITI and the TU Berlin.\n"
              "Developers: Dario Klepoch, Marvin Beese, Clemens Lottermoser",
            ),
          ],
        ),
      ),
    );
  }
}