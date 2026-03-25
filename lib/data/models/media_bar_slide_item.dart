class MediaBarSlideItem {
  final String itemId;
  final String serverId;
  final String title;
  final String? overview;
  final String? backdropUrl;
  final String? logoUrl;
  final String? officialRating;
  final int? year;
  final List<String> genres;
  final Duration? runtime;
  final double? communityRating;
  final int? criticRating;
  final String? tmdbId;
  final String? imdbId;
  final String itemType;
  final List<Map<String, dynamic>> remoteTrailers;
  final int localTrailerCount;

  const MediaBarSlideItem({
    required this.itemId,
    required this.serverId,
    required this.title,
    this.overview,
    this.backdropUrl,
    this.logoUrl,
    this.officialRating,
    this.year,
    this.genres = const [],
    this.runtime,
    this.communityRating,
    this.criticRating,
    this.tmdbId,
    this.imdbId,
    this.itemType = 'Movie',
    this.remoteTrailers = const [],
    this.localTrailerCount = 0,
  });
}
