import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:secure_app_switcher/secure_app_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '/ui/utils/toast_notification.dart';
import '/ui/widgets/alert_dialog.dart';
import '/ui/widgets/options_switch.dart';
import '/utils/global_vars.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("隐私"),
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    FutureBuilder<bool?>(
                        future:
                            sharedStorage.getBool("privacy_hide_app_preview"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "隐藏应用预览",
                              subTitle: "在多任务切换界面隐藏应用预览",
                              switchState: snapshot.data ?? true,
                              onToggled: (value) async {
                                await sharedStorage.setBool(
                                    "privacy_hide_app_preview", value);
                                // Force an immediate update
                                if (Platform.isAndroid || Platform.isIOS) {
                                  if (!value) {
                                    SecureAppSwitcher.off();
                                  } else {
                                    SecureAppSwitcher.on();
                                  }
                                }
                                // the hidePreview var is from main.dart
                                setState(() => hidePreview = value);
                              });
                        }),
                    FutureBuilder<bool?>(
                        future: sharedStorage
                            .getBool("privacy_keyboard_incognito_mode"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "启用键盘无痕模式",
                              subTitle:
                                  "建议键盘启用无痕模式（如停用联想输入和词汇学习）",
                              switchState: snapshot.data ?? true,
                              onToggled: (value) async =>
                                  await sharedStorage.setBool(
                                      "privacy_keyboard_incognito_mode",
                                      value));
                        }),
                    FutureBuilder<bool?>(
                        future: sharedStorage
                            .getBool("privacy_show_external_link_warning"),
                        builder: (context, snapshot) {
                          return OptionsSwitch(
                              title: "打开外部链接时提醒",
                              subTitle:
                                  "使用默认浏览器打开外部链接前显示提醒",
                              switchState: snapshot.data ?? true,
                              onToggled: (value) async =>
                                  await sharedStorage.setBool(
                                      "privacy_show_external_link_warning",
                                      value));
                        }),
                    ListTile(
                        trailing: Icon(Icons.arrow_forward),
                        title: const Text("代理设置"),
                        subtitle:
                            const Text("开启或关闭代理、选择代理"),
                        onTap: () {
                          showToast("代理功能尚未完全实现",
                              context);
                          return;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  settings:
                                      RouteSettings(name: "/settings_proxy"),
                                  builder: (context) => const ProxyScreen()));
                        }),
                    ...buildAnalyticsOptions()
                  ],
                ))));
  }
}

List<Widget> buildAnalyticsOptions({bool reduceBorders = false}) {
  return [
    FutureBuilder<bool?>(
        future: sharedStorage.getBool("analytics_enable_usage_ping"),
        builder: (context, snapshot) {
          String description = "Sends a small anonymous ping "
              "on app startup with app details "
              "(version, build, install source) "
              "and OS details "
              "(type, version, architecture). "
              "Used to estimate user counts and platform "
              "distribution. "
              "\nRead more: https://docs.hedon-haven.top/analytics.md";
          return OptionsSwitch(
              title: "启用匿名使用计数",
              subTitle: "启动应用时发送匿名统计请求",
              maxSubTitleLines: 2,
              trailingWidget: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => ThemedDialog(
                          title: "匿名统计请求",
                          primaryText: "Ok",
                          onPrimary: () => Navigator.pop(context),
                          content: GestureDetector(
                              onTap: () => launchUrl(Uri.parse(
                                  "https://docs.hedon-haven.top/analytics.md")),
                              child: Text(description,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge)),
                        )),
              ),
              switchState: snapshot.data ?? false,
              reduceBorders: reduceBorders,
              onToggled: (value) =>
                  sharedStorage.setBool("analytics_enable_usage_ping", value));
        }),
    FutureBuilder<bool?>(
        future: sharedStorage.getBool("analytics_enable_automatic_bug_reports"),
        builder: (context, snapshot) {
          String description = "Automatically submit anonymous"
              " bug reports whenever they are created. These "
              "contain app details (version, build, "
              "install source), OS details "
              "(type, version, architecture) and error message,"
              " stack trace, screen path, plugin name and "
              "debug info. \nBug reports will not be "
              "automatically submitted for third party plugins. "
              "\nRead more: https://docs.hedon-haven.top/analytics.md";
          return OptionsSwitch(
              title: "启用自动错误报告",
              subTitle: "自动提交匿名错误报告",
              maxSubTitleLines: 2,
              trailingWidget: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => ThemedDialog(
                          title: "匿名统计请求",
                          primaryText: "Ok",
                          onPrimary: () => Navigator.pop(context),
                          content: GestureDetector(
                              onTap: () => launchUrl(Uri.parse(
                                  "https://docs.hedon-haven.top/analytics.md")),
                              child: Text(description,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge)),
                        )),
              ),
              switchState: snapshot.data ?? false,
              reduceBorders: reduceBorders,
              onToggled: (value) => sharedStorage.setBool(
                  "analytics_enable_automatic_bug_reports", value));
        })
  ];
}

class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> {
  void setCustomProxy(String proxy) async {
    TextEditingController textController = TextEditingController(text: proxy);

    String? newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return ThemedDialog(
            title: "设置自定义代理服务器（IP:端口）",
            primaryText: "应用",
            onPrimary: () => Navigator.of(context).pop(textController.text),
            secondaryText: "取消",
            onSecondary: () => Navigator.of(context).pop(null),
            content: TextField(
                controller: textController,
                decoration:
                    InputDecoration(hintText: "e.g. 256.256.256.256:8080")));
      },
    );

    if (newValue != null) {
      await sharedStorage.setString("privacy_proxy_address", newValue);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: const Text("隐私"),
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: FutureBuilder<bool?>(
                    future: sharedStorage.getBool("privacy_proxy_enabled"),
                    builder: (context, proxyEnabled) {
                      return Column(children: <Widget>[
                        OptionsSwitch(
                            title: "启用代理",
                            subTitle: "强制所有网络请求通过"
                                " the proxy",
                            switchState: proxyEnabled.data ?? false,
                            onToggled: (value) async {
                              await sharedStorage.setBool(
                                  "privacy_proxy_enabled", value);
                              setState(() {});
                            }),
                        FutureBuilder<String?>(
                            future: sharedStorage
                                .getString("privacy_proxy_address"),
                            builder: (context, snapshot) {
                              return ListTile(
                                enabled: proxyEnabled.data ?? false,
                                title: Text("当前代理服务器"),
                                subtitle: Text(snapshot.data?.isEmpty ?? true
                                    ? "尚未设置"
                                    : snapshot.data!),
                                trailing: Icon(Icons.edit),
                                onTap: () => setCustomProxy(snapshot.data!),
                              );
                            }),
                        ListTile(
                            enabled: proxyEnabled.data ?? false,
                            trailing: const Icon(Icons.bolt),
                            title: const Text("寻找最快的代理"),
                            onTap: () {
                              showToast("功能尚未实现", context);
                            }),
                        ListTile(
                            enabled: proxyEnabled.data ?? false,
                            trailing: const Icon(Icons.shuffle),
                            title: const Text("随机选择代理"),
                            onTap: () {
                              showToast("功能尚未实现", context);
                            })
                      ]);
                    }))));
  }
}
