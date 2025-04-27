// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/data_file.dart';
import 'package:shoplite/constants/size_config.dart';

import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../constants/widget_utils.dart';
import '../../constants/color_data.dart';
import 'package:shoplite/widgets/chat_icon_badge.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FilterScreen();
  }
}

class _FilterScreen extends State<FilterScreen> {
  List<String> sortList = ["Sort by"];
  List<String> productTypeList = ["Product Type"];
  List<String> genderList = ["Gender"];

  String _selectedSort = "Sort by";
  String selectedProductType = "Product Type";
  String selectedGender = "Gender";
  List<String> getColorList = DataFile.colorList;
  ValueNotifier selectedSizeNotify = ValueNotifier(0);
  ValueNotifier selectedColorNotify = ValueNotifier(0);
  List<String> getSizeList = DataFile.sizeList;
  SfRangeValues selectedValue = const SfRangeValues(100.0, 200.0);

  backClick() {
    Constant.backToFinish(context);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double appbarPadding = getAppBarPadding();

    double circleSize = Constant.getPercentSize(screenHeight, 6.5);

    double toolbarHeight = Constant.getToolbarHeight(context);
    double size = Constant.getHeightPercentSize(6);
    double height = getEditHeight();
    double radius = Constant.getPercentSize(height, 20);
    double fontSize = Constant.getPercentSize(height, 30);
    double circleColorSize = Constant.getPercentSize(screenHeight, 4.8);

    Color dropdownColor = backgroundColor;
    TextStyle style = TextStyle(
        color: greyFont,
        fontSize: fontSize,
        fontFamily: Constant.fontsFamily,
        fontWeight: FontWeight.w400);

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
                PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Container(
                    height: 70 + MediaQuery.of(context).padding.top,
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
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.2),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                backClick();
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
                                "Filter",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.restore,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const ChatIconBadge(size: 26),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: appbarPadding, horizontal: appbarPadding),
                        child: SizedBox(
                          height: height,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constant.getWidthPercentSize(2.5)),
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: SmoothRectangleBorder(
                                side: BorderSide(
                                    color: Colors.grey.shade400, width: 1),
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: radius,
                                  cornerSmoothing: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                getSvgImage(
                                  "Sort.svg",
                                  getEdtIconSize(),
                                ),
                                getHorSpace(
                                    Constant.getPercentSize(screenWidth, 2.5)),
                                Expanded(
                                  child: DropdownButton<String>(
                                    onChanged: (value) {
                                      _selectedSort = value!;
                                    },
                                    dropdownColor: dropdownColor,
                                    isExpanded: true,
                                    itemHeight: null,
                                    isDense: true,
                                    underline: getSpace(0),
                                    icon:
                                        getSvgImage("dropdown_icon.svg", size),
                                    items: sortList
                                        .map((String dropDownStringItem) {
                                      return DropdownMenuItem<String>(
                                        value: dropDownStringItem,
                                        child: Row(
                                          children: [
                                            Text(
                                              dropDownStringItem,
                                              style: style,
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    value: _selectedSort,
                                  ),
                                  flex: 1,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      getTitles("Price Range"),
                      SfRangeSlider(
                          onChanged: (value) {
                            setState(() {
                              selectedValue = value;
                            });
                          },
                          activeColor: primaryColor,
                          inactiveColor: Colors.grey.shade400,
                          labelPlacement: LabelPlacement.onTicks,
                          min: 10.0,
                          tooltipShape: const SfRectangularTooltipShape(),
                          enableTooltip: true,
                          max: 500.0,
                          values: selectedValue),
                      getTitles("Color"),
                      SizedBox(
                        width: double.infinity,
                        height: (appbarPadding * 2) + circleColorSize,
                        child: ValueListenableBuilder(
                          builder: (context, value, child) {
                            return ListView.builder(
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  // bool isCurrentSelected = (selectedColorNotify.value == index);
                                  return InkWell(
                                    onTap: () {
                                      // selectedColorNotify.value = index;
                                    },
                                    child: Container(
                                      width: circleColorSize,
                                      height: circleColorSize,
                                      margin: EdgeInsets.only(
                                          left: (index == 0)
                                              ? appbarPadding
                                              : (appbarPadding / 2),
                                          right: appbarPadding / 2,
                                          top: appbarPadding,
                                          bottom: appbarPadding),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: shadowColor
                                                    .withOpacity(0.060),
                                                // spreadRadius: 0.7,
                                                // blurRadius: 2
                                                spreadRadius: 1.3,
                                                blurRadius: 10,
                                                offset: const Offset(0, 5))
                                          ]),
                                      child: Image.asset(
                                          Constant.assetImagePath +
                                              getColorList[index]),
                                    ),
                                  );
                                },
                                itemCount: getColorList.length);
                          },
                          valueListenable: selectedSizeNotify,
                        ),
                      ),
                      getTitles("Size"),
                      SizedBox(
                        width: double.infinity,
                        height: (appbarPadding * 2) + circleSize,
                        child: ValueListenableBuilder(
                          builder: (context, value, child) {
                            return ListView.builder(
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  bool isCurrentSelected =
                                      (selectedSizeNotify.value == index);
                                  return InkWell(
                                    onTap: () {
                                      selectedSizeNotify.value = index;
                                    },
                                    child: Container(
                                      width: circleSize,
                                      height: circleSize,
                                      margin: EdgeInsets.only(
                                          left: (index == 0)
                                              ? appbarPadding
                                              : (appbarPadding / 2),
                                          right: appbarPadding / 2,
                                          top: appbarPadding,
                                          bottom: appbarPadding),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (isCurrentSelected)
                                              ? primaryColor
                                              : Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                                color: (isCurrentSelected)
                                                    ? primaryColor
                                                        .withOpacity(0.4)
                                                    : shadowColor
                                                        .withOpacity(0.060),
                                                // spreadRadius: 0.7,
                                                // blurRadius: 2
                                                spreadRadius: 1.3,
                                                blurRadius: 10,
                                                offset: const Offset(0, 5))
                                          ]),
                                      child: Center(
                                        child: getCustomText(
                                            getSizeList[index],
                                            (isCurrentSelected)
                                                ? Colors.white
                                                : fontBlack,
                                            1,
                                            TextAlign.center,
                                            FontWeight.w600,
                                            Constant.getPercentSize(
                                                circleSize, 28)),
                                      ),
                                    ),
                                  );
                                },
                                itemCount: getSizeList.length);
                          },
                          valueListenable: selectedSizeNotify,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: appbarPadding, horizontal: appbarPadding),
                        child: SizedBox(
                          height: height,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constant.getWidthPercentSize(2.5)),
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: SmoothRectangleBorder(
                                side: BorderSide(
                                    color: Colors.grey.shade400, width: 1),
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: radius,
                                  cornerSmoothing: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Container(width: 50,color: Colors.yellow,),
                                getSvgImage(
                                  "product_type_icon.svg",
                                  getEdtIconSize(),
                                ),
                                getHorSpace(
                                    Constant.getPercentSize(screenWidth, 2.5)),
                                Expanded(
                                  child: DropdownButton<String>(
                                    onChanged: (value) {
                                      selectedProductType = value!;
                                    },
                                    dropdownColor: dropdownColor,
                                    isExpanded: true,
                                    itemHeight: null,
                                    isDense: true,
                                    underline: getSpace(0),
                                    icon: getSvgImage("ArrowRight.svg", size),
                                    items: productTypeList
                                        .map((String dropDownStringItem) {
                                      return DropdownMenuItem<String>(
                                        value: dropDownStringItem,
                                        child: Row(
                                          children: [
                                            Text(
                                              dropDownStringItem,
                                              style: style,
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    value: selectedProductType,
                                  ),
                                  flex: 1,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: appbarPadding, horizontal: appbarPadding),
                        child: SizedBox(
                          height: height,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constant.getWidthPercentSize(2.5)),
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: SmoothRectangleBorder(
                                side: BorderSide(
                                    color: Colors.grey.shade400, width: 1),
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: radius,
                                  cornerSmoothing: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                getSvgImage(
                                  "User.svg",
                                  getEdtIconSize(),
                                ),
                                getHorSpace(
                                    Constant.getPercentSize(screenWidth, 2.5)),
                                Expanded(
                                  child: DropdownButton<String>(
                                    onChanged: (value) {
                                      selectedGender = value!;
                                    },
                                    dropdownColor: dropdownColor,
                                    isExpanded: true,
                                    itemHeight: null,
                                    isDense: true,
                                    underline: getSpace(0),
                                    icon: getSvgImage("ArrowRight.svg", size),
                                    items: genderList
                                        .map((String dropDownStringItem) {
                                      return DropdownMenuItem<String>(
                                        value: dropDownStringItem,
                                        child: Row(
                                          children: [
                                            Text(
                                              dropDownStringItem,
                                              style: style,
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    value: selectedGender,
                                  ),
                                  flex: 1,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  flex: 1,
                ),
                getButton(primaryColor, true, "Apply", Colors.white, () {
                  backClick();
                }, FontWeight.w700, EdgeInsets.all(appbarPadding))
              ],
            ),
          ),
        ),
        onWillPop: () async {
          backClick();
          return false;
        });
  }

  Widget getTitles(String title) {
    double appbarHeight = getAppBarPadding();
    double height = getEditHeight();
    double fontSize = Constant.getPercentSize(height, 30);
    return Padding(
      padding: EdgeInsets.only(
          left: appbarHeight,
          right: appbarHeight,
          top: appbarHeight,
          bottom: appbarHeight / 2),
      child: getCustomText(
          title, fontBlack, 1, TextAlign.start, FontWeight.bold, fontSize),
    );
  }
}
