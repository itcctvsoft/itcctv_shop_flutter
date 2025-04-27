// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/model_trending.dart';
import 'package:shoplite/ui/items/product_detail.dart';
import 'package:shoplite/ui/search/filter_screen.dart';

import '../../constants/data_file.dart';

class AllProductList extends StatefulWidget {
  const AllProductList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AllProductList();
  }
}

class _AllProductList extends State<AllProductList> {
  List<ModelTrending> popularList = DataFile.getAllPopularProduct();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double appbarPadding = getAppBarPadding();
    double marginPopular = appbarPadding;
    int crossAxisCountPopular = 2;
    double popularWidth =
        (screenWidth - ((crossAxisCountPopular - 1) * marginPopular)) /
            crossAxisCountPopular;
    // var _width = ( _screenWidth - ((_crossAxisCount - 1) * _crossAxisSpacing)) / _crossAxisCount;

    double popularHeight = Constant.getPercentSize(screenHeight, 40);

    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              getDefaultHeader(
                  context,
                  "All Products",
                  () {
                    Constant.backToFinish(context);
                  },
                  (value) {},
                  withFilter: true,
                  filterFun: () {
                    Constant.sendToScreen(const FilterScreen(), context);
                  }),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.all(marginPopular),
                  crossAxisCount: crossAxisCountPopular,
                  crossAxisSpacing: marginPopular,
                  mainAxisSpacing: marginPopular,
                  // crossAxisSpacing: 10,
                  childAspectRatio: popularWidth / popularHeight,
                  shrinkWrap: true,
                  primary: true,
                  children: List.generate(popularList.length, (index) {
                    ModelTrending modelPopular = popularList[index];
                    return InkWell(
                      onTap: () {
                        Constant.sendToScreen(const ProductDetail(product: null,), context);
                      },
                      child: Container(
                        height: popularHeight,
                        width: popularWidth,
                        padding: EdgeInsets.all(
                            Constant.getPercentSize(popularHeight, 3.3)),
                        decoration: ShapeDecoration(
                            color: cardColor,
                            shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                    cornerRadius: Constant.getPercentSize(
                                        popularHeight, 4),
                                    cornerSmoothing: 0.5)),
                            shadows: [
                              BoxShadow(
                                  color: shadowColor,
                                  spreadRadius: 1.2,
                                  blurRadius: 2)
                            ]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: ShapeDecoration(
                                  color: cardColor,
                                  shape: SmoothRectangleBorder(
                                      borderRadius: SmoothBorderRadius(
                                          cornerRadius: Constant.getPercentSize(
                                              popularHeight, 4),
                                          cornerSmoothing: 0.3)),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              Constant.getPercentSize(
                                                  popularHeight, 4))),
                                      child: Image.asset(
                                          Constant.assetImagePath +
                                              modelPopular.image!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover),
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: getFavWidget(
                                          popularHeight,
                                          index == 0,
                                          EdgeInsets.all(
                                              Constant.getPercentSize(
                                                  popularWidth, 3))),
                                    ),
                                    ((modelPopular.sale ?? "").isNotEmpty)
                                        ? Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              margin: EdgeInsets.all(
                                                  Constant.getPercentSize(
                                                      popularWidth, 2.5)),
                                              child: getCustomText(
                                                  "SALE",
                                                  Colors.white,
                                                  1,
                                                  TextAlign.start,
                                                  FontWeight.normal,
                                                  Constant.getPercentSize(
                                                      popularHeight, 4)),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constant.getPercentSize(
                                                          popularWidth, 5),
                                                  vertical:
                                                      Constant.getPercentSize(
                                                          popularWidth, 3)),
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius
                                                      .all(Radius.circular(
                                                          Constant
                                                              .getPercentSize(
                                                                  popularHeight,
                                                                  5))),
                                                  color: Colors.black),
                                            ),
                                          )
                                        : getSpace(0)
                                  ],
                                ),
                              ),
                              flex: 1,
                            ),
                            getSpace(Constant.getPercentSize(popularHeight, 5)),
                            getCustomText(
                                modelPopular.title ?? "",
                                fontBlack,
                                1,
                                TextAlign.start,
                                FontWeight.bold,
                                Constant.getPercentSize(popularHeight, 5.5)),
                            getSpace(
                                Constant.getPercentSize(popularHeight, 2.6)),
                            Row(
                              children: [
                                getCustomText(
                                    modelPopular.price ?? "",
                                    fontBlack,
                                    1,
                                    TextAlign.start,
                                    FontWeight.w400,
                                    Constant.getPercentSize(
                                        popularHeight, 5.5)),
                                getHorSpace(
                                    Constant.getPercentSize(popularWidth, 1.5)),
                                ((modelPopular.sale ?? "").isNotEmpty)
                                    ? Expanded(
                                        child: getCustomTextWithStrike(
                                            modelPopular.price ?? "",
                                            Colors.red,
                                            1,
                                            TextAlign.start,
                                            FontWeight.w500,
                                            Constant.getPercentSize(
                                                popularHeight, 5.5)),
                                        flex: 1,
                                      )
                                    : Container()
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                flex: 1,
              )
            ],
          ),
        ),
        onWillPop: () async {
          Constant.backToFinish(context);
          return false;
        });
  }
}
