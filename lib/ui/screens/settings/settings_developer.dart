import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '/services/analytics_manager.dart';
import '/services/database_manager.dart';
import '/services/icon_manager.dart';
import '/services/plugin_manager.dart';
import '/services/shared_prefs_manager.dart';
import '/services/update_manager.dart';
import '/ui/utils/toast_notification.dart';
import '/ui/utils/update_dialog.dart';
import '/ui/widgets/alert_dialog.dart';
import '/ui/widgets/options_switch.dart';
import '/utils/custom_logger.dart';
import '/utils/global_vars.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  void downloadCustomUpdate(BuildContext context) async {
    String? tag;
    String? link;

    TextEditingController textController = TextEditingController();
    tag = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
            canPop: false,
            // Do not allow the user to close the dialog
            onPopInvoked: (_) {},
            child: ThemedDialog(
                title: "Set custom update tag",
                primaryText: "下一步",
                onPrimary: () => Navigator.of(context).pop(textController.text),
                secondaryText: "取消",
                onSecondary: () => Navigator.of(context).pop(null),
                content: TextField(
                    controller: textController,
                    // hint with the current version
                    decoration: InputDecoration(
                        hintText: "e.g. v${packageInfo.version}"))));
      },
    );

    if (tag?.isEmpty ?? true) {
      showToast("Tag cannot be empty", context);
      return;
    }

    textController.clear();
    link = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
            canPop: false,
            // Do not allow the user to close the dialog
            onPopInvoked: (_) {},
            child: ThemedDialog(
                title: "Set custom update link",
                primaryText: "Attempt update",
                onPrimary: () => Navigator.of(context).pop(textController.text),
                secondaryText: "取消",
                onSecondary: () =>
                    {tag = null, Navigator.of(context).pop(null)},
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      "Set custom link (leave empty for default). The updater"
                      " will use 'link/tag/os-arch.extension to download. "
                      "E.g. https://download.hedon-haven.top/v0.3.14/android-arm64.apk'"
                      "\n\nDO NOT ADD A TRAILING /",
                      style: Theme.of(context).textTheme.titleSmall),
                  TextField(
                      controller: textController,
                      decoration: InputDecoration(
                          hintText:
                              "E.g. https://github.com/myuser/myrepo/releases/download "
                              "(without / at the end!)"))
                ])));
      },
    );

    if (tag != null) {
      UpdateManager updateManager = UpdateManager();
      updateManager.latestTag = tag;
      if (link?.isNotEmpty ?? false) {
        updateManager.downloadLink = link!;
      }
      updateManager.latestChangeLog =
          "Note: On operating systems that verify app signatures (e.g. "
          "Android), using a custom update URL not pointing to the official "
          "Hedon Haven repository may not work due to a signature mismatch.";
      showUpdateDialog(updateManager, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("开发者选项"),
        ),
        body: SafeArea(
            child: SizedBox(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                            leading: const Icon(Icons.settings_backup_restore),
                            title: const Text("恢复所有默认设置"),
                            onTap: () async {
                              await setDefaultSettings(true);
                              await PluginManager.init();
                              showToast(
                                  "All settings have been reset. Reloading UI in 2 seconds",
                                  context);
                              await Future.delayed(const Duration(seconds: 2));
                              // Reload entire UI
                              globalSetState();
                            }),
                        ListTile(
                            leading: const Icon(Icons.storage),
                            title: const Text("删除所有数据库"),
                            onTap: () async {
                              // Purge db, then immediately recreate it
                              await purgeDatabase();
                              await initDb();
                              showToast(
                                  "All databases have been deleted", context);
                            }),
                        ListTile(
                            leading: const Icon(Icons.extension_off),
                            title:
                                const Text("删除所有第三方扩展"),
                            onTap: () async {
                              // delete the whole plugins dir
                              Directory appSupportDir =
                                  await getApplicationSupportDirectory();
                              await Directory("${appSupportDir.path}/plugins")
                                  .delete(recursive: true);
                              await PluginManager.init();
                              showToast(
                                  "All third-party extensions have been deleted",
                                  context);
                            }),
                        ListTile(
                            leading: const Icon(Icons.cached),
                            title: const Text("刷新图标缓存"),
                            onTap: () async {
                              // delete the whole plugins dir
                              await downloadPluginIcons(force: true);
                              showToast(
                                  "Icon cache has been refreshed", context);
                            }),
                        ListTile(
                            leading: const Icon(Icons.widgets),
                            title: const Text("重新加载界面"),
                            onTap: () async {
                              showToast(
                                  "Reloading entire UI in 2 seconds", context);
                              await Future.delayed(const Duration(seconds: 2));
                              globalSetState();
                            }),
                        FutureBuilder<bool?>(
                            future:
                                sharedStorage.getBool("general_enable_logging"),
                            builder: (context, snapshot) {
                              return OptionsSwitch(
                                title: "启用日志",
                                leadingWidget: const Icon(Icons.bug_report),
                                switchState:
                                    kDebugMode ? true : snapshot.data ?? false,
                                nonInteractive: kDebugMode,
                                onToggled: (newState) async {
                                  await sharedStorage.setBool(
                                      "general_enable_logging", newState);
                                  showToast("Restarting app to apply changes",
                                      context);
                                  showToast(
                                      "Logging ${newState ? "enabled" : "disabled"}",
                                      context);
                                },
                              );
                            }),
                        ListTile(
                            leading: const Icon(Icons.list),
                            title: const Text("View current log"),
                            onTap: () {
                              getApplicationSupportDirectory()
                                  .then((appSupportDir) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        settings:
                                            RouteSettings(name: "/log_screen"),
                                        builder: (context) => LogScreen(
                                            logText: File(
                                                    "${appSupportDir.path}/logs/current.log")
                                                .readAsStringSync())));
                              });
                            }),
                        ListTile(
                            leading: const Icon(Icons.share),
                            title: const Text("导出全部日志"),
                            onTap: () async {
                              try {
                                await BetterSimplePrinter().exportLogs();
                              } catch (e) {
                                showToast(e.toString(), context);
                              }
                            }),
                        ListTile(
                            leading: const Icon(Icons.clear),
                            title: const Text("清空日志"),
                            onTap: () async {
                              try {
                                BetterSimplePrinter().clearLogs();
                                showToast("Logs cleared", context);
                              } catch (e) {
                                showToast(e.toString(), context);
                              }
                            }),
                        ListTile(
                          leading: const Icon(Icons.update),
                          title: const Text("安装自定义更新"),
                          onTap: () {
                            if (Platform.isLinux ||
                                Platform.isMacOS ||
                                Platform.isWindows ||
                                Platform.isIOS) {
                              showToast(
                                  "Updates not yet supported for ${Platform.operatingSystem}",
                                  context);
                              return;
                            }
                            downloadCustomUpdate(context);
                          },
                        ),
                        ListTile(
                            leading: const Icon(Icons.network_ping),
                            title: const Text("发送使用统计请求"),
                            onTap: () async {
                              try {
                                await sendUsagePing();
                                showToast(
                                    "Usage ping sent if opted-in", context);
                              } catch (e) {
                                showToast(e.toString(), context);
                              }
                            }),
                      ],
                    )))));
  }
}

class LogScreen extends StatelessWidget {
  final String logText;

  const LogScreen({super.key, required this.logText});

  @override
  Widget build(BuildContext context) {
    // Split the logText into lines
    final lines = logText.split('\n');

    // Create a list of TextSpan widgets
    final textSpans = lines.map((line) {
      Color color;
      if (line.startsWith('[T]')) {
        color = Colors.grey;
      } else if (line.startsWith('[D]')) {
        color = Colors.white;
      } else if (line.startsWith('[I]')) {
        color = Colors.blue;
      } else if (line.startsWith('[W]')) {
        color = Colors.yellow;
      } else if (line.startsWith('[E]')) {
        color = Colors.red;
      } else if (line.startsWith('[F]')) {
        color = Colors.purple;
      } else {
        color = Colors.white; // Default color
      }

      return TextSpan(
        text: '$line\n',
        style: TextStyle(color: color),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: const Text("当前日志"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              child: SelectableText.rich(
                TextSpan(children: textSpans),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
