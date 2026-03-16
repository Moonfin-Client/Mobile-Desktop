import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../auth/repositories/session_repository.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/server_screen.dart';
import '../screens/auth/server_select_screen.dart';
import '../screens/auth/startup_screen.dart';
import '../screens/browse/all_genres_screen.dart';
import '../screens/browse/collection_screen.dart';
import '../screens/browse/favorites_screen.dart';
import '../screens/browse/folder_browse_screen.dart';
import '../screens/browse/folder_view_screen.dart';
import '../screens/browse/library_browse_screen.dart';
import '../screens/browse/library_genres_screen.dart';
import '../screens/browse/library_letters_screen.dart';
import '../screens/browse/library_suggestions_screen.dart';
import '../screens/browse/music_browse_screen.dart';
import '../screens/detail/item_detail_screen.dart';
import '../screens/detail/item_list_screen.dart';
import '../screens/detail/music_favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/seerr/seerr_browse_screen.dart';
import '../screens/seerr/seerr_discover_screen.dart';
import '../screens/seerr/seerr_media_detail_screen.dart';
import '../screens/seerr/seerr_person_screen.dart';
import '../screens/seerr/seerr_requests_screen.dart';
import '../screens/seerr/seerr_settings_screen.dart';
import '../screens/livetv/live_tv_guide_screen.dart';
import '../screens/livetv/live_tv_player_screen.dart';
import '../../data/viewmodels/live_tv_guide_view_model.dart';
import '../screens/livetv/live_tv_recordings_screen.dart';
import '../screens/livetv/live_tv_schedule_screen.dart';
import '../screens/livetv/live_tv_screen.dart';
import '../screens/livetv/live_tv_series_recordings_screen.dart';
import '../screens/playback/audio_player_screen.dart';
import '../screens/playback/next_up_screen.dart';
import '../screens/playback/photo_player_screen.dart';
import '../screens/playback/still_watching_screen.dart';
import '../screens/playback/trailer_player_screen.dart';
import '../screens/playback/video_player_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/appearance_settings_screen.dart';
import '../screens/settings/auth_settings_screen.dart';
import '../screens/settings/home_sections_screen.dart';
import '../screens/settings/seerr_config_screen.dart';
import '../screens/settings/library_settings_screen.dart';
import '../screens/settings/media_bar_settings_screen.dart';
import '../screens/settings/moonfin_settings_screen.dart';
import '../screens/settings/navigation_settings_screen.dart';
import '../screens/settings/parental_settings_screen.dart';
import '../screens/settings/pin_code_settings_screen.dart';
import '../screens/settings/playback_settings_screen.dart';
import '../screens/settings/screensaver_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/subtitle_settings_screen.dart';
import 'destinations.dart';

const _authRoutes = {
  Destinations.startup,
  Destinations.serverSelect,
  Destinations.server,
  Destinations.login,
};

final appRouter = GoRouter(
  initialLocation: Destinations.startup,
  redirect: (context, state) {
    final path = state.uri.path;
    if (_authRoutes.contains(path)) return null;

    final session = GetIt.instance<SessionRepository>();
    if (session.activeUserId == null) return Destinations.startup;

    return null;
  },
  routes: [
    // Auth
    GoRoute(
      path: Destinations.startup,
      builder: (context, state) => const StartupScreen(),
    ),
    GoRoute(
      path: Destinations.serverSelect,
      builder: (context, state) => const ServerSelectScreen(),
    ),
    GoRoute(
      path: Destinations.server,
      builder: (context, state) {
        final serverId = state.uri.queryParameters['serverId'] ?? '';
        return ServerScreen(serverId: serverId);
      },
    ),
    GoRoute(
      path: Destinations.login,
      builder: (context, state) {
        final serverId = state.uri.queryParameters['serverId'] ?? '';
        final username = state.uri.queryParameters['username'];
        return LoginScreen(serverId: serverId, prefillUsername: username);
      },
    ),

    // General
    GoRoute(
      path: Destinations.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Destinations.search,
      builder: (context, state) => SearchScreen(
        initialQuery: state.uri.queryParameters['query'],
      ),
    ),

    // Browsing
    GoRoute(
      path: Destinations.libraryBrowse,
      builder: (context, state) {
        final libraryId = state.pathParameters['libraryId']!;
        return LibraryBrowseScreen(libraryId: libraryId);
      },
      routes: [
        GoRoute(
          path: 'genres',
          builder: (context, state) {
            final libraryId = state.pathParameters['libraryId']!;
            return LibraryGenresScreen(libraryId: libraryId);
          },
        ),
        GoRoute(
          path: 'letters',
          builder: (context, state) {
            final libraryId = state.pathParameters['libraryId']!;
            return LibraryLettersScreen(libraryId: libraryId);
          },
        ),
        GoRoute(
          path: 'suggestions',
          builder: (context, state) {
            final libraryId = state.pathParameters['libraryId']!;
            return LibrarySuggestionsScreen(libraryId: libraryId);
          },
        ),
      ],
    ),
    GoRoute(
      path: Destinations.allGenres,
      builder: (context, state) => const AllGenresScreen(),
    ),
    GoRoute(
      path: Destinations.allFavorites,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: Destinations.folderView,
      builder: (context, state) => const FolderViewScreen(),
    ),
    GoRoute(
      path: Destinations.folderBrowse,
      builder: (context, state) {
        final folderId = state.pathParameters['folderId']!;
        return FolderBrowseScreen(folderId: folderId);
      },
    ),
    GoRoute(
      path: Destinations.collectionBrowse,
      builder: (context, state) {
        final collectionId = state.pathParameters['collectionId']!;
        return CollectionScreen(collectionId: collectionId);
      },
    ),
    GoRoute(
      path: Destinations.musicBrowse,
      builder: (context, state) {
        final libraryId = state.pathParameters['libraryId']!;
        return MusicBrowseScreen(libraryId: libraryId);
      },
    ),
    GoRoute(
      path: Destinations.genreBrowse,
      builder: (context, state) {
        final genreName = state.pathParameters['genreName']!;
        final genreId = state.uri.queryParameters['genreId']!;
        final parentId = state.uri.queryParameters['parentId'];
        final includeType = state.uri.queryParameters['includeType'];
        return LibraryBrowseScreen(
          libraryId: parentId ?? '',
          genreId: genreId,
          genreName: Uri.decodeComponent(genreName),
          includeItemTypes: includeType != null ? [includeType] : ['Movie', 'Series'],
        );
      },
    ),

    // Item details
    GoRoute(
      path: Destinations.itemDetail,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return ItemDetailScreen(key: ValueKey(itemId), itemId: itemId);
      },
      routes: [
        GoRoute(
          path: 'list',
          builder: (context, state) {
            final itemId = state.pathParameters['itemId']!;
            return ItemListScreen(itemId: itemId);
          },
        ),
      ],
    ),
    GoRoute(
      path: Destinations.musicFavorites,
      builder: (context, state) {
        final parentId = state.pathParameters['parentId']!;
        return MusicFavoritesScreen(parentId: parentId);
      },
    ),

    // Live TV
    GoRoute(
      path: Destinations.liveTv,
      builder: (context, state) => const LiveTvScreen(),
      routes: [
        GoRoute(
          path: 'guide',
          builder: (context, state) => const LiveTvGuideScreen(),
        ),
        GoRoute(
          path: 'schedule',
          builder: (context, state) => const LiveTvScheduleScreen(),
        ),
        GoRoute(
          path: 'recordings',
          builder: (context, state) => const LiveTvRecordingsScreen(),
        ),
        GoRoute(
          path: 'series-recordings',
          builder: (context, state) =>
              const LiveTvSeriesRecordingsScreen(),
        ),
        GoRoute(
          path: 'player',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return LiveTvPlayerScreen(
              channels: extra['channels'] as List<GuideChannel>,
              startIndex: extra['startIndex'] as int,
            );
          },
        ),
      ],
    ),

    // Playback
    GoRoute(
      path: Destinations.videoPlayer,
      builder: (context, state) => const VideoPlayerScreen(),
    ),
    GoRoute(
      path: Destinations.audioPlayer,
      builder: (context, state) => const AudioPlayerScreen(),
    ),
    GoRoute(
      path: Destinations.photoPlayer,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return PhotoPlayerScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: Destinations.trailerPlayer,
      builder: (context, state) {
        final videoId = state.uri.queryParameters['videoId'];
        return TrailerPlayerScreen(videoId: videoId);
      },
    ),
    GoRoute(
      path: Destinations.nextUp,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return NextUpScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: Destinations.stillWatching,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return StillWatchingScreen(itemId: itemId);
      },
    ),

    // Settings
    GoRoute(
      path: Destinations.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'playback',
          builder: (context, state) => const PlaybackSettingsScreen(),
        ),
        GoRoute(
          path: 'appearance',
          builder: (context, state) => const AppearanceSettingsScreen(),
        ),
        GoRoute(
          path: 'home-sections',
          builder: (context, state) => const HomeSectionsScreen(),
        ),
        GoRoute(
          path: 'subtitles',
          builder: (context, state) => const SubtitleSettingsScreen(),
        ),
        GoRoute(
          path: 'auth',
          builder: (context, state) => const AuthSettingsScreen(),
        ),
        GoRoute(
          path: 'pin-code',
          builder: (context, state) => const PinCodeSettingsScreen(),
        ),
        GoRoute(
          path: 'screensaver',
          builder: (context, state) => const ScreensaverSettingsScreen(),
        ),
        GoRoute(
          path: 'parental',
          builder: (context, state) => const ParentalSettingsScreen(),
        ),
        GoRoute(
          path: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: 'media-bar',
          builder: (context, state) => const MediaBarSettingsScreen(),
        ),
        GoRoute(
          path: 'library',
          builder: (context, state) => const LibrarySettingsScreen(),
        ),
        GoRoute(
          path: 'seerr-config',
          builder: (context, state) => const SeerrConfigScreen(),
        ),
        GoRoute(
          path: 'moonfin',
          builder: (context, state) => const MoonfinSettingsScreen(),
        ),
        GoRoute(
          path: 'navigation',
          builder: (context, state) => const NavigationSettingsScreen(),
        ),
      ],
    ),

    // Seerr
    GoRoute(
      path: Destinations.seerrDiscover,
      builder: (context, state) => const SeerrDiscoverScreen(),
    ),
    GoRoute(
      path: Destinations.seerrRequests,
      builder: (context, state) => const SeerrRequestsScreen(),
    ),
    GoRoute(
      path: Destinations.seerrSettings,
      builder: (context, state) => const SeerrSettingsScreen(),
    ),
    GoRoute(
      path: Destinations.seerrBrowse,
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return SeerrBrowseScreen(
          filterId: params['filterId'],
          filterName: params['filterName'],
          mediaType: params['mediaType'],
          filterType: params['filterType'],
        );
      },
    ),
    GoRoute(
      path: Destinations.seerrMediaDetail,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        return SeerrMediaDetailScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: Destinations.seerrPersonDetail,
      builder: (context, state) {
        final personId = state.pathParameters['personId']!;
        return SeerrPersonScreen(personId: personId);
      },
    ),
  ],
);
