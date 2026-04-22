import 'package:flutter/widgets.dart';

class WebYouTubeTrailer extends StatelessWidget {
  final String videoId;
  final bool muted;

  const WebYouTubeTrailer({
    super.key,
    required this.videoId,
    this.muted = true,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
