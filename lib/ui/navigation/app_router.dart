import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../auth/repositories/session_repository.dart';
import '../../auth/repositories/user_repository.dart';
import '../../data/services/connectivity_service.dart';
import '../../di/injection.dart';
import '../screens/auth/emby_connect_screen.dart';
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
import '../screens/livetv/live_tv_guide_screen.dart';
import '../screens/livetv/live_tv_player_screen.dart';
import '../../data/viewmodels/live_tv_guide_view_model.dart';
import '../screens/livetv/live_tv_recordings_screen.dart';
import '../screens/livetv/live_tv_schedule_screen.dart';
import '../screens/livetv/live_tv_screen.dart';
import '../screens/livetv/live_tv_series_recordings_screen.dart';
import '../screens/playback/audio_player_screen.dart';
import '../screens/playback/book_reader_screen.dart';
import '../screens/playback/next_up_screen.dart';
import '../screens/playback/photo_player_screen.dart';
import '../screens/playback/still_watching_screen.dart';
import '../screens/playback/trailer_player_screen.dart';
import '../screens/playback/video_player_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/appearance_settings_screen.dart';
import '../screens/settings/auth_settings_screen.dart';
import '../screens/settings/customization_settings_screen.dart';
import '../screens/settings/download_settings_screen.dart';
import '../screens/settings/home_sections_screen.dart';
import '../screens/settings/home_rows_image_type_screen.dart';
import '../screens/settings/seerr_config_screen.dart';
import '../screens/settings/library_settings_screen.dart';
import '../screens/settings/media_bar_settings_screen.dart';
import '../screens/settings/plugin_settings_screen.dart';
import '../screens/settings/navigation_settings_screen.dart';
import '../screens/settings/ratings_config_screen.dart';
import '../screens/settings/parental_settings_screen.dart';
import '../screens/settings/pin_code_settings_screen.dart';
import '../screens/settings/playback_settings_screen.dart';
import '../screens/settings/screensaver_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/subtitle_settings_screen.dart';
import '../screens/admin/admin_shell_screen.dart';
import '../screens/admin/admin_content_analytics_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/users/admin_users_screen.dart';
import '../screens/admin/users/admin_user_add_screen.dart';
import '../screens/admin/users/admin_user_edit_screen.dart';
import '../screens/admin/libraries/admin_libraries_screen.dart';
import '../screens/admin/libraries/admin_library_add_screen.dart';
import '../screens/admin/libraries/admin_library_edit_screen.dart';
import '../screens/admin/tasks/admin_tasks_screen.dart';
import '../screens/admin/tasks/admin_task_detail_screen.dart';
import '../screens/admin/activity/admin_activity_screen.dart';
import '../screens/admin/settings/admin_general_settings_screen.dart';
import '../screens/admin/settings/admin_branding_screen.dart';
import '../screens/admin/settings/admin_networking_screen.dart';
import '../screens/admin/settings/admin_playback_settings_screen.dart';
import '../screens/admin/settings/admin_resume_settings_screen.dart';
import '../screens/admin/settings/admin_streaming_screen.dart';
import '../screens/admin/settings/admin_trickplay_screen.dart';
import '../screens/admin/plugins/admin_plugins_screen.dart';
import '../screens/admin/plugins/admin_plugin_detail_screen.dart';
import '../screens/admin/plugins/admin_repositories_screen.dart';
import '../screens/admin/devices/admin_devices_screen.dart';
import '../screens/admin/keys/admin_api_keys_screen.dart';
import '../screens/admin/backups/admin_backups_screen.dart';
import '../screens/admin/logs/admin_logs_screen.dart';
import '../screens/admin/logs/admin_log_viewer_screen.dart';
import '../screens/admin/livetv/admin_live_tv_screen.dart';
import '../screens/admin/metadata/admin_metadata_edit_screen.dart';
import '../screens/downloads/saved_media_screen.dart';
import '../screens/downloads/saved_album_screen.dart';
import '../screens/downloads/saved_season_screen.dart';
import '../screens/downloads/saved_series_screen.dart';
import '../screens/downloads/storage_management_screen.dart';
import 'destinations.dart';

const _authRoutes = {
  Destinations.startup,
  Destinations.serverSelect,
  Destinations.embyConnect,
  Destinations.server,
  Destinations.login,
};

bool _isOfflineAllowed(String path) {
  if (path.startsWith('/settings')) return true;
  if (path == Destinations.videoPlayer || path == Destinations.audioPlayer) {
    return true;
  }
  return false;
}

final appRouter = GoRouter(
  initialLocation: Destinations.startup,
  redirect: (context, state) {
    final path = state.uri.path;
    if (_authRoutes.contains(path)) return null;

    if (path.startsWith('/downloads')) return null;

    final session = GetIt.instance<SessionRepository>();
    if (session.activeUserId == null) return Destinations.startup;

    if (path.startsWith('/admin')) {
      final user = getIt<UserRepository>().currentUser;
      if (user == null || !user.isAdministrator) return Destinations.home;
    }

    final connectivity = GetIt.instance<ConnectivityService>();
    if (!connectivity.isOnline && !_isOfflineAllowed(path)) {
      return Destinations.downloads;
    }

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
      path: Destinations.embyConnect,
      builder: (context, state) => const EmbyConnectScreen(),
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
        scopedLibraryId: state.uri.queryParameters['libraryId'],
      ),
    ),

    // Browsing
    GoRoute(
      path: Destinations.libraryBrowse,
      builder: (context, state) {
        final libraryId = state.pathParameters['libraryId']!;
        final typesParam = state.uri.queryParameters['types'];
        final bookUiParam = state.uri.queryParameters['bookUi'];
        final includeItemTypes = typesParam
            ?.split(',')
            .map(Uri.decodeComponent)
            .toList();
        return LibraryBrowseScreen(
          libraryId: libraryId,
          includeItemTypes: includeItemTypes,
          forceBookExperience: bookUiParam == '1' ||
              bookUiParam?.toLowerCase() == 'true',
        );
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
          includeItemTypes: includeType != null ? [includeType] : null,
        );
      },
    ),

    // Item details
    GoRoute(
      path: Destinations.itemDetail,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        final serverId = state.uri.queryParameters['serverId'];
        return ItemDetailScreen(
          key: ValueKey(itemId),
          itemId: itemId,
          serverId: serverId,
        );
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
          builder: (context, state) => const LiveTvSeriesRecordingsScreen(),
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
      path: Destinations.bookReader,
      builder: (context, state) {
        final itemId = state.pathParameters['itemId']!;
        final serverId = state.uri.queryParameters['serverId'];
        final extra = state.extra as Map<String, dynamic>?;
        return BookReaderScreen(
          itemId: itemId,
          serverId: serverId,
          initialPosition: extra?['initialPosition'] as int?,
          initialMode: extra?['initialMode'] as String?,
        );
      },
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
        final url = state.uri.queryParameters['url'];
        return TrailerPlayerScreen(videoId: videoId, trailerUrl: url);
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

    // Admin
    ShellRoute(
      builder: (context, state, child) => AdminShellScreen(child: child),
      routes: [
        GoRoute(
          path: Destinations.admin,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: Destinations.adminAnalytics,
          builder: (context, state) => const AdminContentAnalyticsScreen(),
        ),
        GoRoute(
          path: Destinations.adminUsers,
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: Destinations.adminUsersAdd,
          builder: (context, state) => const AdminUserAddScreen(),
        ),
        GoRoute(
          path: Destinations.adminUsersEdit,
          builder: (context, state) =>
              AdminUserEditScreen(userId: state.pathParameters['userId']!),
        ),
        GoRoute(
          path: Destinations.adminLibraries,
          builder: (context, state) => const AdminLibrariesScreen(),
        ),
        GoRoute(
          path: Destinations.adminLibrariesAdd,
          builder: (context, state) => const AdminLibraryAddScreen(),
        ),
        GoRoute(
          path: Destinations.adminLibrariesEdit,
          builder: (context, state) => AdminLibraryEditScreen(
            libraryId: state.pathParameters['libraryId']!,
          ),
        ),
        GoRoute(
          path: Destinations.adminSettings,
          builder: (context, state) => const AdminGeneralSettingsScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsPlayback,
          builder: (context, state) => const AdminPlaybackSettingsScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsResume,
          builder: (context, state) => const AdminResumeSettingsScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsStreaming,
          builder: (context, state) => const AdminStreamingScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsTrickplay,
          builder: (context, state) => const AdminTrickplayScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsNetworking,
          builder: (context, state) => const AdminNetworkingScreen(),
        ),
        GoRoute(
          path: Destinations.adminSettingsBranding,
          builder: (context, state) => const AdminBrandingScreen(),
        ),
        GoRoute(
          path: Destinations.adminTasks,
          builder: (context, state) => const AdminTasksScreen(),
        ),
        GoRoute(
          path: Destinations.adminTasksDetail,
          builder: (context, state) =>
              AdminTaskDetailScreen(taskId: state.pathParameters['taskId']!),
        ),
        GoRoute(
          path: Destinations.adminPlugins,
          builder: (context, state) => const AdminPluginsScreen(),
        ),
        GoRoute(
          path: Destinations.adminPluginsDetail,
          builder: (context, state) => AdminPluginDetailScreen(
            pluginId: state.pathParameters['pluginId']!,
          ),
        ),
        GoRoute(
          path: Destinations.adminRepositories,
          builder: (context, state) => const AdminRepositoriesScreen(),
        ),
        GoRoute(
          path: Destinations.adminActivity,
          builder: (context, state) => const AdminActivityScreen(),
        ),
        GoRoute(
          path: Destinations.adminDevices,
          builder: (context, state) => const AdminDevicesScreen(),
        ),
        GoRoute(
          path: Destinations.adminKeys,
          builder: (context, state) => const AdminApiKeysScreen(),
        ),
        GoRoute(
          path: Destinations.adminBackups,
          builder: (context, state) => const AdminBackupsScreen(),
        ),
        GoRoute(
          path: Destinations.adminLogs,
          builder: (context, state) => const AdminLogsScreen(),
        ),
        GoRoute(
          path: Destinations.adminLogsFile,
          builder: (context, state) => AdminLogViewerScreen(
            fileName: Uri.decodeComponent(state.pathParameters['fileName']!),
          ),
        ),
        GoRoute(
          path: Destinations.adminLiveTv,
          builder: (context, state) => const AdminLiveTvScreen(),
        ),
        GoRoute(
          path: Destinations.adminMetadataEdit,
          builder: (context, state) =>
              AdminMetadataEditScreen(itemId: state.pathParameters['itemId']!),
        ),
      ],
    ),

    // Settings
    GoRoute(
      path: Destinations.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'customization',
          builder: (context, state) => const CustomizationSettingsScreen(),
        ),
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
          routes: [
            GoRoute(
              path: 'image-type',
              builder: (context, state) => const HomeRowsImageTypeScreen(),
            ),
          ],
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
          path: 'plugin',
          builder: (context, state) => const PluginSettingsScreen(),
        ),
        GoRoute(
          path: 'ratings',
          builder: (context, state) => const RatingsConfigScreen(),
        ),
        GoRoute(
          path: 'navigation',
          builder: (context, state) => const NavigationSettingsScreen(),
        ),
        GoRoute(
          path: 'downloads',
          builder: (context, state) => const DownloadSettingsScreen(),
          routes: [
            GoRoute(
              path: 'storage',
              builder: (context, state) => const StorageManagementScreen(),
            ),
          ],
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

    // Downloads / Saved Media
    GoRoute(
      path: Destinations.downloads,
      builder: (context, state) => const SavedMediaScreen(),
      routes: [
        GoRoute(
          path: 'music/:albumId',
          builder: (context, state) => SavedAlbumScreen(
            albumId: state.pathParameters['albumId']!,
            albumName: state.uri.queryParameters['name'],
          ),
        ),
        GoRoute(
          path: 'series/:seriesId',
          builder: (context, state) =>
              SavedSeriesScreen(seriesId: state.pathParameters['seriesId']!),
          routes: [
            GoRoute(
              path: 'season/:seasonId',
              builder: (context, state) => SavedSeasonScreen(
                seasonId: state.pathParameters['seasonId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
