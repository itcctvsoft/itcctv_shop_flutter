// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/order/order_history_screen.dart';


import '../../constants/color_data.dart';

class ThankYouDialog extends StatefulWidget {
  final BuildContext context;
  final ValueChanged<int> onChanged;

  @override
  _ThankYouDialog createState() {
    return _ThankYouDialog();
  }

  const ThankYouDialog(this.context, this.onChanged, {Key? key})
      : super(key: key);
}

class _ThankYouDialog extends State<ThankYouDialog> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double height = Constant.getHeightPercentSize(70);
    double radius = Constant.getPercentSize(height, 2);
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0.0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: dialogContent(context, setState),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  dialogContent(BuildContext context, var setState) {
    double height = Constant.getHeightPercentSize(45);
    double width = Constant.getWidthPercentSize(80);
    double radius = Constant.getPercentSize(height, 4);
    double imgSize = Constant.getPercentSize(height, 32);
    return Container(
      height: height,
      width: width,
      padding: EdgeInsets.zero,
      // padding: EdgeInsets.all((radius)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              getSvgImage("thankyou.svg", imgSize),
              // Image.asset(
              //   Constant.assetImagePath + "Grourep.png",
              //   height: imgSize,
              //   width: imgSize,
              // ),
              SizedBox(
                height: Constant.getPercentSize(
                  height,
                  4,
                ),
              ),
              getCustomText(
                'Order Placed',
                fontBlack,
                1,
                TextAlign.center,
                FontWeight.bold,
                Constant.getPercentSize(width, 7),
              ),

              SizedBox(
                height: Constant.getPercentSize(
                  height,
                  3,
                ),
              ),

              getCustomText(
                'Đơn hàng của bạn đã được đặt thành công',
                fontBlack,
                2,
                TextAlign.center,
                FontWeight.w400,
                Constant.getPercentSize(width, 5),
              ),

              SizedBox(
                height: Constant.getPercentSize(
                  height,
                  6,
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Constant.getPercentSize(width, 5)),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(),
                                ));
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                                right: Constant.getWidthPercentSize(3)),
                            height: Constant.getHeightPercentSize(7),
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: SmoothRectangleBorder(
                                side: BorderSide(color: primaryColor, width: 2),
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius:
                                      Constant.getHeightPercentSize(1.8),
                                  cornerSmoothing: 0.8,
                                ),
                              ),
                            ),
                            child: Center(
                              child: getCustomText(
                                  "Ok",
                                  primaryColor,
                                  1,
                                  TextAlign.center,
                                  FontWeight.w600,
                                  Constant.getHeightPercentSize(2)),
                            ),
                          )),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Constant.sendToScreen(
                              const OrderHistoryScreen(), context);
                          // Navigator.pushReplacement(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => TrackOrderPage(),
                          //     ));
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                              left: Constant.getWidthPercentSize(3)),
                          height: Constant.getHeightPercentSize(7),
                          decoration: ShapeDecoration(
                            color: primaryColor,
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius:
                                    Constant.getHeightPercentSize(1.8),
                                cornerSmoothing: 0.8,
                              ),
                            ),
                          ),
                          child: Center(
                              child: getCustomText(
                                  "Theo dõi đơn hàng",
                                  Colors.white,
                                  1,
                                  TextAlign.center,
                                  FontWeight.w600,
                                  Constant.getHeightPercentSize(2))),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          )),
        ],
      ),
    );
  }
}
