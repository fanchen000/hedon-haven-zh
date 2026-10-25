import 'package:material_ui/material_ui.dart';

import '/utils/global_vars.dart';
import 'settings_about.dart';
import 'settings_appearance.dart';
import 'settings_comments.dart';
import 'settings_developer.dart';
import 'settings_history.dart';
import 'settings_media.dart';
import 'settings_plugins/settings_plugins.dart';
import 'settings_privacy.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showPluginsBadge = false;

  @override
  void initState() {
    super.initState();

    // Enable badge when plugin update check finishes and updates are available
    pluginUpdatesAvailableEvent.stream.listen((value) =>
        context.mounted ? setState(() => showPluginsBadge = value != 0) : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: Text("设置",
              style: Theme.of(context).textTheme.headlineLarge),
        ),
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text("插件"),
                    subtitle: const Text(
                        "管理插件及其设置"),
                    leading: Badge(
                        isLabelVisible: showPluginsBadge,
                        smallSize: 12,
                        alignment: AlignmentDirectional.centerEnd,
                        child: const Icon(Icons.extension)),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings:
                                  RouteSettings(name: "/settings_plugins_list"),
                              builder: (context) => const PluginsScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("外观"),
                    subtitle: const Text(
                        "默认主题、首页开关、视频预览"),
                    leading: const Icon(Icons.palette),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings:
                                  RouteSettings(name: "/settings_appearance"),
                              builder: (context) => const AppearanceScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("播放设置"),
                    subtitle: const Text(
                        "视频清晰度、快进时长、播放器行为"),
                    leading: const Icon(Icons.headphones),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: RouteSettings(name: "/settings_media"),
                              builder: (context) => const MediaScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("评论"),
                    subtitle: const Text("评论筛选及垃圾评论设置"),
                    leading: const Icon(Icons.comment),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings:
                                  RouteSettings(name: "/settings_comments"),
                              builder: (context) => const CommentsScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("历史记录"),
                    subtitle: const Text("Watch & Search history"),
                    leading: const Icon(Icons.history),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings:
                                  RouteSettings(name: "/settings_history"),
                              builder: (context) => const HistoryScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("隐私"),
                    subtitle:
                        const Text("隐藏应用预览、键盘无痕模式"),
                    leading: const Icon(Icons.lock),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings:
                                  RouteSettings(name: "/settings_privacy"),
                              builder: (context) => const PrivacyScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text("关于"),
                    subtitle: const Text("关于应用"),
                    leading: const Icon(Icons.info),
                    onTap: () {
                      // The AboutScreen has an option to turn on dev settings -> setState on return to immediately show/hide dev settings
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: RouteSettings(name: "/settings_about"),
                              builder: (context) => AboutScreen())).then(
                          (value) => setState(() {}));
                    },
                  ),
                  FutureBuilder<bool?>(
                      future:
                          sharedStorage.getBool("general_enable_dev_options"),
                      builder: (context, snapshot) {
                        // Don't show anything until the future is done
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        return snapshot.data!
                            ? ListTile(
                                title: const Text("开发者选项"),
                                subtitle: const Text("开发和调试设置"),
                                leading: const Icon(Icons.data_object),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          settings: RouteSettings(
                                              name: "/settings_developer"),
                                          builder: (context) =>
                                              const DeveloperScreen()));
                                },
                              )
                            : const SizedBox();
                      })
                ],
              )),
        ));
  }
}
