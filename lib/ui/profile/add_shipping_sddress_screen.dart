// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';

import '../../constants/select_state.dart';
import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';

class AddShippingAddressScreen extends StatefulWidget {
  const AddShippingAddressScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddShippingAddressScreen();
  }
}

class _AddShippingAddressScreen extends State<AddShippingAddressScreen> {
  _requestPop() {
    Constant.backToFinish(context);
  }

  TextEditingController txtControllerName =
      TextEditingController(text: "Jennie");
  TextEditingController txtPinCode = TextEditingController(text: "83475");
  TextEditingController txtControllerAddress =
      TextEditingController(text: "2715 Ash Dr.San Jose, South Dakota 83475");

  String countryValue = "";
  String stateValue = "";
  String cityValue = "";

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double appBarPadding = getAppBarPadding();

    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getDefaultHeader(context, "Shipping Address", () {
                  _requestPop();
                }, (value) {}, isShowSearch: false),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: appBarPadding,
                      right: appBarPadding,
                      top: appBarPadding,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: appBarPadding, vertical: appBarPadding),
                        decoration: ShapeDecoration(
                            color: cardColor,
                            shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                    cornerRadius: Constant.getPercentSize(
                                        screenHeight, 2),
                                    cornerSmoothing: 0.5))),
                        child: Column(
                          children: [
                            getDefaultTextFiledWithoutIconWidget(
                                context, "Name", txtControllerName),
                            getDefaultTextFiledWithoutIconWidget(
                                context, "Address", txtControllerAddress,
                                minLines: true),
                            getDefaultTextFiledWithoutIconWidget(
                                context, "PinCode", txtPinCode),
                            SelectState(
                              // style: TextStyle(color: Colors.red),
                              onCountryChanged: (value) {
                                setState(() {
                                  countryValue = value;
                                });
                              },
                              onStateChanged: (value) {
                                setState(() {
                                  stateValue = value;
                                });
                              },
                              onCityChanged: (value) {
                                setState(() {
                                  cityValue = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  flex: 1,
                ),
                getButton(primaryColor, true, "Save", Colors.white, () {
                  _requestPop();
                  // Constant.sendToScreen(ShippingAddressScreen(), context);
                }, FontWeight.w700, EdgeInsets.all(appBarPadding))
              ],
            ),
          ),
        ),
        onWillPop: () async {
          _requestPop();
          return false;
        });
  }

  Widget getDefaultTextFiledWithoutIconWidget(BuildContext context, String s,
      TextEditingController textEditingController,
      {bool withPrefix = false, String imgName = "", bool minLines = false}) {
    double height = getEditHeight();

    double radius = Constant.getPercentSize(height, 20);
    double fontSize = Constant.getPercentSize(height, 30);
    FocusNode myFocusNode = FocusNode();
    bool isAutoFocus = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: (minLines) ? (height * 2.2) : height,
          margin: EdgeInsets.symmetric(
              vertical: Constant.getHeightPercentSize(1.2)),
          padding: EdgeInsets.symmetric(
              horizontal: Constant.getWidthPercentSize(2.5)),
          alignment: (minLines) ? Alignment.topLeft : Alignment.centerLeft,
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: SmoothRectangleBorder(
              side: BorderSide(
                  color: isAutoFocus ? primaryColor : Colors.grey.shade400,
                  width: 1),
              borderRadius: SmoothBorderRadius(
                cornerRadius: radius,
                cornerSmoothing: 0.8,
              ),
            ),
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                setState(() {
                  isAutoFocus = true;
                  myFocusNode.canRequestFocus = true;
                });
              } else {
                setState(() {
                  isAutoFocus = false;
                  myFocusNode.canRequestFocus = false;
                });
              }
            },
            child: TextField(
              maxLines: (minLines) ? null : 1,
              controller: textEditingController,
              autofocus: false,
              focusNode: myFocusNode,
              textAlign: TextAlign.start,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                  fontFamily: Constant.fontsFamily,
                  color: fontBlack,
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize),
              decoration: InputDecoration(
                  prefixIcon: (withPrefix)
                      ? Padding(
                          padding: EdgeInsets.only(
                              right: Constant.getWidthPercentSize(2.5)),
                          child: getSvgImage(
                              imgName, Constant.getPercentSize(height, 40)),
                        )
                      : getSpace(0),
                  border: InputBorder.none,
                  isDense: true,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: s,
                  prefixIconConstraints:
                      const BoxConstraints(minHeight: 0, minWidth: 0),
                  hintStyle: TextStyle(
                      fontFamily: Constant.fontsFamily,
                      color: greyFont,
                      fontWeight: FontWeight.w400,
                      fontSize: fontSize)),
            ),
          ),
        );
      },
    );
  }
}
