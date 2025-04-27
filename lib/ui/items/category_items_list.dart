// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/data_file.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/models/model_category_items.dart';

import 'product_detail.dart';

class CategoryItemsList extends StatefulWidget {
  const CategoryItemsList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CategoryItemsList();
  }
}

class _CategoryItemsList extends State<CategoryItemsList> {
  List<ModelCategoryItems> catItemsList = DataFile.getAllCategoryItems();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    double screenWidth = SizeConfig.safeBlockHorizontal! * 100;
    double screenHeight = SizeConfig.safeBlockVertical! * 100;
    double itemHeight = Constant.getPercentSize(screenHeight, 14);
    double appBarPadding = getAppBarPadding();

    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              getDefaultHeader(context, "Women", () {
                Constant.backToFinish(context);
              }, (value) {}),
              Expanded(
                child: ListView.builder(
                  itemCount: catItemsList.length,
                  padding: EdgeInsets.symmetric(vertical: appBarPadding / 2),
                  shrinkWrap: true,
                  primary: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    ModelCategoryItems catItems = catItemsList[index];
                    return InkWell(
                      onTap: () {
                        Constant.sendToScreen(const ProductDetail(product: null,), context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                            horizontal: appBarPadding,
                            vertical: appBarPadding / 2),
                        height: itemHeight,
                        padding: EdgeInsets.all(
                            Constant.getPercentSize(itemHeight, 10)),
                        decoration: ShapeDecoration(
                          color: cardColor,
                          shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius:
                                      Constant.getPercentSize(itemHeight, 20),
                                  cornerSmoothing: 1.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: double.infinity,
                              width: Constant.getPercentSize(itemHeight, 79),
                              decoration: ShapeDecoration(
                                color: cardColor,
                                shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(
                                        cornerRadius: Constant.getPercentSize(
                                            itemHeight, 15),
                                        cornerSmoothing: 1.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(
                                    Constant.getPercentSize(itemHeight, 15))),
                                child: Image.asset(
                                  Constant.assetImagePath + catItems.image!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            getHorSpace(
                                Constant.getPercentSize(screenWidth, 3)),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  getCustomText(
                                      catItems.title ?? "",
                                      fontBlack,
                                      1,
                                      TextAlign.start,
                                      FontWeight.w600,
                                      Constant.getPercentSize(
                                          itemHeight, 18.5)),
                                  getSpace(
                                      Constant.getPercentSize(itemHeight, 3.8)),
                                  Row(
                                    children: [
                                      getCustomText(
                                          catItems.total ?? "",
                                          Colors.grey,
                                          1,
                                          TextAlign.start,
                                          FontWeight.w500,
                                          Constant.getPercentSize(
                                              itemHeight, 16.5)),
                                      getHorSpace(2),
                                      Expanded(
                                        child: getCustomText(
                                            "items",
                                            Colors.grey,
                                            1,
                                            TextAlign.start,
                                            FontWeight.w600,
                                            Constant.getPercentSize(
                                                itemHeight, 15.5)),
                                        flex: 1,
                                      )
                                    ],
                                  )
                                ],
                              ),
                              flex: 1,
                            )
                          ],
                        ),
                      ),
                    );
                  },
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
