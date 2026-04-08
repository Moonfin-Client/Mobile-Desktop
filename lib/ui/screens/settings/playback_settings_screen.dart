import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playback)),
      body: ListView(
        children: [
          _section(context, l10n.video),
          StringPickerPreferenceTile(
            preference: UserPreferences.maxBitrate,
            title: l10n.maxStreamingBitrate,
            icon: Icons.speed,
            options: {
              'auto': l10n.auto,
              '300': '300 Mbps',
              '250': '250 Mbps',
              '200': '200 Mbps',
              '160': '160 Mbps',
              '120': '120 Mbps',
              '100': '100 Mbps',
              '80': '80 Mbps',
              '60': '60 Mbps',
              '40': '40 Mbps',
              '20': '20 Mbps',
              '15': '15 Mbps',
              '10': '10 Mbps',
              '8': '8 Mbps',
              '4': '4 Mbps',
              '2': '2 Mbps',
              '1': '1 Mbps',
            },
          ),
          EnumPreferenceTile<MaxVideoResolution>(
            preference: UserPreferences.maxVideoResolution,
            title: l10n.maxResolution,
            icon: Icons.high_quality,
            labelOf: (v) => switch (v) {
              MaxVideoResolution.auto => l10n.auto,
              MaxVideoResolution.res480p => '480p',
              MaxVideoResolution.res720p => '720p',
              MaxVideoResolution.res1080p => '1080p',
              MaxVideoResolution.res2160p => '4K',
            },
          ),
          EnumPreferenceTile<ZoomMode>(
            preference: UserPreferences.playerZoomMode,
            title: l10n.playerZoomMode,
            icon: Icons.crop,
            labelOf: (v) => switch (v) {
              ZoomMode.fit => l10n.fit,
              ZoomMode.autoCrop => l10n.autoCrop,
              ZoomMode.stretch => l10n.stretch,
            },
          ),
          EnumPreferenceTile<RefreshRateSwitchingBehavior>(
            preference: UserPreferences.refreshRateSwitchingBehavior,
            title: l10n.refreshRateSwitching,
            icon: Icons.monitor,
            labelOf: (v) => switch (v) {
              RefreshRateSwitchingBehavior.disabled => l10n.disabled,
              RefreshRateSwitchingBehavior.scaleOnTv => l10n.scaleOnTv,
              RefreshRateSwitchingBehavior.scaleOnDevice => l10n.scaleOnDevice,
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.trickPlayEnabled,
            title: l10n.trickPlay,
            subtitle: l10n.showPreviewThumbnailsWhenSeeking,
            icon: Icons.preview,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showDescriptionOnPause,
            title: l10n.showDescriptionOnPause,
            subtitle: l10n.dimVideoShowOverview,
            icon: Icons.description,
          ),
          if (PlatformDetection.isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.osdLockEnabled,
              title: l10n.osdLockButton,
              subtitle: l10n.osdLockButtonDescription,
              icon: Icons.lock_outline,
            ),
          _section(context, l10n.audio),
          EnumPreferenceTile<AudioBehavior>(
            preference: UserPreferences.audioBehavior,
            title: l10n.audioBehavior,
            icon: Icons.surround_sound,
            labelOf: (v) => switch (v) {
              AudioBehavior.directStream => l10n.directStream,
              AudioBehavior.downmixToStereo => l10n.downmixToStereo,
            },
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.defaultAudioLanguage,
            title: l10n.defaultAudioLanguage,
            icon: Icons.language,
            options: {
              '': l10n.autoServerDefault,
              'eng': l10n.english,
              'spa': l10n.spanish,
              'fra': l10n.french,
              'deu': l10n.german,
              'ita': l10n.italian,
              'por': l10n.portuguese,
              'jpn': l10n.japanese,
              'kor': l10n.korean,
              'zho': l10n.chinese,
              'rus': l10n.russian,
              'ara': l10n.arabic,
              'hin': l10n.hindi,
              'nld': l10n.dutch,
              'swe': l10n.swedish,
              'nor': l10n.norwegian,
              'dan': l10n.danish,
              'fin': l10n.finnish,
              'pol': l10n.polish,
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.ac3Enabled,
            title: l10n.ac3Passthrough,
            icon: Icons.speaker,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.trueHdEnabled,
            title: l10n.trueHdSupport,
            subtitle: l10n.enableTrueHdAudio,
            icon: Icons.speaker,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.audioNightMode,
            title: l10n.nightMode,
            subtitle: l10n.compressDynamicRange,
            icon: Icons.nightlight,
          ),
          if (PlatformDetection.isDesktop || Platform.isAndroid) ...[
            _section(context, l10n.advancedMpv),
            SwitchPreferenceTile(
              preference: UserPreferences.customMpvConfEnabled,
              title: l10n.enableCustomMpvConf,
              subtitle: l10n.applyMpvConfBeforePlayback,
              icon: Icons.tune,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.customMpvConfUnsafeAdvanced,
              title: l10n.unsafeAdvancedMpvOptions,
              subtitle: l10n.unsafeMpvOptionsDescription,
              icon: Icons.warning_amber,
            ),
            const _MpvConfPathTile(),
          ],
          _section(context, l10n.nextUpAndQueuing),
          EnumPreferenceTile<NextUpBehavior>(
            preference: UserPreferences.nextUpBehavior,
            title: l10n.nextUpBehavior,
            icon: Icons.skip_next,
            labelOf: (v) => switch (v) {
              NextUpBehavior.extended => l10n.extended,
              NextUpBehavior.minimal => l10n.minimal,
              NextUpBehavior.disabled => l10n.disabled,
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.nextUpTimeout,
            title: l10n.nextUpTimeout,
            icon: Icons.timer,
            min: 0,
            max: 30000,
            divisions: 30,
            labelOf: (v) => v == 0 ? l10n.disabled : l10n.secondsValue((v / 1000).round()),
          ),
          // SwitchPreferenceTile(
          //   preference: UserPreferences.cinemaModeEnabled,
          //   title: 'Cinema Mode',
          //   subtitle: 'Play trailers and intros before content',
          //   icon: Icons.movie,
          // ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaQueuingEnabled,
            title: l10n.mediaQueuing,
            subtitle: l10n.autoQueueNextEpisodes,
            icon: Icons.queue_play_next,
          ),
          EnumPreferenceTile<StillWatchingBehavior>(
            preference: UserPreferences.stillWatchingBehavior,
            title: l10n.stillWatchingPrompt,
            icon: Icons.visibility,
            labelOf: (v) => switch (v) {
              StillWatchingBehavior.disabled => l10n.disabled,
              _ => l10n.afterEpisodesAndHours(v.episodes, v.hours),
            },
          ),
          _section(context, l10n.resumeAndSkip),
          StringPickerPreferenceTile(
            preference: UserPreferences.resumeSubtractDuration,
            title: l10n.resumeRewind,
            icon: Icons.replay,
            options: {
              '0': l10n.none,
              '5': l10n.fiveSeconds,
              '10': l10n.tenSeconds,
              '15': l10n.fifteenSeconds,
              '30': l10n.thirtySeconds,
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.skipBackLength,
            title: l10n.skipBackLength,
            icon: Icons.replay_10,
            min: 5000,
            max: 60000,
            divisions: 11,
            labelOf: (v) => l10n.secondsValue((v / 1000).round()),
          ),
          SliderPreferenceTile(
            preference: UserPreferences.skipForwardLength,
            title: l10n.skipForwardLength,
            icon: Icons.forward_30,
            min: 5000,
            max: 60000,
            divisions: 11,
            labelOf: (v) => l10n.secondsValue((v / 1000).round()),
          ),
        ],
      ),
    );
  }

  static Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MpvConfPathTile extends StatefulWidget {
  const _MpvConfPathTile();

  @override
  State<_MpvConfPathTile> createState() => _MpvConfPathTileState();
}

class _MpvConfPathTileState extends State<_MpvConfPathTile> {
  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      UserPreferences.customMpvConfPath,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) => ListTile(
        leading: const Icon(Icons.description),
        title: Text(l10n.customMpvConfPath),
        subtitle: Text(
          value.trim().isEmpty
              ? l10n.notSetMpvConf
              : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _showPathDialog(context, value),
        trailing: IconButton(
          tooltip: l10n.browse,
          icon: const Icon(Icons.folder_open),
          onPressed: () => _pickPath(),
        ),
      ),
    );
  }

  Future<void> _pickPath() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['conf'],
      dialogTitle: l10n.selectMpvConf,
    );
    final picked = result?.files.single.path?.trim();
    if (picked == null || picked.isEmpty) {
      return;
    }
    _binding.value = picked;
  }

  Future<void> _showPathDialog(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.customMpvConfPath),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.pathToMpvConf,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l10n.clear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      _binding.value = result;
    }
  }
}
