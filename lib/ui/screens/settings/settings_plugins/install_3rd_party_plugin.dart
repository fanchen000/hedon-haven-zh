import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '/services/plugin_manager.dart';
import '/ui/widgets/alert_dialog.dart';
import '/utils/global_vars.dart';

class Install3rdPartyPluginScreen extends StatefulWidget {
  final bool partOfOnboarding;

  const Install3rdPartyPluginScreen({super.key, this.partOfOnboarding = false});

  @override
  State<Install3rdPartyPluginScreen> createState() =>
      _Install3rdPartyPluginScreenState();
}

class _Install3rdPartyPluginScreenState
    extends State<Install3rdPartyPluginScreen> {
  String? fileName;
  Map<String, dynamic>? pluginConfigMap;
  String? configFormatted;
  bool? isTestingPlugin;
  bool funcTestFailed = false;
  bool? isImportingPlugin;
  bool allowPop = false;

  @override
  void initState() {
    super.initState();
    // Don't show warning in dev mode
    sharedStorage.getBool("general_enable_dev_options").then((value) {
      if (!thirdPartyPluginWarningShown && !value!) {
        logger.d("Showing third party warning");
        WidgetsBinding.instance
            .addPostFrameCallback((_) => showThirdPartyWarning());
      }
    });
  }

  void resetProgress() {
    setState(() {
      fileName = null;
      pluginConfigMap = null;
      configFormatted = null;
      isTestingPlugin = null;
      funcTestFailed = false;
      isImportingPlugin = null;
    });
  }

  void showThirdPartyWarning() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return PopScope(
              canPop: false,
              child: ThemedDialog(
                title: "第三方插件安全提醒",
                primaryText: "了解风险并继续",
                onPrimary: () {
                  Navigator.pop(context);
                  thirdPartyPluginWarningShown = true;
                },
                secondaryText: "取消",
                onSecondary: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                content: const Text(
                    "Importing plugins from untrusted sources may put your device at risk! "
                    "The developers of Hedon Haven take no responsibility for any damage or "
                    "unintended consequences of using plugins from untrusted sources.",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ));
        });
  }

  void showFunctionalityFailWarning() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return PopScope(
              canPop: false,
              child: ThemedDialog(
                title: "功能测试未通过",
                primaryText: "仍然导入",
                onPrimary: () {
                  Navigator.pop(context);
                  importPlugin();
                },
                secondaryText: "取消导入",
                onSecondary: () {
                  resetProgress();
                  Navigator.of(context).pop();
                },
                content: const Text(
                    "Some functionality tests failed. The plugin might not "
                    "fully work as intended.",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ));
        });
  }

  void showErrorDialog(String title, String message) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ThemedDialog(
            title: title,
            primaryText: "Ok",
            onPrimary: () {
              resetProgress();
              Navigator.pop(context);
            },
            content: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: const EdgeInsets.all(5.0),
              child: Text(message.trim(),
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        });
  }

  void extractPlugin() async {
    resetProgress();
    try {
      var selectedFile = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ["zip"]);
      pluginConfigMap =
          await PluginManager.extractNewPlugin(selectedFile.first.path!);
      configFormatted = "Name: ${pluginConfigMap!["metadata"]["prettyName"]} "
          "(${pluginConfigMap!["metadata"]["codeName"]})"
          "\nProvider for: ${pluginConfigMap!["providerData"]["providerUrl"]}"
          "\nVersion: ${pluginConfigMap!["metadata"]["version"]}"
          "\nDeveloper: ${pluginConfigMap!["metadata"]["developer"]}"
          "\nContact email: ${pluginConfigMap!["metadata"]["contactEmail"]}"
          "\nDescription: ${pluginConfigMap!["metadata"]["description"]}"
          "\nUpdate URL: ${pluginConfigMap!["metadata"]["updateUrl"] ?? "暂不支持更新"}";
      setState(() => fileName = selectedFile.first.name);
    } catch (e, stacktrace) {
      if (e.toString().contains("AlreadyInstalled")) {
        showErrorDialog(
            "检测到重复插件",
            "A plugin with the codename: "
                "${e.toString().split(":").last.trim()} is already installed! "
                "请先卸载原有插件！");
        return;
      }
      logger.w("Error extracting plugin: $e\n$stacktrace");
      showErrorDialog("不是有效的插件 ZIP 文件！", "$e\n$stacktrace");
      setState(() => fileName = null);
    }
    logger.i("Finished extracting plugin, waiting for user confirmation");
  }

  void testPlugin() async {
    setState(() => isTestingPlugin = true);
    logger.i("正在测试插件功能");
    try {
      final passed = await PluginManager.testExternalPlugin(
          Directory(pluginConfigMap!["tempPluginPath"]));
      if (!passed) {
        logger.w("功能测试全部或部分未通过");
        setState(() {
          isTestingPlugin = false;
          funcTestFailed = true;
        });
        showFunctionalityFailWarning();
      } else {
        setState(() => isTestingPlugin = false);
        importPlugin();
      }
    } catch (e, stacktrace) {
      logger.e("Failed to run functionality tests: $e\n$stacktrace");
      showErrorDialog("功能测试运行失败", "$e\n$stacktrace");
      setState(() {
        funcTestFailed = true;
        isTestingPlugin = false;
      });
    }
  }

  void importPlugin() async {
    setState(() => isImportingPlugin = true);
    try {
      await PluginManager.importNewPlugin(pluginConfigMap!);
      // Tell videoLists to update
      reloadVideoListEvent.add(null);
      setState(() => isImportingPlugin = false);
    } catch (e, stacktrace) {
      logger.e("Failed to import plugin: $e\n$stacktrace");
      showErrorDialog("导入插件失败", "$e\n$stacktrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: allowPop ||
            isImportingPlugin == isTestingPlugin && isImportingPlugin != true,
        onPopInvokedWithResult: (goingToPop, __) {
          if (!goingToPop) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ThemedDialog(
                    title: "取消安装插件吗？",
                    primaryText: "继续安装",
                    onPrimary: Navigator.of(context).pop,
                    secondaryText: "取消安装",
                    onSecondary: () {
                      allowPop = true;
                      // close popup
                      Navigator.pop(context);
                      // Go back a screen
                      Navigator.of(context).pop(false);
                    },
                  );
                });
          }
        },
        child: Scaffold(
            appBar: AppBar(
              iconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
              title: Text("安装第三方插件"),
            ),
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  fileName != null
                                      ? "$fileName"
                                      : "选择 ZIP 文件：",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  onPressed: isTestingPlugin != null
                                      ? null
                                      : () => extractPlugin(),
                                  child: Row(children: [
                                    Text("选择 "),
                                    Icon(size: 20, Icons.open_in_new),
                                  ]))
                            ],
                          ),
                          if (configFormatted != null) ...[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text("插件详情：",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(configFormatted!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                )
                              ],
                            ),
                            if (isTestingPlugin == null)
                              Row(mainAxisSize: MainAxisSize.max, children: [
                                Spacer(),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: () => testPlugin(),
                                    child: Text("测试并导入")),
                                Spacer()
                              ])
                          ],
                          if (isTestingPlugin != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("功能测试：",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                isTestingPlugin!
                                    ? SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator())
                                    : Icon(
                                        funcTestFailed
                                            ? Icons.error
                                            : Icons.check_circle,
                                        size: 30,
                                        color: funcTestFailed
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary)
                              ],
                            ),
                          if (isImportingPlugin != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("正在导入插件：",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                isImportingPlugin!
                                    ? SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator())
                                    : Icon(Icons.check_circle,
                                        size: 30,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)
                              ],
                            ),
                            if (!isImportingPlugin!)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Spacer(),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text("完成")),
                                Spacer()
                              ])
                          ]
                        ])))));
  }
}
