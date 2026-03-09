class RatingIconProvider {
  const RatingIconProvider._();

  static String? getIconUrl(String baseUrl, String source, [int? scorePercent]) {
    final file = _getIconFile(source, scorePercent);
    if (file == null) return null;
    return '$baseUrl/Moonfin/Assets/$file';
  }

  static String? _getIconFile(String source, int? score) {
    return switch (source) {
      'tomatoes' when score != null && score >= 75 => 'rt-certified.svg',
      'tomatoes' when score != null && score < 60 => 'rt-rotten.svg',
      'tomatoes' => 'rt-fresh.svg',
      'tomatoes_audience' || 'popcorn' when score != null && score >= 90 =>
        'rt-verified.svg',
      'tomatoes_audience' || 'popcorn' when score != null && score < 60 =>
        'rt-audience-down.svg',
      'tomatoes_audience' || 'popcorn' => 'rt-audience-up.svg',
      'metacritic' when score != null && score >= 81 => 'metacritic-score.svg',
      'metacritic' => 'metacritic.svg',
      'metacriticuser' => 'metacritic-user.svg',
      'imdb' => 'imdb.svg',
      'tmdb' || 'tmdb_episode' => 'tmdb.svg',
      'trakt' => 'trakt.svg',
      'letterboxd' => 'letterboxd.svg',
      'rogerebert' => 'rogerebert.svg',
      'myanimelist' => 'mal.svg',
      'anilist' => 'anilist.svg',
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
}
