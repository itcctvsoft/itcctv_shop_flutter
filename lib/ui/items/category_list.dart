// ignore: file_names
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/constants/constant.dart';
import 'package:shoplite/constants/size_config.dart';
import 'package:shoplite/constants/widget_utils.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/ui/items/category_items_list.dart';

import '../../constants/data_file.dart';
import '../../models/model_category.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CategoryList();
  }
}

class _CategoryList extends State<CategoryList> {
  List<ModelCategory> catList = DataFile.getAllCategory();

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

    double categoryHeight = Constant.getPercentSize(screenHeight, 33);
    double categoryWidth = Constant.getPercentSize(categoryHeight, 57);

    return WillPopScope(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              getDefaultHeader(context, "Category", () {
                Constant.backToFinish(context);
              }, (value) {}),
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCountPopular,
                  crossAxisSpacing: marginPopular,
                  mainAxisSpacing: marginPopular,
                  padding: EdgeInsets.symmetric(
                      horizontal: marginPopular, vertical: marginPopular),
                  // crossAxisSpacing: 10,
                  childAspectRatio: popularWidth / categoryHeight,
                  shrinkWrap: true,
                  primary: true,
                  children: List.generate(catList.length, (index) {
                    ModelCategory modelCat = catList[index];
                    return Center(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const CategoryItemsList(),
                          ));
                        },
                        child: SizedBox(
                          width: categoryWidth,
                          height: double.infinity,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: ShapeDecoration(
                                      shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius(
                                              cornerRadius:
                                                  Constant.getPercentSize(
                                                      categoryHeight, 50),
                                              cornerSmoothing: 0.8)),
                                      color: Colors.green),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(
                                        Constant.getPercentSize(
                                            categoryHeight, 50),
                                      ),
                                    ),
                                    child: Image.asset(
                                      Constant.assetImagePath + modelCat.image!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                flex: 1,
                              ),
                              getSpace(
                                  Constant.getPercentSize(categoryHeight, 4)),
                              getCustomText(
                                  modelCat.title ?? "",
                                  fontBlack,
                                  1,
                                  TextAlign.start,
                                  FontWeight.w700,
                                  Constant.getPercentSize(categoryHeight, 9)),
                              getSpace(
                                  Constant.getPercentSize(categoryHeight, 4))
                            ],
                          ),
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
