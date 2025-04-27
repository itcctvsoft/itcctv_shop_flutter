// ignore: file_names

import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/ui/login/change_password_screen.dart';

import '../../constants/size_config.dart';
import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ForgotPasswordScreen();
  }
}

class _ForgotPasswordScreen extends State<ForgotPasswordScreen> {
  void backScreen() {
    Constant.backToFinish(context);
  }

  FocusNode focusNode = FocusNode();
  TextEditingController emailSignInController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeData = Theme.of(context);
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
                          'Quên mật khẩu',
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
                        "Vui lòng nhập email để khôi phục\nmật khẩu của bạn.",
                        AppColors.fontBlack,
                        TextAlign.center,
                        FontWeight.w400,
                        getEdtTextSize()),
                    getSpace(appBarPadding),
                    getLoginTextField(
                        emailSignInController, "Email", "email.svg",
                        iconColor: AppColors.greyFont),
                    getSpace(appBarPadding),
                    getButton(
                        AppColors.primaryColor, true, "Tiếp tục", Colors.white,
                        () {
                      Constant.sendToScreen(
                          const ChangePasswordScreen(), context);
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
      emailSignInController.dispose();
      focusNode.dispose();
      // ignore: empty_catches
    } catch (e) {}

    super.dispose();
  }
}
