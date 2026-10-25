import 'package:material_ui/material_ui.dart';

import '/ui/utils/toast_notification.dart';
import '/ui/widgets/options_dialog.dart';
import '/ui/widgets/options_switch.dart';
import '/utils/universal_formats.dart';

class FilterScreen extends StatefulWidget {
  final UniversalSearchRequest searchRequest;

  const FilterScreen({super.key, required this.searchRequest});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String searchString = "";
  String sortingType = "";
  String dateRange = "";
  double minFps = 0;
  double maxFps = 60;

  double minQualityIndex = 0;
  double maxQualityIndex = 8;
  final List<int> qualities = [0, 144, 240, 360, 480, 720, 1080, 1440, 2160];

  double minDurationIndex = 0;
  double maxDurationIndex = 5;

  // 0, 5, 10, 20, 30, 60 min
  final List<int> durationsInSeconds = [0, 300, 600, 1200, 1800, 3600];

  @override
  void initState() {
    super.initState();
    setFiltersFrom(widget.searchRequest);
    setState(() {});
  }

  void setFiltersFrom(UniversalSearchRequest request) {
    searchString = request.searchString;
    sortingType = request.sortingType;
    dateRange = request.dateRange;
    minFps = request.minFramesPerSecond.toDouble();
    maxFps = request.maxFramesPerSecond.toDouble();
    minQualityIndex = qualities.indexOf(request.minQuality).toDouble();
    maxQualityIndex = qualities.indexOf(request.maxQuality).toDouble();
    minDurationIndex =
        durationsInSeconds.indexOf(request.minDuration).toDouble();
    maxDurationIndex =
        durationsInSeconds.indexOf(request.maxDuration).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("搜索筛选"),
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            actions: [
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                onPressed: () async {
                  setFiltersFrom(
                      UniversalSearchRequest(searchString: searchString));
                  setState(() {});
                  showToast("Filters reset to default", context);
                },
                icon: const Icon(Icons.restart_alt),
              ),
              IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => Navigator.of(context).pop(
                      UniversalSearchRequest(
                          searchString: searchString,
                          sortingType: sortingType,
                          dateRange: dateRange,
                          minQuality: qualities[minQualityIndex.toInt()],
                          maxQuality: qualities[maxQualityIndex.toInt()],
                          minDuration:
                              durationsInSeconds[minDurationIndex.toInt()],
                          maxDuration:
                              durationsInSeconds[maxDurationIndex.toInt()],
                          minFramesPerSecond: minFps.toInt(),
                          maxFramesPerSecond: maxFps.toInt(),
                          virtualReality: false)),
                  icon: const Icon(Icons.check))
            ]),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(children: [
            OptionsTile(
                title: "排序方式",
                subtitle: sortingType,
                options: const [
                  "相关度",
                  "上传时间",
                  "播放量",
                  "评分",
                  "时长"
                ],
                selectedOption: sortingType,
                onSelected: (value) {
                  setState(() {
                    sortingType = value;
                  }); // Update the widget
                }),
            OptionsTile(
                title: "日期范围",
                subtitle: dateRange,
                options: const [
                  "不限时间",
                  "最近一年",
                  "最近一个月",
                  "最近一周",
                  "最近一天 / 三天 / 最新"
                  // aka last 3 days or latest on some websites
                ],
                selectedOption: dateRange,
                onSelected: (value) {
                  setState(() {
                    dateRange = value;
                  }); // Update the widget
                }),
            ListTile(
                title: const Text("类别"),
                subtitle: const Text("要包含或排除的类别"),
                onTap: () {
                  showToast("类别筛选尚未实现", context);
                }),
            ListTile(
                title: const Text("关键词"),
                subtitle: const Text("要包含或排除的关键词"),
                onTap: () {
                  showToast("关键词筛选尚未实现", context);
                }),
            Padding(
                padding: const EdgeInsets.only(left: 16, right: 20),
                child: Column(children: [
                  Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 80, child: Text("画质：")),
                        Expanded(
                            child: RangeSlider(
                          min: 0,
                          max: 8,
                          divisions: 8,
                          labels: RangeLabels(
                            // display actual resolutions, not the slider values
                            "${qualities[minQualityIndex.toInt()]}p",
                            "${qualities[maxQualityIndex.toInt()]}p",
                          ),
                          values: RangeValues(minQualityIndex, maxQualityIndex),
                          onChanged: (values) {
                            setState(() {
                              minQualityIndex = values.start;
                              maxQualityIndex = values.end;
                            });
                          },
                        ))
                      ]),
                  Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 80, child: Text("时长：")),
                        Expanded(
                            child: RangeSlider(
                          min: 0,
                          max: 5,
                          divisions: 5,
                          labels: RangeLabels(
                            // display actual resolutions, not the slider values
                            // .toStringAsFixed(0) removes the .0 at the end
                            "${(durationsInSeconds[minDurationIndex.toInt()] / 60).toStringAsFixed(0)} min",
                            maxDurationIndex <= 4
                                ? "${(durationsInSeconds[maxDurationIndex.toInt()] / 60).toStringAsFixed(0)} min"
                                : "60+ min",
                          ),
                          values:
                              RangeValues(minDurationIndex, maxDurationIndex),
                          onChanged: (values) {
                            setState(() {
                              minDurationIndex = values.start;
                              maxDurationIndex = values.end;
                            });
                          },
                        ))
                      ]),
                  Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 80, child: Text("FPS:")),
                        Expanded(
                            child: RangeSlider(
                          min: 0,
                          max: 60,
                          divisions: 2,
                          labels: RangeLabels(
                            // display actual resolutions, not the slider values
                            minFps == 0 ? "0/unknown fps" : "$minFps fps",
                            maxFps == 60 ? "60+ fps" : "$maxFps fps",
                          ),
                          values: RangeValues(minFps, maxFps),
                          onChanged: (values) {
                            setState(() {
                              minFps = values.start;
                              maxFps = values.end;
                            });
                          },
                        ))
                      ]),
                  OptionsSwitch(
                      title: "虚拟现实",
                      subTitle: "包含 VR 视频",
                      reduceBorders: true,
                      nonInteractive: true,
                      switchState: false,
                      onToggled: (value) {
                        showToast("VR is not yet implemented", context);
                        //setState(() => virtualReality = false);
                      }),
                  OptionsSwitch(
                      title: "倒序",
                      subTitle: "按相反顺序显示结果",
                      reduceBorders: true,
                      nonInteractive: true,
                      switchState: false,
                      onToggled: (value) {
                        showToast(
                            "倒序搜索尚未实现", context);
                        //setState(() => reverseOrder = false);
                      })
                ])),
          ]),
        )));
  }
}
