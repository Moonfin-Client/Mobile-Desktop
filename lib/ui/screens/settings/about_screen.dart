import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/app_update_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appVersion = GetIt.instance<DeviceInfo>().appVersion;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(child: Image.asset('assets/images/logo_and_text.png', height: 80)),
          const SizedBox(height: 4),
          Center(child: Text(l10n.versionValue(appVersion))),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Moonfin',
              applicationVersion: appVersion,
              applicationIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/logo_and_text.png', height: 48),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.sourceCode),
            subtitle: const Text('https://github.com/Moonfin-Client/Mobile-Desktop'),
            onTap: () => launchUrl(Uri.parse('https://github.com/Moonfin-Client/Mobile-Desktop')),
          ),
          if (PlatformDetection.isDesktop) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: Text(l10n.checkForUpdatesNow),
              subtitle: Text(l10n.checksLatestDesktopRelease),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await GetIt.instance<AppUpdateService>().checkForUpdateNowDetailed();
                if (!context.mounted) {
                  return;
                }

                final l10n = AppLocalizations.of(context);
                messenger.clearSnackBars();
                final update = result.update;
                if (update == null) {
                  final message = switch (result.status) {
                    DesktopUpdateCheckStatus.upToDate => l10n.youAreUpToDate,
                    DesktopUpdateCheckStatus.checkFailed => l10n.couldNotCheckForUpdates,
                    DesktopUpdateCheckStatus.noMatchingAsset => l10n.noCompatibleUpdate,
                    DesktopUpdateCheckStatus.unsupportedPlatform => l10n.updateChecksNotSupported,
                    DesktopUpdateCheckStatus.disabledByPreference => l10n.updateNotificationsDisabled,
                    DesktopUpdateCheckStatus.rateLimited => l10n.pleaseWaitBeforeChecking,
                    DesktopUpdateCheckStatus.alreadyNotified => l10n.latestUpdateAlreadyShown,
                    DesktopUpdateCheckStatus.updateAvailable => l10n.updateAvailable,
                  };
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  return;
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.updateAvailableVersion(update.version)),
                    duration: const Duration(seconds: 10),
                    action: SnackBarAction(
                      label: l10n.download,
                      onPressed: () {
                        launchUrl(
                          update.downloadUri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.updateNotificationsEnabled,
              title: l10n.updateNotifications,
              subtitle: l10n.showWhenUpdatesAvailable,
              icon: Icons.system_update,
            ),
          ],
        ],
      ),
    );
  }
}
