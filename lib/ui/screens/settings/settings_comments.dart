import 'package:material_ui/material_ui.dart';

import '/ui/widgets/alert_dialog.dart';
import '/ui/widgets/options_switch.dart';
import '/utils/global_vars.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("评论"),
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    FutureBuilder<bool?>(
                      future: sharedStorage.getBool("comments_hide_hidden"),
                      builder: (context, snapshot) {
                        return OptionsSwitch(
                            title: "隐藏已屏蔽或垃圾评论",
                            subTitle: "Hide comments that were hidden by the "
                                "creator or marked as spam.",
                            switchState: snapshot.data ?? false,
                            onToggled: (value) async => await sharedStorage
                                .setBool("comments_hide_hidden", value));
                      },
                    ),
                    FutureBuilder<bool?>(
                        future: sharedStorage.getBool("comments_hide_negative"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "隐藏负评分评论",
                              subTitle: "Hide comments that have a rating of "
                                  "less than 0",
                              switchState: snapshot.data ?? false,
                              onToggled: (value) async => await sharedStorage
                                  .setBool("comments_hide_negative", value));
                        }),
                    ListTile(
                        title: const Text("评论文本筛选"),
                        subtitle: const Text("对评论应用文本筛选"),
                        onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ThemedDialog(
                                  title: "评论文本筛选",
                                  primaryText: "Ok",
                                  onPrimary: Navigator.of(context).pop,
                                  content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FutureBuilder<bool?>(
                                            future: sharedStorage.getBool(
                                                "comments_filter_links"),
                                            builder: (context, snapshot) {
                                              return OptionsSwitch(
                                                  title:
                                                      "隐藏带链接的评论",
                                                  subTitle:
                                                      "Comments with links "
                                                      "will be hidden",
                                                  switchState:
                                                      snapshot.data ?? false,
                                                  onToggled: (value) async =>
                                                      await sharedStorage.setBool(
                                                          "comments_filter_links",
                                                          value));
                                            }),
                                        FutureBuilder<bool?>(
                                            future: sharedStorage.getBool(
                                                "comments_filter_non_ascii"),
                                            builder: (context, snapshot) {
                                              return OptionsSwitch(
                                                  title:
                                                      "隐藏非 ASCII 字符评论",
                                                  subTitle:
                                                      "Hide comments with non"
                                                      "-ascii (non-english) text",
                                                  switchState:
                                                      snapshot.data ?? false,
                                                  onToggled: (value) async =>
                                                      await sharedStorage.setBool(
                                                          "comments_filter_non_ascii",
                                                          value));
                                            })
                                      ]));
                            })),
                  ],
                ))));
  }
}
