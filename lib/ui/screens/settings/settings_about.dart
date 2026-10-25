import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '/services/bug_report_manager.dart';
import '/services/plugin_manager.dart';
import '/services/update_manager.dart';
import '/ui/screens/bug_report/bug_report.dart';
import '/ui/utils/toast_notification.dart';
import '/ui/utils/update_dialog.dart';
import '/utils/bundled_plugin.dart';
import '/utils/global_vars.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int devSettingsCounter = 0;

  String returnAppType() {
    logger.d("package name: ${packageInfo.packageName}");
    if (packageInfo.packageName.split(".").last == "debug") {
      return "debug";
    } else if (packageInfo.packageName.split(".").last == "viewer" &&
        packageInfo.packageName.split(".").length == 3) {
      return "release";
    } else if (packageInfo.packageName.split(".").last == "profile") {
      return "profile";
    } else {
      // TODO: Add desktop versions
      return "UNKNOWN TYPE; PLEASE REPORT THIS TO THE DEVELOPERS";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("关于"),
        ),
        body: SafeArea(
            child: SizedBox(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                            leading: const Icon(Icons.abc_outlined),
                            title: const Text("应用名称"),
                            subtitle: Text(packageInfo.appName),
                            onTap: () async {
                              if (devSettingsCounter == 6) {
                                if (kDebugMode) {
                                  logger.w(
                                      "Dev settings permanently enabled in debug releases. Refusing to toggle");
                                  showToast(
                                      "Dev settings permanently enabled in debug releases. Refusing to toggle",
                                      context);
                                  return;
                                }
                                bool devSettingsEnabled = (await sharedStorage
                                    .getBool("general_enable_dev_options"))!;
                                if (devSettingsEnabled) {
                                  // disable tester plugin if leaving debug mode
                                  PluginManager.disablePlugin(
                                      (await getBundledPluginByName(
                                          "com.hedon_haven.tester_internal"))!);
                                }

                                devSettingsEnabled = !devSettingsEnabled;
                                sharedStorage.setBool(
                                    "general_enable_dev_options",
                                    devSettingsEnabled);
                                // reload plugins to show TesterPlugin in release versions too
                                await PluginManager.init();
                                showToast(
                                    "Dev settings ${devSettingsEnabled ? "enabled" : "disabled"}",
                                    context);
                                devSettingsCounter = 0;
                              } else {
                                devSettingsCounter++;
                              }
                            }),
                        ListTile(
                          leading: const Icon(Icons.info),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary),
                            onPressed: () async {
                              if (Platform.isLinux ||
                                  Platform.isMacOS ||
                                  Platform.isWindows ||
                                  Platform.isIOS) {
                                showToast(
                                    "Auto-updates not yet supported for ${Platform.operatingSystem}",
                                    context);
                              } else {
                                try {
                                  UpdateManager updateManager = UpdateManager();
                                  if (await updateManager.updateAvailable() ==
                                      true) {
                                    showUpdateDialog(updateManager, context);
                                    setState(() {});
                                  } else {
                                    showToast("No update available", context);
                                  }
                                } catch (e, stacktrace) {
                                  logger.e(
                                      "Failed to manually check for update: $e\n$stacktrace");
                                  showToast(
                                      "Failed to manually check for update: $e",
                                      context);
                                }
                              }
                            },
                            child: Text("检查更新",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                          ),
                          title: const Text("版本"),
                          subtitle: Text(
                              "${packageInfo.version} - ${returnAppType()}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.key),
                          title: const Text("构建签名"),
                          // TODO: Update source code link
                          subtitle: Text(packageInfo.buildSignature != ""
                              ? packageInfo.buildSignature
                              : "None"),
                        ),
                        ListTile(
                            leading: const Icon(Icons.code),
                            title: const Text("源代码"),
                            // TODO: Update source code link
                            subtitle:
                                const Text("https://source.hedon-haven.top"),
                            onTap: () {
                              launchUrl(
                                  Uri.parse("https://source.hedon-haven.top"));
                            }),
                        ListTile(
                            leading: const Icon(Icons.text_snippet),
                            title: const Text("查看开源许可"),
                            subtitle: const Text(
                                "查看本应用包含的全部许可证"),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    settings:
                                        RouteSettings(name: "/licenses_page"),
                                    builder: (context) => LicensePage(
                                          applicationName: "Hedon Haven",
                                        )))),
                        ListTile(
                            leading: const Icon(Icons.bug_report),
                            title: const Text("反馈问题"),
                            subtitle: const Text(
                                "长按应用中的任意内容可反馈问题"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  settings: RouteSettings(name: "/bug-report"),
                                  builder: (context) => BugReportScreen(
                                      submissionType: SubmissionType.manual,
                                      bugReportsList: []),
                                ),
                              );
                            }),
                        ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text("贡献者"),
                            subtitle: const Text("查看所有贡献者"),
                            onTap: () {
                              // This is a rather non-critical link, therefore its not
                              // url-linked via the hedon-haven.top domain
                              launchUrl(Uri.parse(
                                  "https://github.com/Hedon-Haven/Hedon-Haven/graphs/contributors"));
                            }),
                        ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: const Text("捐助"),
                            subtitle: const Text("支持项目开发"),
                            onTap: () => launchUrl(Uri.parse(
                                "https://donations.hedon-haven.top"))),
                      ],
                    )))));
  }
}
