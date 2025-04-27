// ignore: file_names
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/ui/home/home_screen.dart';

import '../../constants/size_config.dart';
import '../../constants/color_data.dart';

class TrackOrderScreen extends StatefulWidget {
  final Function? function;

  const TrackOrderScreen({Key? key, this.function}) : super(key: key);

  @override
  _TrackOrderScreen createState() {
    return _TrackOrderScreen();
  }
}

class _TrackOrderScreen extends State<TrackOrderScreen> {
  @override
  void initState() {
    super.initState();

    setState(() {});
  }

  Future<bool> _requestPop() {
    if (widget.function != null) {
      widget.function!();
    } else {
      Constant.sendToScreen(HomeScreen(), context);
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => MainPage()));
    }

    return Future.value(true);
  }

  void doNothing(BuildContext context) {}
  double leftMargin = 0;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    leftMargin = getAppBarPadding();
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double height = Constant.getPercentSize(screenHeight, 12);
    double imageSize = Constant.getPercentSize(height, 67);
    Color borderColor = Colors.grey.shade200;
    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              getDefaultHeader(context, "Track Order", () {
                _requestPop();
              }, (value) {}, isShowSearch: false),
              Expanded(
                flex: 1,
                child: ListView(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: leftMargin),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Container(
                              height: imageSize,
                              width: imageSize,
                              // color: Colors.green,

                              // decoration: getDecoration(radius),

                              margin: EdgeInsets.only(
                                right: Constant.getPercentSize(leftMargin, 70),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    Constant.getPercentSize(imageSize, 20)),
                                child: Image.asset(
                                  Constant.assetImagePath + 'order1.png',
                                  fit: BoxFit.cover,
                                ),
                              )),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: getCustomText(
                                    'Arriving today',
                                    fontBlack,
                                    1,
                                    TextAlign.start,
                                    FontWeight.w400,
                                    Constant.getPercentSize(height, 17),
                                  ),
                                ),
                                getCustomText(
                                  '8 PM',
                                  fontBlack,
                                  1,
                                  TextAlign.start,
                                  FontWeight.bold,
                                  Constant.getPercentSize(height, 16),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: borderColor,
                      margin: EdgeInsets.symmetric(
                          vertical: Constant.getPercentSize(screenHeight, 2),
                          horizontal: leftMargin),
                    ),
                    timelineRow("Ordered on Monday,January 23", "", '', true),
                    timelineRow("Shipped on Monday,January 23", '', '', true),
                    timelineRow(
                        "Out for delivery", 'See all updates', "", true),
                    timelineRow("Arriving today by 8PM", '', "", false),
                    Container(
                      height: 1,
                      color: borderColor,
                      margin: EdgeInsets.symmetric(horizontal: leftMargin),
                    ),
                    Padding(
                      padding: EdgeInsets.all(leftMargin),
                      child: getCustomTextWithoutMaxLine(
                        'Shipped with App Name',
                        fontBlack,
                        TextAlign.start,
                        FontWeight.w800,
                        Constant.getPercentSize(screenHeight, 2.2),
                      ),
                    ),
                    getCell('Request Cancellation'),
                    SizedBox(
                      height: (leftMargin / 2),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: leftMargin),
                      child: Row(
                        children: [
                          getCustomText(
                            'Tracking ID: ',
                            greyFont,
                            1,
                            TextAlign.start,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2),
                          ),
                          Expanded(
                            child: getCustomText(
                              '546859',
                              fontBlack,
                              1,
                              TextAlign.start,
                              FontWeight.w400,
                              Constant.getPercentSize(screenHeight, 2.3),
                            ),
                            flex: 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: borderColor,
                      margin: EdgeInsets.all(leftMargin),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: leftMargin, vertical: leftMargin / 2),
                      child: getCustomTextWithoutMaxLine(
                        'Shipping Address',
                        fontBlack,
                        TextAlign.start,
                        FontWeight.w800,
                        Constant.getPercentSize(screenHeight, 2.2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: leftMargin,
                          right: leftMargin,
                          top: leftMargin,
                          bottom: Constant.getPercentSize(leftMargin, 18)),
                      child: getCustomTextWithoutMaxLine(
                        '1901 Thornridge Cir.Shilon,Hawaii 81063',
                        fontBlack,
                        TextAlign.start,
                        FontWeight.w500,
                        Constant.getPercentSize(screenHeight, 2.3),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: leftMargin,
                          right: leftMargin,
                          bottom: leftMargin),
                      child: getCustomText(
                          "See all updates",
                          primaryColor,
                          2,
                          TextAlign.start,
                          FontWeight.w400,
                          Constant.getHeightPercentSize(2)),
                    ),
                    getCell('Request or Replace Items'),
                    getCell('View Order Details'),
                  ],
                ),
              )
            ],
          ),
        ),
        onWillPop: _requestPop);
  }

  getCell(String s) {
    return Container(
      margin: EdgeInsets.only(
          left: leftMargin,
          right: leftMargin,
          bottom: Constant.getHeightPercentSize(2)),
      padding: EdgeInsets.all(Constant.getHeightPercentSize(2.2)),
      decoration: getButtonShapeDecoration(cardColor,
          withCustomCorner: true, corner: Constant.getHeightPercentSize(1.5)),
      child: Row(
        children: [
          Expanded(
            child: getCustomTextWithoutMaxLine(
              s,
              fontBlack,
              TextAlign.start,
              FontWeight.w500,
              Constant.getHeightPercentSize(2),
            ),
            flex: 1,
          ),
          getSvgImage("ArrowRight.svg", Constant.getHeightPercentSize(2.6))
        ],
      ),
    );
  }

  Widget timelineRow(
      String title, String desc, String subTitle, bool isSelect) {
    double size = Constant.getHeightPercentSize(2.8);
    double height = Constant.getHeightPercentSize(7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: size,
                height: size,
                child: isSelect
                    ? Icon(
                        Icons.check_circle_sharp,
                        size: size,
                        color: primaryColor,
                      )
                    : Image.asset(
                        Constant.assetImagePath + "un_selected_check.png",
                        height: size,
                        width: size,
                        color: greyFont,
                      ),
              ),
              SizedBox(
                width: Constant.getWidthPercentSize(0.2),
                height: (isSelect) ? height : 0,
                child: (isSelect)
                    ? DottedLine(
                        dashLength: 3.0,
                        lineThickness: 3,
                        dashRadius: 0.0,
                        dashGapLength: 3.0,
                        dashColor: isSelect ? (primaryColor) : greyFont,
                        direction: Axis.horizontal,
                        lineLength: (height),
                      )
                    : Container(),

                // decoration: new BoxDecoration(
                //   color: isSelect?(primaryColor):Colors.grey,
                //   shape: BoxShape.rectangle,
                // ),
                // child: Text(""),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: Constant.fontsFamily,
                            fontSize: Constant.getHeightPercentSize(2.2),
                            fontWeight: FontWeight.w600,
                            color: fontBlack)),
                    SizedBox(
                      height: Constant.getHeightPercentSize(1),
                    ),
                    getCustomText(desc, primaryColor, 2, TextAlign.start,
                        FontWeight.w400, Constant.getHeightPercentSize(2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
