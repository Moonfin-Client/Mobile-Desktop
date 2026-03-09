import 'package:flutter/material.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: ListView(
        children: [
          StringPickerPreferenceTile(
            preference: UserPreferences.maxBitrate,
            title: 'Max Streaming Bitrate',
            icon: Icons.speed,
            options: const {
              '100': 'Auto',
              '120': '120 Mbps',
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
            title: 'Max Resolution',
            icon: Icons.high_quality,
            labelOf: (v) => switch (v) {
              MaxVideoResolution.auto => 'Auto',
              MaxVideoResolution.res480p => '480p',
              MaxVideoResolution.res720p => '720p',
              MaxVideoResolution.res1080p => '1080p',
              MaxVideoResolution.res2160p => '4K',
            },
          ),
          EnumPreferenceTile<AudioBehavior>(
            preference: UserPreferences.audioBehavior,
            title: 'Audio Behavior',
            icon: Icons.surround_sound,
            labelOf: (v) => switch (v) {
              AudioBehavior.directStream => 'Direct Stream',
              AudioBehavior.downmixToStereo => 'Downmix to Stereo',
            },
          ),
          EnumPreferenceTile<NextUpBehavior>(
            preference: UserPreferences.nextUpBehavior,
            title: 'Next Up Behavior',
            icon: Icons.skip_next,
            labelOf: (v) => switch (v) {
              NextUpBehavior.extended => 'Extended',
              NextUpBehavior.minimal => 'Minimal',
              NextUpBehavior.disabled => 'Disabled',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.nextUpTimeout,
            title: 'Next Up Timeout',
            icon: Icons.timer,
            min: 0,
            max: 30000,
            divisions: 30,
            labelOf: (v) => v == 0 ? 'Disabled' : '${(v / 1000).round()}s',
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.resumeSubtractDuration,
            title: 'Resume Rewind',
            icon: Icons.replay,
            options: const {
              '0': 'None',
              '5': '5 seconds',
              '10': '10 seconds',
              '15': '15 seconds',
              '30': '30 seconds',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.cinemaModeEnabled,
            title: 'Cinema Mode',
            subtitle: 'Play trailers and intros before content',
            icon: Icons.movie,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaQueuingEnabled,
            title: 'Media Queuing',
            subtitle: 'Auto-queue next episodes',
            icon: Icons.queue_play_next,
          ),
          EnumPreferenceTile<StillWatchingBehavior>(
            preference: UserPreferences.stillWatchingBehavior,
            title: 'Still Watching Prompt',
            icon: Icons.visibility,
            labelOf: (v) => switch (v) {
              StillWatchingBehavior.disabled => 'Disabled',
              _ => 'After ${v.episodes} episodes / ${v.hours}h',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.ac3Enabled,
            title: 'AC3 Passthrough',
            icon: Icons.speaker,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.audioNightMode,
            title: 'Night Mode',
            subtitle: 'Compress dynamic range',
            icon: Icons.nightlight,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.trickPlayEnabled,
            title: 'Trick Play',
            subtitle: 'Show preview thumbnails when seeking',
            icon: Icons.preview,
          ),
          EnumPreferenceTile<ZoomMode>(
            preference: UserPreferences.playerZoomMode,
            title: 'Player Zoom Mode',
            icon: Icons.crop,
            labelOf: (v) => switch (v) {
              ZoomMode.fit => 'Fit',
              ZoomMode.autoCrop => 'Auto Crop',
              ZoomMode.stretch => 'Stretch',
            },
          ),
          EnumPreferenceTile<RefreshRateSwitchingBehavior>(
            preference: UserPreferences.refreshRateSwitchingBehavior,
            title: 'Refresh Rate Switching',
            icon: Icons.monitor,
            labelOf: (v) => switch (v) {
              RefreshRateSwitchingBehavior.disabled => 'Disabled',
              RefreshRateSwitchingBehavior.scaleOnTv => 'Scale on TV',
              RefreshRateSwitchingBehavior.scaleOnDevice => 'Scale on Device',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showDescriptionOnPause,
            title: 'Show Description on Pause',
            icon: Icons.description,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.skipBackLength,
            title: 'Skip Back Length',
            icon: Icons.replay_10,
            min: 5000,
            max: 60000,
            divisions: 11,
            labelOf: (v) => '${(v / 1000).round()}s',
          ),
          SliderPreferenceTile(
            preference: UserPreferences.skipForwardLength,
            title: 'Skip Forward Length',
            icon: Icons.forward_30,
            min: 5000,
            max: 60000,
            divisions: 11,
            labelOf: (v) => '${(v / 1000).round()}s',
          ),
        ],
      ),
    );
  }
}
