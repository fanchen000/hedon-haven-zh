import 'package:dynamic_app_icon_flutter_plus/dynamic_app_icon_flutter_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '/ui/utils/toast_notification.dart';
import '/ui/widgets/alert_dialog.dart';
import '/utils/global_vars.dart';

class LauncherAppearance extends StatefulWidget {
  final bool partOfOnboarding;

  const LauncherAppearance({super.key, this.partOfOnboarding = false});

  @override
  State<LauncherAppearance> createState() => _LauncherAppearanceScreenState();
}

class _LauncherAppearanceScreenState extends State<LauncherAppearance> {
  // the actual default icon is called "stock" everywhere except here
  final List<String> list = ["default", "fake_settings", "reminders"];

  void handleOptionChange(String? value) async {
    if (value != null) {
      // show dialog explaining the option if needed
      if (value != "Hedon Haven") {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return ThemedDialog(
                primaryText: "Ok",
                onPrimary: Navigator.of(context).pop,
                content: Text(
                    value == "提醒事项"
                        ? "Create a new reminder called \"Stop concealing\" to exit reminders mode."
                        : "Press and hold \"Show signal strength in advanced mode\" for 5 seconds to exit GSM Settings mode",
                    style: Theme.of(context).textTheme.titleMedium),
              );
            });
      }
      setState(() {});
      showDialog(
          context: context,
          builder: (BuildContext context) {
            // running setupAppIcon will force the app to quit. Ask user to confirm first
            return ThemedDialog(
                content: Text(
                    "App will now close and can be found again as \"$value\" in the launcher.",
                    style: Theme.of(context).textTheme.titleMedium),
                primaryText: widget.partOfOnboarding
                    ? "完成首次设置"
                    : "关闭应用",
                onPrimary: () async {
                  if (kDebugMode || kProfileMode) {
                    showToast(
                        "Doesn't work in Debug or Profile versions", context);
                    Navigator.of(context).pop();
                    return;
                  }
                  if (widget.partOfOnboarding) {
                    logger.i("首次设置已完成");
                    await sharedStorage.setBool(
                        "general_onboarding_completed", true);
                  }
                  // close popup
                  Navigator.pop(context);
                  sharedStorage.setString(
                      "appearance_launcher_appearance", value);
                  switch (value) {
                    case "Hedon Haven":
                      logger.i("Changing to stock icon");
                      await DynamicAppIconFlutterPlus.setAlternateIconName(
                          null);
                      break;
                    case "GSM 设置":
                      logger.i("Changing to GSM settings icon");
                      await DynamicAppIconFlutterPlus.setAlternateIconName(
                          "fake_settings");
                      break;
                    case "提醒事项":
                      logger.i("Changing to reminders icon");
                      await DynamicAppIconFlutterPlus.setAlternateIconName(
                          "reminders");
                      break;
                  }
                },
                secondaryText: "取消",
                onSecondary: Navigator.of(context).pop);
          });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Hide back button in onboarding
          automaticallyImplyLeading: !widget.partOfOnboarding,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          title: widget.partOfOnboarding
              ? Center(child: Text("桌面图标与名称"))
              : const Text("桌面图标与名称"),
        ),
        body: SafeArea(
            child: Column(children: [
          SingleChildScrollView(
              child: FutureBuilder<String?>(
                  future:
                      sharedStorage.getString("appearance_launcher_appearance"),
                  builder: (context, snapshot) {
                    // Don't show anything until the future is done
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                                title: const Text("Hedon Haven"),
                                leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(20 * 0.20),
                                        child: Image.asset(
                                            "assets/launcher-icon/stock.png"),
                                      ),
                                    )),
                                onTap: () => handleOptionChange("Hedon Haven"),
                                trailing: Radio(
                                  value: "Hedon Haven",
                                  groupValue: snapshot.data!,
                                  onChanged: handleOptionChange,
                                )),
                            const SizedBox(height: 10),
                            ListTile(
                                title: const Text("GSM 设置"),
                                leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(20 * 0.20),
                                        child: Image.asset(
                                            "assets/launcher-icon/fake_settings.png"),
                                      ),
                                    )),
                                onTap: () => handleOptionChange("GSM 设置"),
                                trailing: Radio(
                                  value: "GSM 设置",
                                  groupValue: snapshot.data!,
                                  onChanged: handleOptionChange,
                                )),
                            const SizedBox(height: 10),
                            ListTile(
                              title: const Text("提醒事项"),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color.fromARGB(255, 51, 181, 229),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20 * 0.20),
                                    child: Image.asset(
                                        "assets/launcher-icon/reminders.png"),
                                  ),
                                ),
                              ),
                              onTap: () => handleOptionChange("提醒事项"),
                              trailing: Radio(
                                value: "提醒事项",
                                groupValue: snapshot.data!,
                                onChanged: handleOptionChange,
                              ),
                            )
                          ],
                        ));
                  })),
          if (widget.partOfOnboarding) ...[
            Spacer(),
            Padding(
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                          style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("返回",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)))),
                  Spacer(),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                          style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            logger.i("首次设置已完成");
                            await sharedStorage.setBool(
                                "general_onboarding_completed", true);
                            // Force redraw of main screen to exit onboarding
                            globalSetState();
                            // Go back to main screen
                            await Navigator.pushNamedAndRemoveUntil(
                                context, "/", (route) => false);
                          },
                          child: Text("完成初始设置",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary))))
                ]))
          ]
        ])));
  }
}
