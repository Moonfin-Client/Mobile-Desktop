import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/repositories/session_repository.dart';
import '../../../data/services/plugin_sync_service.dart';
import '../../../di/providers.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../admin/providers/admin_status_providers.dart';
import '../../../util/platform_detection.dart';
import 'customization_entries.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prefs = GetIt.instance<UserPreferences>();
    final pluginSync = GetIt.instance<PluginSyncService>();
    final showSeerrIntegration =
        pluginSync.pluginAvailable && prefs.get(UserPreferences.seerrEnabled);
    final isAdmin = ref.watch(isAdminProvider);
    final adminBadgeCount = isAdmin
        ? ref.watch(adminNotificationSummaryProvider).valueOrNull?.count ?? 0
        : 0;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accountEntries = <_SettingsEntry>[
      _SettingsEntry(
        icon: Icons.manage_accounts,
        title: l10n.authentication,
        subtitle: l10n.autoLoginServerManagement,
        onTap: () => context.push(Destinations.settingsAuth),
      ),
      _SettingsEntry(
        icon: Icons.pin,
        title: l10n.pinCode,
        subtitle: l10n.setUpPinCodeProtection,
        onTap: () => context.push(Destinations.settingsPinCode),
      ),
      _SettingsEntry(
        icon: Icons.child_care,
        title: l10n.parentalControls,
        subtitle: l10n.contentRatingRestrictions,
        onTap: () => context.push(Destinations.settingsParental),
      ),
    ];

    final customizationEntries = buildCustomizationEntries(
      isMobile: PlatformDetection.isMobile,
      l10n: l10n,
    ).map((entry) => _SettingsEntry(
          icon: entry.icon,
          title: entry.title,
          subtitle: entry.subtitle,
          onTap: () => context.push(entry.destination),
        )).toList();

    final playbackEntries = <_SettingsEntry>[
      _SettingsEntry(
        icon: Icons.play_circle_fill,
        title: l10n.playback,
        subtitle: l10n.bitRateResolutionBehavior,
        onTap: () => context.push(Destinations.settingsPlayback),
      ),
      _SettingsEntry(
        icon: Icons.subtitles,
        title: l10n.subtitles,
        subtitle: l10n.languageSizeAppearance,
        onTap: () => context.push(Destinations.settingsSubtitles),
      ),
      _SettingsEntry(
        icon: Icons.download,
        title: l10n.download,
        subtitle: l10n.qualityStorage,
        onTap: () => context.push(Destinations.settingsDownloads),
      ),
    ];

    final moonfinEntries = <_SettingsEntry>[
      _SettingsEntry(
        iconBuilder: (size, color) => Image.asset(
          'assets/icons/moonfin.png',
          width: size,
          height: size,
          color: color,
          fit: BoxFit.contain,
        ),
        title: l10n.pluginLabel,
        subtitle: l10n.serverSyncAndPluginStatus,
        onTap: () => context.push(Destinations.settingsPlugin),
      ),
      if (showSeerrIntegration)
        _SettingsEntry(
          iconBuilder: (size, color) => Image.asset(
            'assets/icons/seerr.png',
            width: size,
            height: size,
            color: color,
            fit: BoxFit.contain,
          ),
          title: l10n.seerr,
          subtitle: l10n.mediaRequestIntegration,
          onTap: () => context.push(Destinations.settingsSeerr),
        ),
    ];

    final otherEntries = <_SettingsEntry>[
      _SettingsEntry(
        icon: Icons.swap_horiz,
        title: l10n.switchServer,
        onTap: () => context.go(Destinations.serverSelect),
      ),
      _SettingsEntry(
        icon: Icons.logout,
        title: l10n.signOut,
        onTap: () async {
          await GetIt.instance<SessionRepository>().destroyCurrentSession();
          if (context.mounted) context.go(Destinations.serverSelect);
        },
      ),
      _SettingsEntry(
        icon: Icons.info,
        title: l10n.aboutTitle,
        subtitle: l10n.versionLicenses,
        onTap: () => context.push(Destinations.settingsAbout),
      ),
    ];

    final sections = <_SettingsSectionData>[
      _SettingsSectionData(
        icon: Icons.manage_accounts,
        title: l10n.account,
        subtitle: l10n.signInAndSecurity,
        entries: accountEntries,
      ),
      if (isAdmin)
        _SettingsSectionData(
          icon: Icons.admin_panel_settings,
          title: l10n.administration,
          subtitle: l10n.serverSettingsUsersLibraries,
          entries: const [],
          badgeCount: adminBadgeCount,
          onTap: () => context.push(Destinations.admin),
        ),
      _SettingsSectionData(
        icon: Icons.brush,
        title: l10n.customization,
        subtitle: l10n.themeAndLayout,
        entries: customizationEntries,
        onTap: () => context.push(Destinations.settingsCustomization),
      ),
      _SettingsSectionData(
        icon: Icons.play_circle,
        title: l10n.playback,
        subtitle: l10n.videoAndSubtitles,
        entries: playbackEntries,
      ),
      _SettingsSectionData(
        iconBuilder: (size, color) => Image.asset(
          'assets/icons/moonfin.png',
          width: size,
          height: size,
          color: color,
          fit: BoxFit.contain,
        ),
        title: l10n.integrations,
        subtitle: l10n.pluginAndRequests,
        entries: moonfinEntries,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.customizeAccountPlaybackInterface,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1500
                ? 5
                : width >= 1180
                  ? 4
                  : width >= 860
                    ? 3
                    : width >= 360
                      ? 2
                      : 1;
              final cardWidth = (width - (columns - 1) * 10) / columns;
              final cardScale = columns >= 4
                ? 0.64
                : columns == 3
                  ? 0.72
                  : 0.82;
              final cardHeight = (cardWidth * cardScale).clamp(136.0, 196.0);
              final compactCard = cardHeight < 164;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _SettingsSectionCard(
                    section: section,
                    compact: compactCard,
                    onTap: () {
                      if (section.onTap != null) {
                        section.onTap!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _SectionDetailScreen(section: section),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              l10n.other,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SettingsListCard(entries: otherEntries),
        ],
      ),
    );
  }
}

class _SettingsSectionData {
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final String title;
  final String subtitle;
  final List<_SettingsEntry> entries;
  final VoidCallback? onTap;
  final int badgeCount;

  const _SettingsSectionData({
    this.icon,
    this.iconBuilder,
    required this.title,
    required this.subtitle,
    required this.entries,
    this.onTap,
    this.badgeCount = 0,
  });
}

class _SettingsSectionCard extends StatelessWidget {
  final _SettingsSectionData section;
  final bool compact;
  final VoidCallback onTap;

  const _SettingsSectionCard({
    required this.section,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(10, 9, 10, 8)
        : const EdgeInsets.fromLTRB(11, 11, 11, 9);
    final iconBoxSize = compact ? 42.0 : 48.0;
    final iconSize = compact ? 20.0 : 22.0;
    final iconRadius = compact ? 12.0 : 14.0;
    final titleStyle = compact
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;
    final optionsStyle = compact
        ? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final arrowSize = compact ? 24.0 : 26.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(iconRadius),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: section.iconBuilder != null
                          ? section.iconBuilder!(iconSize, Colors.white)
                          : Icon(section.icon, size: iconSize),
                    ),
                    if (section.badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            section.badgeCount > 9 ? '9+' : '${section.badgeCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 3),
              Text(
                section.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
              const Spacer(),
              Row(
                children: [
                  if (section.entries.isNotEmpty)
                    Text(
                      l10n.optionsCount(section.entries.length),
                      style: optionsStyle,
                    ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    size: arrowSize,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDetailScreen extends StatelessWidget {
  final _SettingsSectionData section;

  const _SectionDetailScreen({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < section.entries.length; i++) ...[
                  _SettingsEntryTile(entry: section.entries[i]),
                  if (i != section.entries.length - 1)
                    Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 12,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsListCard extends StatelessWidget {
  final List<_SettingsEntry> entries;

  const _SettingsListCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _SettingsEntryTile(entry: entries[i]),
            if (i != entries.length - 1)
              Divider(
                height: 1,
                indent: 70,
                endIndent: 12,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SettingsEntry {
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsEntry({
    this.icon,
    this.iconBuilder,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
}

class _SettingsEntryTile extends StatelessWidget {
  final _SettingsEntry entry;

  const _SettingsEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minLeadingWidth: 40,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        ),
        child: entry.iconBuilder != null
            ? entry.iconBuilder!(20, Colors.white)
            : Icon(entry.icon, size: 20),
      ),
      title: Text(
        entry.title,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: entry.subtitle != null
          ? Text(
              entry.subtitle!,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: entry.onTap,
    );
  }
}
