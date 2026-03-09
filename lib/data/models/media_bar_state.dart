import 'media_bar_slide_item.dart';

sealed class MediaBarState {
  const MediaBarState();
}

class MediaBarLoading extends MediaBarState {
  const MediaBarLoading();
}

class MediaBarReady extends MediaBarState {
  final List<MediaBarSlideItem> items;
  const MediaBarReady(this.items);
}

class MediaBarError extends MediaBarState {
  final String message;
  const MediaBarError(this.message);
}

class MediaBarDisabled extends MediaBarState {
  const MediaBarDisabled();
}
