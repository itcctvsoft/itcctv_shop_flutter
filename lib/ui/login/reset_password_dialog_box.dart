// ignore: file_names
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';

import '../../constants/color_data.dart';

class ResetPasswordDialogBox extends StatefulWidget {
  final Function? func;

  const ResetPasswordDialogBox({Key? key, this.func}) : super(key: key);

  @override
  _ResetPasswordDialogBoxState createState() => _ResetPasswordDialogBoxState();
}

class _ResetPasswordDialogBoxState extends State<ResetPasswordDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: AppColors.backgroundColor,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    double padding = getAppBarPadding();
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    final themeData = Theme.of(context);

    return Stack(
      children: <Widget>[
        // Background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeData.brightness == Brightness.dark
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : AppColors.primaryColor.withOpacity(0.05),
                  themeData.brightness == Brightness.dark
                      ? const Color(0xFF121212)
                      : Colors.white,
                ],
                stops: themeData.brightness == Brightness.dark
                    ? const [0.0, 0.35]
                    : const [0.0, 0.3],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Original content
        Container(
          padding:
              EdgeInsets.only(left: padding, right: padding, bottom: padding),
          margin: const EdgeInsets.only(top: 40),
          // margin: EdgeInsets.only(top: avatarRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                Constant.assetImagePath + "pass_reset.png",
                height: Constant.getHeightPercentSize(12),
                // color: primaryColor,
              ),
              SizedBox(
                height: Constant.getHeightPercentSize(5),
              ),
              getCustomText(
                  'Đã thay đổi mật khẩu',
                  AppColors.fontBlack,
                  1,
                  TextAlign.center,
                  FontWeight.w800,
                  Constant.getPercentSize(screenHeight, 3)),
              SizedBox(
                height: Constant.getPercentSize(screenHeight, 1.7),
              ),
              getCustomTextWithoutMaxLine(
                'Mật khẩu của bạn đã được\nthay đổi thành công!',
                AppColors.fontBlack,
                TextAlign.center,
                FontWeight.w500,
                Constant.getPercentSize(screenHeight, 2.4),
              ),
              // SizedBox(
              //   height: Constant.getPercentSize(screenHeight, 5),
              // ),
              getButton(AppColors.primaryColor, true, "Đồng ý", Colors.white,
                  () {
                Navigator.of(context).pop();
                widget.func!();
              }, FontWeight.w400,
                  EdgeInsets.symmetric(vertical: getAppBarPadding()))
            ],
          ),
        ),
      ],
    );
  }
}
