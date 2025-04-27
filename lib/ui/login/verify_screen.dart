import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';

import '../../constants/pref_data.dart';
import '../../constants/size_config.dart';
import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';
import '../../constants/flutter_pin_code_fields.dart';
import '../home/home_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VerifyScreen();
  }
}

class _VerifyScreen extends State<VerifyScreen> {
  void backScreen() {
    Constant.backToFinish(context);
  }

  TextEditingController newTextEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeData = Theme.of(context);
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appBarPadding = getAppBarPadding();

    return WillPopScope(
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              height: 65 + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDarkColor,
                    AppColors.primaryColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          backScreen();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Xác minh mã',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
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
                  ),
                ),
              ),
              // Original content
              getBackgroundWidget(Container(
                padding: EdgeInsets.all(appBarPadding),
                child: Column(
                  children: [
                    getCustomTextWithoutMaxLine(
                        "Vui lòng nhập mã xác minh mà chúng tôi\nđã gửi đến email của bạn.",
                        AppColors.fontBlack,
                        TextAlign.center,
                        FontWeight.w400,
                        getEdtTextSize()),
                    getSpace(appBarPadding / 2),
                    PinCodeFields(
                      length: 4,
                      fieldBorderStyle: FieldBorderStyle.square,
                      controller: newTextEditingController,
                      activeBorderColor: AppColors.primaryColor,
                      padding: EdgeInsets.zero,
                      focusNode: focusNode,
                      textStyle: TextStyle(
                          color: AppColors.fontBlack,
                          fontSize: Constant.getPercentSize(screenWidth, 5.5),
                          fontFamily: Constant.fontsFamily,
                          fontWeight: FontWeight.w500),
                      margin: EdgeInsets.all(
                          Constant.getPercentSize(appBarPadding, 70)),
                      borderWidth: 0.5,
                      borderColor: AppColors.greyFont,
                      borderRadius: BorderRadius.all(Radius.circular(
                          Constant.getPercentSize(screenWidth, 3))),
                      fieldHeight: Constant.getPercentSize(screenWidth, 14),
                      onComplete: (result) {
                        // Your logic with code
                      },
                    ),
                    getSpace(appBarPadding),
                    getButton(
                        AppColors.primaryColor, true, "Xác minh", Colors.white,
                        () {
                      PrefData.setLogIn(true);

                      Constant.sendToScreen(HomeScreen(), context);
                    }, FontWeight.w600,
                        EdgeInsets.symmetric(vertical: appBarPadding))
                  ],
                ),
              )),
            ],
          ),
        ),
        onWillPop: () async {
          backScreen();
          return false;
        });
  }

  @override
  void dispose() {
    try {
      newTextEditingController.dispose();
      focusNode.dispose();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    super.dispose();
  }
}
