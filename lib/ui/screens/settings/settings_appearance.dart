import 'package:material_ui/material_ui.dart';

import '/ui/widgets/options_dialog.dart';
import '/ui/widgets/options_switch.dart';
import '/utils/global_vars.dart';
import 'settings_launcher_appearance.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("外观"),
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    ListTile(
                        trailing: Icon(Icons.arrow_forward),
                        title: const Text("桌面图标与名称"),
                        subtitle: const Text(
                            "在桌面隐藏真实应用图标和名称"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                settings:
                                    RouteSettings(name: "/launcher_appearance"),
                                builder: (context) =>
                                    const LauncherAppearance()))),
                    FutureBuilder<String?>(
                      future: sharedStorage.getString("appearance_theme_mode"),
                      builder: (context, snapshot) {
                        return OptionsTile(
                          title: "主题",
                          subtitle: snapshot.data ?? "",
                          options: const [
                            "跟随系统主题",
                            "浅色主题",
                            "深色主题"
                          ],
                          selectedOption: snapshot.data ?? "",
                          onSelected: (value) async {
                            await sharedStorage.setString(
                                "appearance_theme_mode", value);
                            globalSetState();
                            setState(() {});
                          },
                        );
                      },
                    ),
                    FutureBuilder<String?>(
                        future: sharedStorage.getString("appearance_list_view"),
                        builder: (context, snapshot) {
                          return OptionsTile(
                              // TODO: Add visualization of the list modes
                              title: "列表展示方式",
                              subtitle: snapshot.data ?? "",
                              options: const ["卡片", "网格", "列表"],
                              selectedOption: snapshot.data ?? "",
                              onSelected: (value) async {
                                await sharedStorage.setString(
                                    "appearance_list_view", value);
                                setState(() {});
                              });
                        }),
                    FutureBuilder<bool?>(
                        future:
                            sharedStorage.getBool("appearance_play_previews"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "自动播放预览",
                              subTitle:
                                  "在首页及搜索结果页播放预览",
                              switchState: snapshot.data ?? true,
                              onToggled: (value) async => await sharedStorage
                                  .setBool("appearance_play_previews", value));
                        }),
                    FutureBuilder<bool?>(
                        future: sharedStorage
                            .getBool("appearance_homepage_enabled"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "启用首页",
                              subTitle: "启动应用时显示首页",
                              switchState: snapshot.data ?? true,
                              onToggled: (value) async {
                                await sharedStorage.setBool(
                                    "appearance_homepage_enabled", value);
                                reloadVideoListEvent.add(null);
                              });
                        })
                  ],
                ))));
  }
}
