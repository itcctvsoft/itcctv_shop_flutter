// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/data_file.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/home/home_screen.dart';

class ProductDetail extends StatefulWidget {
  const ProductDetail({Key? key, required product}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProductDetail();
  }
}

class _ProductDetail extends State<ProductDetail> {
  ValueNotifier quantityNotify = ValueNotifier(1);
  ValueNotifier selectedSizeNotify = ValueNotifier(0);
  ValueNotifier selectedColorNotify = ValueNotifier(0);

  Widget getPaddingData(Widget widget) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getAppBarPadding()),
      child: widget,
    );
  }

  List<String> getSizeList = DataFile.sizeList;
  List<String> getColorList = DataFile.colorList;

  finishScreen() {
    Constant.backToFinish(context);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double imgSize = Constant.getPercentSize(screenHeight, 50);
    double appBarPadding = getAppBarPadding();
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    Widget verSpace = getSpace(Constant.getPercentSize(screenHeight, 0.8));
    double iconSize = Constant.getPercentSize(screenHeight, 5.2);
    double circleColorSize = Constant.getPercentSize(screenHeight, 4.5);
    double circleSize = Constant.getPercentSize(screenHeight, 6.8);
    double topView = Constant.getPercentSize(screenHeight, 8.3);
    return WillPopScope(
        child: Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                shrinkWrap: true,
                primary: true,
                slivers: <Widget>[
                  SliverAppBar(
                    backgroundColor: primaryColor,
                    expandedHeight: imgSize,
                    toolbarHeight: Constant.getHeightPercentSize(4) + 7,
                    // pinned: true,
                    leadingWidth:
                        Constant.getHeightPercentSize(4) + appBarPadding * 2,
                    // toolbarHeight: Constant.getPercentSize(Constant.getToolbarHeight(context), 50),
                    leading: Padding(
                        padding: EdgeInsets.only(
                            left: appBarPadding, right: appBarPadding, top: 7),
                        child: getLeadingIcon(context, () {
                          finishScreen();
                        })),
                    actions: [
                      Padding(
                          padding:
                              EdgeInsets.only(right: appBarPadding, top: 7),
                          child: getSvgImage(
                            "fav_fill.svg",
                            Constant.getHeightPercentSize(3.6),
                          ))
                    ],

                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.asset(
                        Constant.assetImagePath + "order1.png",
                        // Constant.assetImagePath + "intro3.png",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SliverList(
                      delegate: SliverChildListDelegate([
                    ListView(
                      padding: EdgeInsets.only(top: appBarPadding),
                      primary: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        getPaddingData(getCustomText(
                            "Stylish Women",
                            fontBlack,
                            1,
                            TextAlign.start,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.1))),
                        verSpace,
                        getPaddingData(getCustomTextWithoutMaxLine(
                            "Kid's Girl Shrug",
                            fontBlack,
                            TextAlign.start,
                            FontWeight.bold,
                            Constant.getPercentSize(screenHeight, 2.6))),
                        verSpace,
                        getPaddingData(
                          getCustomTextWithoutMaxLine(
                              "\$22.0",
                              fontBlack,
                              TextAlign.start,
                              FontWeight.w900,
                              Constant.getPercentSize(screenHeight, 2.4)),
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 0.8)),
                        getPaddingData(
                          Row(
                            children: [
                              getSvgImage("star.svg",
                                  Constant.getPercentSize(iconSize, 65)),
                              getHorSpace(
                                  Constant.getPercentSize(screenWidth, 2.3)),
                              getCustomTextWithoutMaxLine(
                                  "4.2",
                                  fontBlack,
                                  TextAlign.start,
                                  FontWeight.bold,
                                  Constant.getPercentSize(screenHeight, 2.2)),
                              Expanded(
                                child: getCustomTextWithoutMaxLine(
                                    " (425 Reviews)",
                                    greyFont,
                                    TextAlign.start,
                                    FontWeight.w400,
                                    Constant.getPercentSize(screenHeight, 2.1)),
                                flex: 1,
                              ),
                              Container(
                                decoration: ShapeDecoration(
                                    shape: SmoothRectangleBorder(
                                        borderRadius: SmoothBorderRadius(
                                            cornerRadius:
                                                Constant.getPercentSize(
                                                    iconSize, 15),
                                            cornerSmoothing: 0.5),
                                        side: BorderSide(
                                            color: primaryColor, width: 1.2))),
                                width: iconSize,
                                height: iconSize,
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    size: Constant.getPercentSize(iconSize, 50),
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: Constant.getPercentSize(
                                        screenWidth, 4)),
                                child: ValueListenableBuilder(
                                  valueListenable: quantityNotify,
                                  builder: (context, value, child) {
                                    return getCustomTextWithoutMaxLine(
                                        "${quantityNotify.value}",
                                        fontBlack,
                                        TextAlign.start,
                                        FontWeight.w600,
                                        Constant.getPercentSize(
                                            screenHeight, 2.6));
                                  },
                                ),
                              ),
                              Container(
                                decoration: ShapeDecoration(
                                    shape: SmoothRectangleBorder(
                                        borderRadius: SmoothBorderRadius(
                                            cornerRadius:
                                                Constant.getPercentSize(
                                                    iconSize, 15),
                                            cornerSmoothing: 0.5),
                                        side: BorderSide(
                                            color: primaryColor, width: 1.2))),
                                width: iconSize,
                                height: iconSize,
                                child: Center(
                                  child: Icon(
                                    Icons.remove,
                                    size: Constant.getPercentSize(iconSize, 50),
                                    color: primaryColor,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 1.9)),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade500,
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 2)),
                        getPaddingData(getCustomTextWithoutMaxLine(
                            "Color",
                            fontBlack,
                            TextAlign.start,
                            FontWeight.bold,
                            Constant.getPercentSize(screenHeight, 2.4))),
                        // verSpace,
                        SizedBox(
                          width: double.infinity,
                          height: (appBarPadding * 2) + circleColorSize,
                          child: ValueListenableBuilder(
                            builder: (context, value, child) {
                              return ListView.builder(
                                  primary: false,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () {},
                                      child: Container(
                                        width: circleColorSize,
                                        height: circleColorSize,
                                        margin: EdgeInsets.only(
                                            left: (index == 0)
                                                ? appBarPadding
                                                : (appBarPadding / 2),
                                            right: appBarPadding / 2,
                                            top: appBarPadding,
                                            bottom: appBarPadding),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: shadowColor
                                                      .withOpacity(0.060),
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
                            valueListenable: selectedColorNotify,
                          ),
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 1.7)),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade500,
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 2)),
                        getPaddingData(getCustomTextWithoutMaxLine(
                            "Size",
                            fontBlack,
                            TextAlign.start,
                            FontWeight.bold,
                            Constant.getPercentSize(screenHeight, 2.4))),
                        // verSpace,
                        SizedBox(
                          width: double.infinity,
                          height: (appBarPadding * 2) + circleSize,
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
                                                ? appBarPadding
                                                : (appBarPadding / 2),
                                            right: appBarPadding / 2,
                                            top: appBarPadding,
                                            bottom: appBarPadding),
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
                        getSpace(Constant.getPercentSize(screenHeight, 1.7)),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade500,
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 2)),
                        getPaddingData(getCustomTextWithoutMaxLine(
                            "Description",
                            fontBlack,
                            TextAlign.start,
                            FontWeight.bold,
                            Constant.getPercentSize(screenHeight, 2.4))),
                        verSpace,
                        getPaddingData(getCustomTextWithoutMaxLine(
                            "Everything that is considered fashion is available and popularized by the passion system.",
                            fontBlack,
                            TextAlign.start,
                            FontWeight.w400,
                            Constant.getPercentSize(screenHeight, 2.3))),
                        verSpace,
                        getPaddingData(Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Image.asset(
                                Constant.assetImagePath + "point.png",
                                width:
                                    Constant.getPercentSize(screenHeight, 1.5),
                                height:
                                    Constant.getPercentSize(screenHeight, 1.5),
                              ),
                            ),
                            getHorSpace(
                                Constant.getPercentSize(screenWidth, 2)),
                            // getCustomTextWithoutMaxLine(
                            //     "⚈ ",
                            //     primaryColor,
                            //     TextAlign.start,
                            //     FontWeight.w400,
                            //     Constant.getPercentSize(screenHeight, 2.3)),
                            Expanded(
                              child: getCustomTextWithoutMaxLine(
                                  "Fashion goods by designers, manufacturers.",
                                  fontBlack,
                                  TextAlign.start,
                                  FontWeight.w400,
                                  Constant.getPercentSize(screenHeight, 2.3),
                                  txtHeight: 1.2),
                              flex: 1,
                            )
                          ],
                        )),
                        verSpace,
                        getPaddingData(Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Image.asset(
                                Constant.assetImagePath + "point.png",
                                width:
                                    Constant.getPercentSize(screenHeight, 1.5),
                                height:
                                    Constant.getPercentSize(screenHeight, 1.5),
                              ),
                            ),
                            getHorSpace(
                                Constant.getPercentSize(screenWidth, 2)),
                            // getCustomTextWithoutMaxLine(
                            //     "⚈ ",
                            //     primaryColor,
                            //     TextAlign.start,
                            //     FontWeight.w400,
                            //     Constant.getPercentSize(screenHeight, 2.3)),
                            Expanded(
                              child: getCustomTextWithoutMaxLine(
                                  "Various forms of advertising and promotion.",
                                  fontBlack,
                                  TextAlign.start,
                                  FontWeight.w400,
                                  Constant.getPercentSize(screenHeight, 2.3),
                                  txtHeight: 1.2),
                              flex: 1,
                            )
                          ],
                        )),
                        getSpace(Constant.getPercentSize(screenHeight, 2)),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade500,
                        ),
                        getSpace(Constant.getPercentSize(screenHeight, 2)),
                        getPaddingData(Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            getCustomTextWithoutMaxLine(
                                "Reviews",
                                fontBlack,
                                TextAlign.start,
                                FontWeight.bold,
                                Constant.getPercentSize(screenHeight, 2.4)),
                            getCustomTextWithoutMaxLine(
                                "View all",
                                primaryColor,
                                TextAlign.start,
                                FontWeight.w400,
                                Constant.getPercentSize(screenHeight, 2.3)),
                          ],
                        )),
                        SizedBox(
                          width: double.infinity,
                          child: ListView.builder(
                            itemBuilder: (context, index) {
                              double profileSize = topView;
                              double ratingSize =
                                  Constant.getPercentSize(topView, 30);
                              return Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(
                                    left: appBarPadding,
                                    right: appBarPadding,
                                    top: (index == 0) ? 0 : appBarPadding),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: topView,
                                      child: Row(
                                        children: [
                                          Container(
                                            height: profileSize,
                                            width: profileSize,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                    image: AssetImage(Constant
                                                            .assetImagePath +
                                                        "profile1.png"),
                                                    fit: BoxFit.cover)),
                                            // child: ClipRRect(
                                            //   borderRadius: ,
                                            // ),
                                          ),
                                          getHorSpace(Constant.getPercentSize(
                                              screenWidth, 3)),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Expanded(child: Container(),flex: 1,),
                                                Padding(
                                                  child: getCustomText(
                                                      "Jenny Wilson",
                                                      fontBlack,
                                                      1,
                                                      TextAlign.start,
                                                      FontWeight.w700,
                                                      Constant.getPercentSize(
                                                          topView, 26)),
                                                  padding: EdgeInsets.only(
                                                      left: Constant
                                                          .getPercentSize(
                                                              screenWidth,
                                                              0.4)),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    RatingBar(
                                                      initialRating: 3.5,
                                                      direction:
                                                          Axis.horizontal,
                                                      allowHalfRating: true,
                                                      itemCount: 5,
                                                      itemSize: ratingSize,
                                                      ignoreGestures: true,
                                                      ratingWidget:
                                                          RatingWidget(
                                                        full: getSvgImage(
                                                            "star.svg",
                                                            ratingSize),
                                                        half: getSvgImage(
                                                            "unfav_star.svg",
                                                            ratingSize),
                                                        empty: getSvgImage(
                                                            "unfav_star.svg",
                                                            ratingSize),
                                                      ),
                                                      itemPadding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: Constant
                                                                  .getPercentSize(
                                                                      screenWidth,
                                                                      0.4)),
                                                      onRatingUpdate:
                                                          (rating) {},
                                                    ),
                                                    getHorSpace(
                                                        Constant.getPercentSize(
                                                            screenWidth, 1.8)),
                                                    Expanded(
                                                      child: getCustomText(
                                                          "3.5",
                                                          fontBlack,
                                                          1,
                                                          TextAlign.start,
                                                          FontWeight.w500,
                                                          Constant
                                                              .getPercentSize(
                                                                  topView, 26)),
                                                      flex: 1,
                                                    )
                                                  ],
                                                )
                                                // Expanded(child: Container(),flex: 1,),
                                                ,
                                                getSpace(
                                                    Constant.getPercentSize(
                                                        topView, 1.5))
                                              ],
                                            ),
                                            flex: 1,
                                          ),
                                          getCustomText(
                                              "1 day ago",
                                              Colors.grey,
                                              1,
                                              TextAlign.start,
                                              FontWeight.w500,
                                              Constant.getPercentSize(
                                                  topView, 26))
                                        ],
                                      ),
                                    ),
                                    getSpace(appBarPadding),
                                    getCustomTextWithoutMaxLine(
                                        "Fashion is inherently a social phenomenon. A person cannot have a fashion by oneself, but for something to be defined as fashion",
                                        fontBlack,
                                        TextAlign.start,
                                        FontWeight.w400,
                                        Constant.getPercentSize(topView, 26)),
                                    getSpace(appBarPadding),
                                    Divider(
                                      color: Colors.grey.shade400,
                                      height: 1,
                                    )
                                  ],
                                ),
                              );
                            },
                            itemCount: 3,
                            primary: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(appBarPadding),
                          height: getEditHeight(),
                          color: Colors.transparent,
                        )
                        // Padding(
                        //   padding:
                        //       EdgeInsets.symmetric(vertical: appBarPadding),
                        //   child: SizedBox(
                        //     height: getEditHeight(),
                        //   ),
                        // )
                      ],
                    )
                  ]))
                  // SliverFillRemaining(
                  //   // hasScrollBody: false,
                  //   child: ListView(
                  //     padding: EdgeInsets.only(top: appBarPadding),
                  //     primary: false,
                  //     shrinkWrap: true,
                  //     physics: const NeverScrollableScrollPhysics(),
                  //     children: [
                  //       getPaddingData(getCustomText(
                  //           "Stylish Women",
                  //           fontBlack,
                  //           1,
                  //           TextAlign.start,
                  //           FontWeight.w400,
                  //           Constant.getPercentSize(screenHeight, 2.3))),
                  //       verSpace,
                  //       getPaddingData(getCustomTextWithoutMaxLine(
                  //           "Kid's Girl Shrug",
                  //           fontBlack,
                  //           TextAlign.start,
                  //           FontWeight.bold,
                  //           Constant.getPercentSize(screenHeight, 3.2))),
                  //       verSpace,
                  //       getPaddingData(
                  //         getCustomTextWithoutMaxLine(
                  //             "\$22.0",
                  //             fontBlack,
                  //             TextAlign.start,
                  //             FontWeight.w900,
                  //             Constant.getPercentSize(screenHeight, 2.6)),
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 0.8)),
                  //       getPaddingData(
                  //         Row(
                  //           children: [
                  //             getSvgImage("star.svg",
                  //                 Constant.getPercentSize(iconSize, 65)),
                  //             getHorSpace(
                  //                 Constant.getPercentSize(screenWidth, 2.3)),
                  //             getCustomTextWithoutMaxLine(
                  //                 "4.2",
                  //                 fontBlack,
                  //                 TextAlign.start,
                  //                 FontWeight.bold,
                  //                 Constant.getPercentSize(screenHeight, 2.4)),
                  //             Expanded(
                  //               child: getCustomTextWithoutMaxLine(
                  //                   " (425 Reviews)",
                  //                   greyFont,
                  //                   TextAlign.start,
                  //                   FontWeight.w400,
                  //                   Constant.getPercentSize(screenHeight, 2.3)),
                  //               flex: 1,
                  //             ),
                  //             IconButton(
                  //                 onPressed: () {},
                  //                 icon: Container(
                  //                   decoration: ShapeDecoration(
                  //                       shape: SmoothRectangleBorder(
                  //                           borderRadius: SmoothBorderRadius(
                  //                               cornerRadius:
                  //                                   Constant.getPercentSize(
                  //                                       iconSize, 15),
                  //                               cornerSmoothing: 0.5),
                  //                           side: BorderSide(
                  //                               color: primaryColor,
                  //                               width: 1.2))),
                  //                   width: iconSize,
                  //                   height: iconSize,
                  //                   child: Icon(
                  //                     Icons.add,
                  //                     size:
                  //                         Constant.getPercentSize(iconSize, 50),
                  //                     color: primaryColor,
                  //                   ),
                  //                 )),
                  //             Padding(
                  //               padding: EdgeInsets.symmetric(
                  //                   horizontal: Constant.getPercentSize(
                  //                       screenWidth, 1.7)),
                  //               child: ValueListenableBuilder(
                  //                 valueListenable: quantityNotify,
                  //                 builder: (context, value, child) {
                  //                   return getCustomTextWithoutMaxLine(
                  //                       "${quantityNotify.value}",
                  //                       fontBlack,
                  //                       TextAlign.start,
                  //                       FontWeight.w600,
                  //                       Constant.getPercentSize(
                  //                           screenHeight, 2.8));
                  //                 },
                  //               ),
                  //             ),
                  //             IconButton(
                  //                 onPressed: () {},
                  //                 icon: Container(
                  //                   decoration: ShapeDecoration(
                  //                       shape: SmoothRectangleBorder(
                  //                           borderRadius: SmoothBorderRadius(
                  //                               cornerRadius:
                  //                                   Constant.getPercentSize(
                  //                                       iconSize, 15),
                  //                               cornerSmoothing: 0.5),
                  //                           side: BorderSide(
                  //                               color: primaryColor,
                  //                               width: 1.2))),
                  //                   width: iconSize,
                  //                   height: iconSize,
                  //                   child: Icon(
                  //                     Icons.remove,
                  //                     size:
                  //                         Constant.getPercentSize(iconSize, 50),
                  //                     color: primaryColor,
                  //                   ),
                  //                 )),
                  //           ],
                  //         ),
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 1.9)),
                  //       Divider(
                  //         height: 1,
                  //         color: Colors.grey.shade500,
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 2)),
                  //       getPaddingData(getCustomTextWithoutMaxLine(
                  //           "Color",
                  //           fontBlack,
                  //           TextAlign.start,
                  //           FontWeight.bold,
                  //           Constant.getPercentSize(screenHeight, 2.6))),
                  //       // verSpace,
                  //       Container(
                  //         width: double.infinity,
                  //         height: (appBarPadding * 2) + circleColorSize,
                  //         child: ValueListenableBuilder(
                  //           builder: (context, value, child) {
                  //             return ListView.builder(
                  //                 primary: false,
                  //                 shrinkWrap: true,
                  //                 scrollDirection: Axis.horizontal,
                  //                 itemBuilder: (context, index) {
                  //                   bool isCurrentSelected =
                  //                       (selectedColorNotify.value == index);
                  //                   return InkWell(
                  //                     onTap: () {
                  //                       // selectedColorNotify.value = index;
                  //                     },
                  //                     child: Container(
                  //                       width: circleColorSize,
                  //                       height: circleColorSize,
                  //                       margin: EdgeInsets.only(
                  //                           left: (index == 0)
                  //                               ? appBarPadding
                  //                               : (appBarPadding / 2),
                  //                           right: appBarPadding / 2,
                  //                           top: appBarPadding,
                  //                           bottom: appBarPadding),
                  //                       decoration: BoxDecoration(
                  //                           shape: BoxShape.circle,
                  //                           boxShadow: [
                  //                             BoxShadow(
                  //                                 color: shadowColor
                  //                                     .withOpacity(0.060),
                  //                                 // spreadRadius: 0.7,
                  //                                 // blurRadius: 2
                  //                                 spreadRadius: 1.3,
                  //                                 blurRadius: 10,
                  //                                 offset: Offset(0, 5))
                  //                           ]),
                  //                       child: Image.asset(
                  //                           Constant.assetImagePath +
                  //                               getColorList[index]),
                  //                     ),
                  //                   );
                  //                 },
                  //                 itemCount: getColorList.length);
                  //           },
                  //           valueListenable: selectedSizeNotify,
                  //         ),
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 1.7)),
                  //       Divider(
                  //         height: 1,
                  //         color: Colors.grey.shade500,
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 2)),
                  //       getPaddingData(getCustomTextWithoutMaxLine(
                  //           "Size",
                  //           fontBlack,
                  //           TextAlign.start,
                  //           FontWeight.bold,
                  //           Constant.getPercentSize(screenHeight, 2.6))),
                  //       // verSpace,
                  //       Container(
                  //         width: double.infinity,
                  //         height: (appBarPadding * 2) + circleSize,
                  //         child: ValueListenableBuilder(
                  //           builder: (context, value, child) {
                  //             return ListView.builder(
                  //                 primary: false,
                  //                 shrinkWrap: true,
                  //                 scrollDirection: Axis.horizontal,
                  //                 itemBuilder: (context, index) {
                  //                   bool isCurrentSelected =
                  //                       (selectedSizeNotify.value == index);
                  //                   return InkWell(
                  //                     onTap: () {
                  //                       selectedSizeNotify.value = index;
                  //                     },
                  //                     child: Container(
                  //                       width: circleSize,
                  //                       height: circleSize,
                  //                       margin: EdgeInsets.only(
                  //                           left: (index == 0)
                  //                               ? appBarPadding
                  //                               : (appBarPadding / 2),
                  //                           right: appBarPadding / 2,
                  //                           top: appBarPadding,
                  //                           bottom: appBarPadding),
                  //                       decoration: BoxDecoration(
                  //                           shape: BoxShape.circle,
                  //                           color: (isCurrentSelected)
                  //                               ? primaryColor
                  //                               : Colors.white,
                  //                           boxShadow: [
                  //                             BoxShadow(
                  //                                 color: (isCurrentSelected)
                  //                                     ? primaryColor
                  //                                         .withOpacity(0.4)
                  //                                     : shadowColor
                  //                                         .withOpacity(0.060),
                  //                                 // spreadRadius: 0.7,
                  //                                 // blurRadius: 2
                  //                                 spreadRadius: 1.3,
                  //                                 blurRadius: 10,
                  //                                 offset: Offset(0, 5))
                  //                           ]),
                  //                       child: Center(
                  //                         child: getCustomText(
                  //                             getSizeList[index],
                  //                             (isCurrentSelected)
                  //                                 ? Colors.white
                  //                                 : fontBlack,
                  //                             1,
                  //                             TextAlign.center,
                  //                             FontWeight.w600,
                  //                             Constant.getPercentSize(
                  //                                 circleSize, 28)),
                  //                       ),
                  //                     ),
                  //                   );
                  //                 },
                  //                 itemCount: getSizeList.length);
                  //           },
                  //           valueListenable: selectedSizeNotify,
                  //         ),
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 1.7)),
                  //       Divider(
                  //         height: 1,
                  //         color: Colors.grey.shade500,
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 2)),
                  //       getPaddingData(getCustomTextWithoutMaxLine(
                  //           "Description",
                  //           fontBlack,
                  //           TextAlign.start,
                  //           FontWeight.bold,
                  //           Constant.getPercentSize(screenHeight, 2.6))),
                  //       verSpace,
                  //       getPaddingData(getCustomTextWithoutMaxLine(
                  //           "Everything that is considered fashion is available and popularized by the passion system.",
                  //           fontBlack,
                  //           TextAlign.start,
                  //           FontWeight.w400,
                  //           Constant.getPercentSize(screenHeight, 2.6))),
                  //       verSpace,
                  //       getPaddingData(Row(
                  //         children: [
                  //           getCustomTextWithoutMaxLine(
                  //               "⚈ ",
                  //               primaryColor,
                  //               TextAlign.start,
                  //               FontWeight.w400,
                  //               Constant.getPercentSize(screenHeight, 2.3)),
                  //           Expanded(
                  //             child: getCustomTextWithoutMaxLine(
                  //                 "Fashion goods by designers, manufacturers.",
                  //                 fontBlack,
                  //                 TextAlign.start,
                  //                 FontWeight.w400,
                  //                 Constant.getPercentSize(screenHeight, 2.63)),
                  //             flex: 1,
                  //           )
                  //         ],
                  //       )),
                  //       verSpace,
                  //       getPaddingData(Row(
                  //         children: [
                  //           getCustomTextWithoutMaxLine(
                  //               "⚈ ",
                  //               primaryColor,
                  //               TextAlign.start,
                  //               FontWeight.w400,
                  //               Constant.getPercentSize(screenHeight, 2.3)),
                  //           Expanded(
                  //             child: getCustomTextWithoutMaxLine(
                  //                 "Various forms of advertising and promotion.",
                  //                 fontBlack,
                  //                 TextAlign.start,
                  //                 FontWeight.w400,
                  //                 Constant.getPercentSize(screenHeight, 2.63)),
                  //             flex: 1,
                  //           )
                  //         ],
                  //       )),
                  //       getSpace(Constant.getPercentSize(screenHeight, 2)),
                  //       Divider(
                  //         height: 1,
                  //         color: Colors.grey.shade500,
                  //       ),
                  //       getSpace(Constant.getPercentSize(screenHeight, 2)),
                  //       getPaddingData(Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           getCustomTextWithoutMaxLine(
                  //               "Description",
                  //               fontBlack,
                  //               TextAlign.start,
                  //               FontWeight.bold,
                  //               Constant.getPercentSize(screenHeight, 2.6)),
                  //           getCustomTextWithoutMaxLine(
                  //               "View all",
                  //               primaryColor,
                  //               TextAlign.start,
                  //               FontWeight.w400,
                  //               Constant.getPercentSize(screenHeight, 2.4)),
                  //         ],
                  //       )),
                  //       Container(
                  //         margin: EdgeInsets.all(appBarPadding),
                  //         height: getEditHeight(),
                  //         color: Colors.yellow,
                  //       )
                  //       // Padding(
                  //       //   padding:
                  //       //       EdgeInsets.symmetric(vertical: appBarPadding),
                  //       //   child: SizedBox(
                  //       //     height: getEditHeight(),
                  //       //   ),
                  //       // )
                  //     ],
                  //   ),
                  //   // fillOverscroll: false,
                  //   // fillOverscroll: true,
                  //   // hasScrollBody: true,
                  // )
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: getButton(
                    primaryColor, true, "Add to Cart", Colors.white, () {
                  Constant.sendToScreen(HomeScreen(selectedTab: 2), context);
                }, FontWeight.w600, EdgeInsets.all(appBarPadding)),
              )
            ],
          ),
        ),
        onWillPop: () async {
          finishScreen();
          return false;
        });
  }
}
