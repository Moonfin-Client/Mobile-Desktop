List<String>? latestIncludeTypesForCollection(String? collectionType) {
  switch (collectionType) {
    case 'tvshows':
      return const ['Series'];
    case 'movies':
      return const ['Movie'];
    case 'musicvideos':
      return const ['MusicVideo'];
    case 'homevideos':
      return const ['Video'];
    default:
      return null;
  }
}
