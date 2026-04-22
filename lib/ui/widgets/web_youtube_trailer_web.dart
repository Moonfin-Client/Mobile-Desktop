import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class WebYouTubeTrailer extends StatefulWidget {
  final String videoId;
  final bool muted;

  const WebYouTubeTrailer({
    super.key,
    required this.videoId,
    this.muted = true,
  });

  @override
  State<WebYouTubeTrailer> createState() => _WebYouTubeTrailerState();
}

class _WebYouTubeTrailerState extends State<WebYouTubeTrailer> {
  static final Set<String> _registeredViewTypes = <String>{};

  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'moonfin-yt-trailer-${widget.videoId}-${widget.muted ? 'm' : 'u'}';
    if (_registeredViewTypes.add(_viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int _) => _buildIframe(),
      );
    }
  }

  web.HTMLIFrameElement _buildIframe() {
    final params = <String, String>{
      'autoplay': '1',
      'mute': widget.muted ? '1' : '0',
      'controls': '0',
      'rel': '0',
      'modestbranding': '1',
      'playsinline': '1',
      'showinfo': '0',
      'iv_load_policy': '3',
      'disablekb': '1',
      'fs': '0',
      'loop': '1',
      'playlist': widget.videoId,
    };
    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final src =
        'https://www.youtube-nocookie.com/embed/${widget.videoId}?$query';

    final iframe = web.HTMLIFrameElement()
      ..src = src
      ..allow = 'autoplay; encrypted-media; picture-in-picture'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = 'none';
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('allowfullscreen', 'true');
    return iframe;
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
