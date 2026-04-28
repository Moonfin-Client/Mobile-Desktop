import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../l10n/app_localizations.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../theme/app_theme_controller.dart';
import 'settings_app_bar.dart';

class AppearanceThemeScreen extends StatelessWidget {
  const AppearanceThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = GetIt.instance<UserPreferences>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildSettingsAppBar(context, Text(l10n.settingsAppearanceTheme)),
      body: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final selected = prefs.get(UserPreferences.visualTheme);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.settingsAppearanceThemeSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
                ),
              ),
              const SizedBox(height: 20),
              _ThemePreviewCard(
                themeId: VisualThemeId.moonfin,
                title: l10n.themeMoonfin,
                subtitle: l10n.themeMoonfinSubtitle,
                selected: selected == VisualThemeId.moonfin,
                stripes: const [
                  Color(0xFF101010),
                  Color(0xFF1A1A1A),
                  Color(0xFF252525),
                  Color(0xFF00A4DC),
                ],
              ),
              const SizedBox(height: 16),
              _ThemePreviewCard(
                themeId: VisualThemeId.neonPulse,
                title: l10n.themeNeonPulse,
                subtitle: l10n.themeNeonPulseSubtitle,
                selected: selected == VisualThemeId.neonPulse,
                stripes: const [
                  Color(0xFF0B0420),
                  Color(0xCC1E0A3F),
                  Color(0xFFFF2E92),
                  Color(0xFF00E5FF),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.themeId,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.stripes,
  });

  final VisualThemeId themeId;
  final String title;
  final String subtitle;
  final bool selected;
  final List<Color> stripes;

  @override
  Widget build(BuildContext context) {
    final prefs = GetIt.instance<UserPreferences>();
    final controller = AppThemeScope.of(context);
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await controller.applyThemeSelection(prefs, themeId);
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.fromBorderSide(
            ThemeRegistry.active.borders.chipBorder.copyWith(
              color: selected
                  ? AppColorScheme.accent
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          boxShadow: selected ? ThemeRegistry.active.borders.focusGlow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                if (selected)
                  Icon(Icons.check_circle, color: AppColorScheme.accent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: stripes),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 28,
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.fromBorderSide(
                            ThemeRegistry.active.borders.chipBorder.copyWith(
                              color: stripes.last.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}