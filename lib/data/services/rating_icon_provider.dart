class RatingIconProvider {
  const RatingIconProvider._();

  static String? getIconAssetPath(String source, [int? scorePercent]) {
    final file = _getIconFile(source, scorePercent);
    if (file == null) return null;
    return 'assets/icons/ratings/$file';
  }

  static String? _getIconFile(String source, int? score) {
    return switch (source) {
      'tomatoes' when score != null && score >= 75 => 'rt-certified.png',
      'tomatoes' when score != null && score < 60 => 'rt-rotten.png',
      'tomatoes' => 'rt-fresh.png',
      'tomatoes_audience' || 'popcorn' when score != null && score >= 90 =>
        'rt-verified.png',
      'tomatoes_audience' || 'popcorn' when score != null && score < 60 =>
        'rt-audience-down.png',
      'tomatoes_audience' || 'popcorn' => 'rt-audience-up.png',
      'metacritic' when score != null && score >= 81 => 'metacritic-score.png',
      'metacritic' => 'metacritic.png',
      'metacriticuser' => 'metacritic-user.png',
      'imdb' => 'imdb.png',
      'tmdb' || 'tmdb_episode' => 'tmdb.png',
      'trakt' => 'trakt.png',
      'letterboxd' => 'letterboxd.png',
      'rogerebert' => 'rogerebert.png',
      'myanimelist' => 'mal.png',
      'anilist' => 'anilist.png',
      _ => null,
    };
  }

  static String formatRating(String source, double value) {
    return switch (source) {
      'tomatoes' || 'popcorn' || 'tomatoes_audience' ||
      'tmdb' || 'metacritic' || 'metacriticuser' || 'trakt' || 'anilist' =>
        '${value.toInt()}%',
      _ => value.toStringAsFixed(1),
    };
  }

  static String sourceDisplayName(String source) {
    return switch (source) {
      'tomatoes' => 'Rotten Tomatoes',
      'tomatoes_audience' || 'popcorn' => 'RT Audience',
      'imdb' => 'IMDb',
      'tmdb' || 'tmdb_episode' => 'TMDB',
      'metacritic' => 'Metacritic',
      'metacriticuser' => 'Metacritic User',
      'trakt' => 'Trakt',
      'letterboxd' => 'Letterboxd',
      'rogerebert' => 'Roger Ebert',
      'myanimelist' => 'MyAnimeList',
      'anilist' => 'AniList',
      'stars' => 'Community Rating',
      _ => source,
    };
  }
}
