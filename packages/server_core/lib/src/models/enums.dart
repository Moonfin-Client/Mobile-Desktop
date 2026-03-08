enum ItemType {
  movie,
  series,
  season,
  episode,
  audio,
  musicAlbum,
  musicArtist,
  musicVideo,
  playlist,
  photo,
  photoAlbum,
  boxSet,
  channel,
  program,
  recording,
  liveTvChannel,
  liveTvProgram,
  book,
  trailer,
  person,
  studio,
  genre,
  musicGenre,
  userView,
  collectionFolder,
  folder,
  basePluginFolder,
  video,
  unknown;

  static ItemType fromServerString(String? value) => switch (value) {
        'Movie' => movie,
        'Series' => series,
        'Season' => season,
        'Episode' => episode,
        'Audio' => audio,
        'MusicAlbum' => musicAlbum,
        'MusicArtist' => musicArtist,
        'MusicVideo' => musicVideo,
        'Playlist' => playlist,
        'Photo' => photo,
        'PhotoAlbum' => photoAlbum,
        'BoxSet' => boxSet,
        'Channel' => channel,
        'Program' => program,
        'Recording' => recording,
        'TvChannel' => liveTvChannel,
        'TvProgram' => liveTvProgram,
        'Book' => book,
        'Trailer' => trailer,
        'Person' => person,
        'Studio' => studio,
        'Genre' => genre,
        'MusicGenre' => musicGenre,
        'UserView' => userView,
        'CollectionFolder' => collectionFolder,
        'Folder' => folder,
        'BasePluginFolder' => basePluginFolder,
        'Video' => video,
        _ => unknown,
      };

  String toServerString() => switch (this) {
        movie => 'Movie',
        series => 'Series',
        season => 'Season',
        episode => 'Episode',
        audio => 'Audio',
        musicAlbum => 'MusicAlbum',
        musicArtist => 'MusicArtist',
        musicVideo => 'MusicVideo',
        playlist => 'Playlist',
        photo => 'Photo',
        photoAlbum => 'PhotoAlbum',
        boxSet => 'BoxSet',
        channel => 'Channel',
        program => 'Program',
        recording => 'Recording',
        liveTvChannel => 'TvChannel',
        liveTvProgram => 'TvProgram',
        book => 'Book',
        trailer => 'Trailer',
        person => 'Person',
        studio => 'Studio',
        genre => 'Genre',
        musicGenre => 'MusicGenre',
        userView => 'UserView',
        collectionFolder => 'CollectionFolder',
        folder => 'Folder',
        basePluginFolder => 'BasePluginFolder',
        video => 'Video',
        unknown => 'Unknown',
      };
}

enum MediaType {
  video,
  audio,
  photo,
  book,
  unknown;

  static MediaType fromServerString(String? value) => switch (value) {
        'Video' => video,
        'Audio' => audio,
        'Photo' => photo,
        'Book' => book,
        _ => unknown,
      };
}

enum StreamType {
  video,
  audio,
  subtitle,
  embeddedImage,
  unknown;

  static StreamType fromServerString(String? value) => switch (value) {
        'Video' => video,
        'Audio' => audio,
        'Subtitle' => subtitle,
        'EmbeddedImage' => embeddedImage,
        _ => unknown,
      };
}

enum PersonType {
  actor,
  director,
  writer,
  producer,
  composer,
  guestStar,
  unknown;

  static PersonType fromServerString(String? value) => switch (value) {
        'Actor' => actor,
        'Director' => director,
        'Writer' => writer,
        'Producer' => producer,
        'Composer' => composer,
        'GuestStar' => guestStar,
        _ => unknown,
      };
}

enum ImageType {
  primary,
  backdrop,
  banner,
  thumb,
  logo,
  art,
  screenshot;

  static ImageType fromServerString(String? value) => switch (value) {
        'Primary' => primary,
        'Backdrop' => backdrop,
        'Banner' => banner,
        'Thumb' => thumb,
        'Logo' => logo,
        'Art' => art,
        'Screenshot' => screenshot,
        _ => primary,
      };

  String toServerString() => switch (this) {
        primary => 'Primary',
        backdrop => 'Backdrop',
        banner => 'Banner',
        thumb => 'Thumb',
        logo => 'Logo',
        art => 'Art',
        screenshot => 'Screenshot',
      };
}

enum PlayMethod {
  directPlay,
  directStream,
  transcode;

  static PlayMethod fromServerString(String? value) => switch (value) {
        'DirectPlay' => directPlay,
        'DirectStream' => directStream,
        'Transcode' => transcode,
        _ => transcode,
      };

  String toServerString() => switch (this) {
        directPlay => 'DirectPlay',
        directStream => 'DirectStream',
        transcode => 'Transcode',
      };
}
