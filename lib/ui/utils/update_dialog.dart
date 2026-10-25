import 'package:material_ui/material_ui.dart';

import '/services/update_manager.dart';
import '/ui/widgets/alert_dialog.dart';
import '/utils/global_vars.dart';

void showUpdateDialog(UpdateManager updateManager, BuildContext parentContext) {
  String? failReason;
  bool isDownloadingUpdate = false;
  showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          // This is for showing the download progress
          updateManager.addListener(() => setState(() {}));
          return Scaffold(
              body: PopScope(
                  canPop: false,
                  // Do not allow the user to close the dialog
                  onPopInvoked: (_) {},
                  child: ThemedDialog(
                    title: failReason != null ? "更新失败" : "应用更新",
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: failReason == null
                              ? const EdgeInsets.only(bottom: 20)
                              : EdgeInsets.zero,
                          child: Text(
                              failReason != null
                                  ? "Update failed due to $failReason\n\nPlease try again later."
                                  : isDownloadingUpdate
                                      ? updateManager.downloadProgress == 0.0
                                          ? "正在获取更新信息…"
                                          : updateManager.downloadProgress ==
                                                  1.0
                                              ? "正在安装更新…"
                                              : "正在下载更新…"
                                      : "请先安装更新以继续",
                              style: Theme.of(context).textTheme.titleMedium)),
                      if (updateManager.latestChangeLog != null &&
                          !isDownloadingUpdate &&
                          failReason == null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Latest changelog for ${updateManager.latestTag}: ",
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 5),
                            Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(updateManager.latestChangeLog!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall)))
                          ],
                        )
                      ],
                      if (isDownloadingUpdate && failReason == null) ...[
                        LinearProgressIndicator(
                            value: updateManager.downloadProgress)
                      ]
                    ]),
                    // Only show buttons if update is not downloading
                    primaryText: isDownloadingUpdate
                        ? null
                        : failReason != null
                            ? "Ok"
                            : "安装更新",
                    onPrimary: () async {
                      if (!isDownloadingUpdate && failReason == null) {
                        setState(() => isDownloadingUpdate = true);
                        logger.i("Starting update");
                        try {
                          await updateManager.downloadAndInstallUpdate(
                              updateManager.latestTag!);
                        } catch (e, stacktrace) {
                          logger.e("Update failed with: $e\n$stacktrace");
                          setState(() {
                            isDownloadingUpdate = false;
                            failReason = "$e\n$stacktrace";
                          });
                        }
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    secondaryText: isDownloadingUpdate || failReason != null
                        ? null
                        : "稍后安装",
                    onSecondary: Navigator.of(context).pop,
                  )));
        });
      });
}
