import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive_extract/archive_extract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:rar/rar.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/offline_repository.dart';
import '../../../data/services/book_document_service.dart';
import '../../../data/services/book_reader_service.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../util/platform_detection.dart';

class BookReaderScreen extends StatefulWidget {
  final String itemId;
  final String? serverId;
  final int? initialPosition;
  final String? initialMode;

  const BookReaderScreen({
    super.key,
    required this.itemId,
    this.serverId,
    this.initialPosition,
    this.initialMode,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

enum _ReaderMode {
  web,
  comic,
  pdf,
  epub,
  fallback,
}

enum _ReaderThemeMode {
  system,
  light,
  dark,
  sepia,
}

class _BookReaderScreenState extends State<BookReaderScreen>
    with WidgetsBindingObserver {
  AggregatedItem? _item;
  String? _extension;
  String? _error;
  bool _loading = true;
  bool _loadingContent = false;
  bool _markingPlayed = false;
  _ReaderMode _mode = _ReaderMode.web;
  WebViewController? _webController;
  final PdfViewerController _pdfController = PdfViewerController();
  final PageController _pageController = PageController();
  final TransformationController _comicTransformController =
      TransformationController();
  List<ArchiveFile> _comicEntries = const [];
  final Map<int, Uint8List> _comicPageCache = {};
  int _currentComicPage = 0;
  double _comicZoom = 1.0;
  bool _twoPageSpreadEnabled = false;
  int _webLoadProgress = 0;
  String? _fallbackMessage;
  Uri? _fallbackExternalUri;
  bool _overlayVisible = true;
  Uint8List? _pdfBytes;
  int _currentPdfPage = 1;
  int _pdfPageCount = 0;
  List<String> _epubChapterHtml = const [];
  int _currentEpubChapter = 0;
  Uint8List? _epubBytes;
  final Map<BookDocumentTheme, List<String>> _epubThemeCache = {};
  Timer? _comicStateSaveDebounce;
  Timer? _pdfPageSaveDebounce;
  List<_BookmarkEntry> _bookmarks = const [];
  List<({String title, int chapterIndex, int depth})> _epubTocEntries = const [];
  List<({String title, int page, int depth})> _pdfOutline = const [];
  static const int _comicCacheRadius = 2;
  static const String _readerThemePrefKey = 'book_reader_theme_mode';
  static const String _fixedLayoutInvertPrefKey =
      'book_reader_fixed_layout_invert';
  _ReaderThemeMode _readerThemeMode = _ReaderThemeMode.system;
  bool _invertFixedLayout = false;

  bool get _supportsEmbeddedWebView {
    if (kIsWeb) {
      return false;
    }

    return PlatformDetection.isAndroid ||
        PlatformDetection.isIOS ||
        PlatformDetection.isMacOS;
  }

  bool get _supportsInAppEpub {
    if (_supportsEmbeddedWebView) {
      return true;
    }

    return !kIsWeb && (PlatformDetection.isLinux || PlatformDetection.isWindows);
  }

  bool get _supportsRarExtraction {
    if (kIsWeb) {
      return false;
    }

    return PlatformDetection.isAndroid ||
        PlatformDetection.isIOS ||
        PlatformDetection.isMacOS;
  }

  bool get _supportsCb7Extraction {
    if (kIsWeb) {
      return false;
    }

    return PlatformDetection.isAndroid ||
        PlatformDetection.isIOS ||
        PlatformDetection.isMacOS ||
        PlatformDetection.isLinux;
  }

  bool get _desktopInputEnabled => PlatformDetection.useDesktopUi;

  int get _comicPageCount => _comicEntries.length;

  bool get _twoPageSpreadActive {
    if (!_desktopInputEnabled || !_twoPageSpreadEnabled || _mode != _ReaderMode.comic) {
      return false;
    }

    final size = MediaQuery.maybeOf(context)?.size;
    if (size == null) {
      return false;
    }

    return size.width >= 1100 && size.width > size.height;
  }

  int get _comicViewportCount {
    if (_twoPageSpreadActive) {
      return (_comicPageCount + 1) ~/ 2;
    }

    return _comicPageCount;
  }

  String get _comicProgressKeyPrefix {
    final item = _item;
    if (item == null) {
      return 'book_reader_comic_unknown';
    }

    return 'book_reader_comic_${item.serverId}_${item.id}';
  }

  String get _twoPageSpreadPrefKey => 'book_reader_comic_two_page_spread';

  String get _epubProgressPrefKey {
    final item = _item;
    if (item == null) return 'book_reader_epub_unknown_chapter';
    return 'book_reader_epub_${item.serverId}_${item.id}_chapter';
  }

  String get _pdfProgressPrefKey {
    final item = _item;
    if (item == null) return 'book_reader_pdf_unknown_page';
    return 'book_reader_pdf_${item.serverId}_${item.id}_page';
  }

  String get _bookmarkPrefKey {
    final item = _item;
    if (item == null) return 'book_reader_bookmarks_unknown';
    return 'book_reader_bookmarks_${item.serverId}_${item.id}';
  }

  MediaServerClient _resolveClient() {
    final factory = GetIt.instance<MediaServerClientFactory>();
    if (widget.serverId == null) {
      return GetIt.instance<MediaServerClient>();
    }

    return factory.getClientIfExists(widget.serverId!) ??
        GetIt.instance<MediaServerClient>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadDisplayPreferences());
    _loadAndPrepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _comicStateSaveDebounce?.cancel();
    _pdfPageSaveDebounce?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _comicTransformController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_loadingContent) {
      _refreshItem();
    }
  }

  Future<void> _loadAndPrepare() async {
    await _loadItem();
    if (_item != null && _error == null) {
      await Future.wait([
        _loadBookmarks(),
        _prepareReaderContent(),
      ]);
    }
  }

  Future<void> _refreshItem() async {
    await _loadItem(isRefreshing: true);
  }

  Future<void> _loadItem({bool isRefreshing = false}) async {
    final client = _resolveClient();

    if (!isRefreshing) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final raw = await client.itemsApi.getItem(widget.itemId);
      final item = AggregatedItem(
        id: widget.itemId,
        serverId: widget.serverId ?? client.baseUrl,
        rawData: raw,
      );
      final extension = BookReaderService.detectExtension(item);

      if (extension != null && !BookReaderService.isSupportedExtension(extension)) {
        setState(() {
          _item = item;
          _extension = extension;
          _loading = false;
          _error = 'Unsupported book format: .$extension';
        });
        return;
      }

      setState(() {
        _item = item;
        _extension = extension;
        _loading = false;
        if (!isRefreshing) {
          _error = null;
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load book details: $e';
      });
    }
  }

  Future<void> _prepareReaderContent() async {
    final item = _item;
    if (item == null) {
      return;
    }

    Uri? fallbackUriCandidate;

    setState(() {
      _loadingContent = true;
      _error = null;
      _fallbackMessage = null;
      _comicEntries = const [];
      _comicPageCache.clear();
      _currentComicPage = 0;
      _comicZoom = 1.0;
      _webLoadProgress = 0;
      _webController = null;
      _fallbackExternalUri = null;
      _overlayVisible = true;
      _pdfBytes = null;
      _currentPdfPage = 1;
      _pdfPageCount = 0;
      _epubChapterHtml = const [];
      _currentEpubChapter = 0;
      _epubBytes = null;
      _epubThemeCache.clear();
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _resetComicZoom();

    try {
      final offlineRepo = GetIt.instance<OfflineRepository>();
      final offlineItem = await offlineRepo.getItem(item.id);
      final localFilePath =
          offlineItem?.downloadStatus == 2 ? offlineItem?.localFilePath : null;

      final List<Uri> uris;
      final Map<String, String> headers;
      if (localFilePath != null && await File(localFilePath).exists()) {
        final localUri = File(localFilePath).uri;
        uris = [localUri];
        headers = const {};
        fallbackUriCandidate = localUri;
      } else {
        final client = _resolveClient();
        uris = BookReaderService.buildDownloadUris(client, item);
        fallbackUriCandidate = uris.isNotEmpty ? uris.first : null;
        headers = BookReaderService.buildAuthHeaders(client);
      }

      var ext = _extension ?? '';
      if (ext.isEmpty && localFilePath != null) {
        ext = BookReaderService.extractExtensionFromFileName(localFilePath) ?? '';
      }
      if (ext.isEmpty) {
        final probedExt =
            await BookDocumentService.probeExtensionFromResponse(uris, headers);
        if (probedExt != null) {
          ext = probedExt;
          if (mounted) {
            setState(() {
              _extension = probedExt;
            });
          }
        }
      }

      if (ext == 'cbz' || ext == 'zip' || ext == 'cbt' || ext == 'cbr' || ext == 'cb7') {
        final entries = await _extractComicEntriesForExtension(uris, headers, ext);
        if (entries.isEmpty) {
          throw StateError('No image pages found inside .$ext archive.');
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _mode = _ReaderMode.comic;
          _comicEntries = entries;
        });

        await _restoreComicState();
        _primeComicCacheAround(_currentComicPage);
      } else if (ext == 'pdf') {
        final bytes = await BookDocumentService.downloadBytes(uris, headers);
        if (!mounted) return;
        setState(() {
          _mode = _ReaderMode.pdf;
          _pdfBytes = bytes;
          _currentPdfPage = 1;
          _pdfPageCount = 0;
        });
      } else if (ext == 'epub') {
        if (!_supportsInAppEpub) {
          if (!mounted) {
            return;
          }

          setState(() {
            _mode = _ReaderMode.fallback;
            _fallbackMessage =
                'EPUB rendering in-app is not available on this platform yet.';
            _fallbackExternalUri = fallbackUriCandidate;
          });
          return;
        }

        await _prepareEpubReader(uris, headers);
      } else {
        final unsupportedDoc =
            ext == 'mobi' || ext == 'azw' || ext == 'azw3';
        if (unsupportedDoc) {
          if (!mounted) return;
          setState(() {
            _mode = _ReaderMode.fallback;
            _fallbackMessage =
                'This format (.$ext) cannot be rendered in-app yet.';
            _fallbackExternalUri = uris.isNotEmpty ? uris.first : null;
          });
          return;
        }

        if (!_supportsEmbeddedWebView) {
          if (!mounted) return;
          setState(() {
            _mode = _ReaderMode.fallback;
            _fallbackMessage =
                'Embedded document rendering is unavailable on this platform.';
          });
          return;
        }

        final uri = await _resolveReadableUri(uris, headers);

        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) {
                if (!mounted) return;
                setState(() {
                  _webLoadProgress = progress;
                });
              },
              onWebResourceError: (error) {
                if (!mounted) return;
                setState(() {
                  _mode = _ReaderMode.fallback;
                  _fallbackMessage =
                      'Embedded renderer failed (${error.errorCode}): ${error.description}';
                });
              },
            ),
          );

        await controller.loadRequest(uri, headers: headers);
        if (!mounted) return;
        setState(() {
          _mode = _ReaderMode.web;
          _webController = controller;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mode = _ReaderMode.fallback;
        _fallbackMessage = 'Failed to open in-app reader: $e';
        _fallbackExternalUri = fallbackUriCandidate;
        _error = 'Failed to open in-app reader: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContent = false;
        });
      }
    }
  }

  Future<void> _openFallbackExternally() async {
    final uri = _fallbackExternalUri;
    if (uri == null) {
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open external viewer.')),
      );
    }
  }

  Future<void> _prepareEpubReader(
    List<Uri> uris,
    Map<String, String> headers,
  ) async {
    final bytes = await BookDocumentService.downloadBytes(uris, headers);
    final chapterHtml = _resolveEpubChapterHtml(bytes, _currentEpubTheme);
    final tocEntries = BookDocumentService.extractEpubTocEntries(bytes);
    if (mounted && tocEntries.isNotEmpty) {
      setState(() => _epubTocEntries = tocEntries);
    }

    if (!_supportsEmbeddedWebView && !kIsWeb && (PlatformDetection.isLinux || PlatformDetection.isWindows)) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mode = _ReaderMode.epub;
        _webController = null;
        _epubBytes = bytes;
        _epubChapterHtml = chapterHtml;
        _currentEpubChapter = 0;
        _webLoadProgress = 100;
      });
      final prefs = await SharedPreferences.getInstance();
      final initialChapter = (widget.initialMode == 'epub' && widget.initialPosition != null)
          ? widget.initialPosition!
          : (prefs.getInt(_epubProgressPrefKey) ?? 0);
      final savedChapter = initialChapter.clamp(0, chapterHtml.length - 1);
      if (savedChapter > 0 && mounted) {
        setState(() {
          _currentEpubChapter = savedChapter;
        });
      }
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_readerBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) {
              return;
            }
            setState(() {
              _webLoadProgress = progress;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _mode = _ReaderMode.fallback;
              _fallbackMessage =
                  'EPUB renderer failed (${error.errorCode}): ${error.description}';
            });
          },
        ),
      );

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = _ReaderMode.epub;
      _webController = controller;
      _epubBytes = bytes;
      _epubChapterHtml = chapterHtml;
      _currentEpubChapter = 0;
    });

    final prefs = await SharedPreferences.getInstance();
    final initialChapter = (widget.initialMode == 'epub' && widget.initialPosition != null)
        ? widget.initialPosition!
        : (prefs.getInt(_epubProgressPrefKey) ?? 0);
    final savedChapter = initialChapter.clamp(0, chapterHtml.length - 1);
    await _loadEpubChapter(savedChapter);
  }

  Future<void> _loadEpubChapter(int index) async {
    if (_epubChapterHtml.isEmpty) {
      return;
    }

    final clamped = index.clamp(0, _epubChapterHtml.length - 1);

    final controller = _webController;
    if (controller != null) {
      await controller.loadHtmlString(_epubChapterHtml[clamped]);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentEpubChapter = clamped;
      _webLoadProgress = controller == null ? 100 : 0;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_epubProgressPrefKey, clamped);
  }

  Future<void> _goToPdfPage(int targetPage) async {
    final count = _pdfPageCount;
    if (count <= 0) {
      return;
    }

    final clamped = targetPage.clamp(1, count);
    await _pdfController.goToPage(pageNumber: clamped);
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPdfPage = clamped;
    });
  }

  Future<void> _nextPdfPage() => _goToPdfPage(_currentPdfPage + 1);

  Future<void> _previousPdfPage() => _goToPdfPage(_currentPdfPage - 1);

  void _toggleOverlay() {
    setState(() {
      _overlayVisible = !_overlayVisible;
    });
    if (_overlayVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }


  Future<Uri> _resolveReadableUri(List<Uri> uris, Map<String, String> headers) async {
    final client = HttpClient();
    try {
      HttpException? lastError;

      for (final uri in uris) {
        if (uri.scheme == 'file') {
          final file = File.fromUri(uri);
          if (await file.exists()) {
            return uri;
          }

          lastError = HttpException('Missing local file for reader: $uri');
          continue;
        }

        var request = await client.openUrl('HEAD', uri);
        headers.forEach(request.headers.add);
        var response = await request.close();

        if (response.statusCode == HttpStatus.methodNotAllowed ||
            response.statusCode == HttpStatus.notImplemented) {
          await response.drain<void>();
          request = await client.getUrl(uri);
          headers.forEach(request.headers.add);
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
          response = await request.close();
        }

        if (response.statusCode >= 200 && response.statusCode < 400) {
          await response.drain<void>();
          return uri;
        }

        await response.drain<void>();
        lastError = HttpException(
          'HTTP ${response.statusCode} while opening book data from $uri',
        );
      }

      throw lastError ?? HttpException('No readable book endpoint available');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<ArchiveFile>> _extractComicEntriesForExtension(
    List<Uri> uris,
    Map<String, String> headers,
    String extension,
  ) async {
    final bytes = await BookDocumentService.downloadBytes(uris, headers);

    switch (extension) {
      case 'cbz':
      case 'zip':
      case 'cbt':
        return _extractComicEntries(bytes, extension);
      case 'cbr':
        return _extractCbrEntries(bytes);
      case 'cb7':
        return _extractCb7Entries(bytes);
      default:
        throw UnsupportedError('Unsupported comic archive format: .$extension');
    }
  }

  Future<List<ArchiveFile>> _extractCbrEntries(Uint8List bytes) async {
    final workspace = await Directory.systemTemp.createTemp('moonfin_cbr_');
    try {
      final archiveFile = File('${workspace.path}/archive.cbr');
      await archiveFile.writeAsBytes(bytes, flush: true);

      final outputDir = Directory('${workspace.path}/out');
      await outputDir.create(recursive: true);

      if (!kIsWeb && (PlatformDetection.isLinux || PlatformDetection.isWindows)) {
        await ArchiveExtract.extract7z(
          archivePath: archiveFile.path,
          destinationPath: outputDir.path,
        );
        return await _readExtractedComicEntries(outputDir);
      }

      if (!_supportsRarExtraction) {
        throw UnsupportedError(
          'CBR extraction plugin is not available on this platform.',
        );
      }

      final Map<dynamic, dynamic> result;
      try {
        result = await Rar.extractRarFile(
          rarFilePath: archiveFile.path,
          destinationPath: outputDir.path,
        );
      } on MissingPluginException {
        throw UnsupportedError(
          'CBR extraction plugin is not available on this platform.',
        );
      }

      if (result['success'] != true) {
        final message = result['message']?.toString() ?? 'Failed to extract .cbr archive.';
        throw StateError(message);
      }

      return await _readExtractedComicEntries(outputDir);
    } finally {
      await workspace.delete(recursive: true);
    }
  }

  Future<List<ArchiveFile>> _extractCb7Entries(Uint8List bytes) async {
    if (!_supportsCb7Extraction) {
      throw UnsupportedError(
        'CB7 extraction is not available on this platform.',
      );
    }

    final workspace = await Directory.systemTemp.createTemp('moonfin_cb7_');
    try {
      final archiveFile = File('${workspace.path}/archive.cb7');
      await archiveFile.writeAsBytes(bytes, flush: true);

      final outputDir = Directory('${workspace.path}/out');
      await outputDir.create(recursive: true);

      await ArchiveExtract.extract7z(
        archivePath: archiveFile.path,
        destinationPath: outputDir.path,
      );

      return await _readExtractedComicEntries(outputDir);
    } on MissingPluginException {
      throw UnsupportedError(
        'CB7 extraction plugin is not available on this platform.',
      );
    } finally {
      await workspace.delete(recursive: true);
    }
  }

  Future<List<ArchiveFile>> _readExtractedComicEntries(Directory outputDir) async {
    final files = outputDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => _isImageFileName(file.path))
        .toList()
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    final entries = <ArchiveFile>[];
    for (final file in files) {
      final data = await file.readAsBytes();
      final relativeName = file.path
          .substring(outputDir.path.length + 1)
          .replaceAll('\\', '/');
      entries.add(ArchiveFile(relativeName, data.length, data));
    }

    return entries;
  }

  List<ArchiveFile> _extractComicEntries(Uint8List bytes, String extension) {
    final archive = extension == 'cbt'
        ? TarDecoder().decodeBytes(bytes)
        : ZipDecoder().decodeBytes(bytes);

    return archive.files
        .where((file) =>
            file.isFile &&
        _isImageFileName(file.name))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  bool _isImageFileName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  Uint8List? _comicPageBytesAt(int index) {
    final cached = _comicPageCache[index];
    if (cached != null) {
      return cached;
    }

    if (index < 0 || index >= _comicEntries.length) {
      return null;
    }

    final bytes = _comicEntries[index].content;
    _comicPageCache[index] = bytes;
    _trimComicCache(index);
    return bytes;
  }

  void _primeComicCacheAround(int centerIndex) {
    for (var i = centerIndex - _comicCacheRadius;
        i <= centerIndex + _comicCacheRadius;
        i++) {
      _comicPageBytesAt(i);
    }
    _trimComicCache(centerIndex);
  }

  void _trimComicCache(int centerIndex) {
    _comicPageCache.removeWhere(
      (index, _) => (index - centerIndex).abs() > _comicCacheRadius,
    );
  }

  int _viewportFromPageIndex(int pageIndex) {
    if (_twoPageSpreadActive) {
      return pageIndex ~/ 2;
    }

    return pageIndex;
  }

  int _pageIndexFromViewport(int viewportIndex) {
    if (_twoPageSpreadActive) {
      return viewportIndex * 2;
    }

    return viewportIndex;
  }

  String _currentComicPageLabel() {
    if (_comicPageCount == 0) {
      return '0/0';
    }

    if (_twoPageSpreadActive) {
      final first = _currentComicPage + 1;
      final second = (_currentComicPage + 2).clamp(1, _comicPageCount);
      if (first == second) {
        return '$first/$_comicPageCount';
      }

      return '$first-$second/$_comicPageCount';
    }

    return '${_currentComicPage + 1}/$_comicPageCount';
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bookmarkPrefKey) ?? const [];
    final entries = raw
        .map((s) {
          try {
            return _BookmarkEntry.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<_BookmarkEntry>()
        .toList();
    if (mounted) {
      setState(() {
        _bookmarks = entries;
      });
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarkPrefKey,
      _bookmarks.map((b) => b.toJson()).toList(),
    );
  }

  String _currentPositionLabel() {
    return switch (_mode) {
      _ReaderMode.epub => 'Chapter ${_currentEpubChapter + 1}',
      _ReaderMode.pdf => 'Page $_currentPdfPage',
      _ReaderMode.comic => 'Page ${_currentComicPage + 1}',
      _ => 'Position',
    };
  }

  int _currentPositionIndex() {
    return switch (_mode) {
      _ReaderMode.epub => _currentEpubChapter,
      _ReaderMode.pdf => _currentPdfPage,
      _ReaderMode.comic => _currentComicPage,
      _ => 0,
    };
  }

  Future<void> _addCurrentBookmark() async {
    final label = _currentPositionLabel();
    final position = _currentPositionIndex();
    final mode = _mode;

    if (_bookmarks.any((b) => b.mode == mode && b.position == position)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark already saved at $label.')),
        );
      }
      return;
    }

    final entry = _BookmarkEntry(
      mode: mode,
      position: position,
      label: label,
      createdAt: DateTime.now(),
    );

    setState(() {
      _bookmarks = [..._bookmarks, entry]
        ..sort((a, b) => a.position.compareTo(b.position));
    });
    await _saveBookmarks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark added: $label')),
      );
    }
  }

  Future<void> _deleteBookmark(int index) async {
    final updated = List<_BookmarkEntry>.from(_bookmarks)..removeAt(index);
    setState(() {
      _bookmarks = updated;
    });
    await _saveBookmarks();
  }

  Future<void> _navigateToBookmark(_BookmarkEntry bookmark) async {
    Navigator.of(context).pop();
    switch (bookmark.mode) {
      case _ReaderMode.epub:
        await _loadEpubChapter(bookmark.position);
      case _ReaderMode.pdf:
        await _goToPdfPage(bookmark.position);
      case _ReaderMode.comic:
        await _goToComicPage(bookmark.position);
      default:
        break;
    }
  }

  void _showBookmarksSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2740),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmarks,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Bookmarks',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    Expanded(
                      child: _bookmarks.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No bookmarks yet.\nTap the bookmark icon while reading to save your position.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _bookmarks.length,
                              itemBuilder: (context, index) {
                                final bookmark = _bookmarks[index];
                                return ListTile(
                                  leading: const Icon(Icons.bookmark,
                                      color: Color(0xFF32B9E8), size: 20),
                                  title: Text(
                                    bookmark.label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    _formatBookmarkDate(bookmark.createdAt),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.white38, size: 20),
                                    onPressed: () async {
                                      await _deleteBookmark(index);
                                      setSheetState(() {});
                                    },
                                  ),
                                  onTap: () => _navigateToBookmark(bookmark),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatBookmarkDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showTocPanel() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Table of Contents',
      barrierColor: const Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        final media = MediaQuery.of(dialogContext);
        final panelWidth = (media.size.width * 0.38).clamp(280.0, 420.0);
        final isEmpty =
            _mode == _ReaderMode.epub ? _epubTocEntries.isEmpty : _pdfOutline.isEmpty;

        return SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: const Color(0xFF1E1E1E),
              child: SizedBox(
                width: panelWidth,
                height: media.size.height,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Table of Contents',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    Expanded(
                      child: isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No table of contents available',
                                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : (_mode == _ReaderMode.epub
                                ? _buildEpubTocList(dialogContext)
                                : _buildPdfTocList(dialogContext)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Widget _buildEpubTocList(BuildContext dialogContext) {
    return ListView.builder(
      itemCount: _epubTocEntries.length,
      itemBuilder: (context, index) {
        final entry = _epubTocEntries[index];
        return ListTile(
          contentPadding: EdgeInsets.fromLTRB(
            16.0 + (entry.depth * 12.0),
            4,
            16,
            4,
          ),
          leading: const Icon(
            Icons.description_outlined,
            color: Colors.white70,
            size: 18,
          ),
          title: Text(
            entry.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Chapter ${entry.chapterIndex + 1}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          onTap: () {
            Navigator.of(dialogContext).pop();
            _loadEpubChapter(entry.chapterIndex);
          },
        );
      },
    );
  }

  Widget _buildPdfTocList(BuildContext dialogContext) {
    return ListView.builder(
      itemCount: _pdfOutline.length,
      itemBuilder: (context, index) {
        final entry = _pdfOutline[index];
        return ListTile(
          contentPadding: EdgeInsets.fromLTRB(
            16.0 + (entry.depth * 12.0),
            4,
            16,
            4,
          ),
          leading: const Icon(
            Icons.picture_in_picture,
            color: Colors.white70,
            size: 18,
          ),
          title: Text(
            entry.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Page ${entry.page}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          onTap: () {
            Navigator.of(dialogContext).pop();
            _goToPdfPage(entry.page);
          },
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _restoreComicState() async {
    final prefs = await SharedPreferences.getInstance();
    final initialPage = (widget.initialMode == 'comic' && widget.initialPosition != null)
        ? widget.initialPosition!
        : (prefs.getInt('${_comicProgressKeyPrefix}_page') ?? 0);
    final savedPage = initialPage;
    final savedZoom = prefs.getDouble('${_comicProgressKeyPrefix}_zoom') ?? 1.0;
    final savedSpread = prefs.getBool(_twoPageSpreadPrefKey) ?? false;

    final clampedPage = savedPage.clamp(0, _comicPageCount - 1);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentComicPage = clampedPage;
      _twoPageSpreadEnabled = savedSpread;
    });

    _setComicZoom(savedZoom);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final viewport = _viewportFromPageIndex(_currentComicPage);
      _pageController.jumpToPage(viewport);
    });
  }

  Future<void> _saveComicState() async {
    final item = _item;
    if (item == null || _mode != _ReaderMode.comic) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_comicProgressKeyPrefix}_page', _currentComicPage);
    await prefs.setDouble('${_comicProgressKeyPrefix}_zoom', _comicZoom);
    await prefs.setBool(_twoPageSpreadPrefKey, _twoPageSpreadEnabled);
  }

  void _scheduleComicStateSave() {
    _comicStateSaveDebounce?.cancel();
    _comicStateSaveDebounce = Timer(const Duration(milliseconds: 250), () {
      _saveComicState();
    });
  }

  Future<void> _toggleTwoPageSpread() async {
    if (!_desktopInputEnabled) {
      return;
    }

    setState(() {
      _twoPageSpreadEnabled = !_twoPageSpreadEnabled;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_viewportFromPageIndex(_currentComicPage));
    }

    await _saveComicState();
  }

  Future<void> _goToComicPage(int target) async {
    if (_comicPageCount == 0) {
      return;
    }

    final clamped = target.clamp(0, _comicPageCount - 1);
    final normalized = _pageIndexFromViewport(_viewportFromPageIndex(clamped));
    if (normalized == _currentComicPage) {
      return;
    }

    await _pageController.animateToPage(
      _viewportFromPageIndex(clamped),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );

    if (mounted) {
      setState(() {
        _currentComicPage = normalized;
      });
    }

    await _saveComicState();
  }

  int get _comicNavigationStep => _twoPageSpreadActive ? 2 : 1;

  Future<void> _nextComicPage() => _goToComicPage(_currentComicPage + _comicNavigationStep);

  Future<void> _previousComicPage() =>
      _goToComicPage(_currentComicPage - _comicNavigationStep);

  void _resetComicZoom() {
    _setComicZoom(1.0);
  }

  void _setComicZoom(double value) {
    final clamped = value.clamp(1.0, 5.0);
    _comicTransformController.value = Matrix4.identity()
      ..scaleByDouble(clamped, clamped, clamped, 1.0);
    if (mounted) {
      setState(() {
        _comicZoom = clamped;
      });
    }

    _scheduleComicStateSave();
  }

  void _zoomComicIn() {
    _setComicZoom(_comicZoom + 0.2);
  }

  void _zoomComicOut() {
    _setComicZoom(_comicZoom - 0.2);
  }

  void _toggleComicZoom() {
    if (_comicZoom > 1.01) {
      _resetComicZoom();
    } else {
      _setComicZoom(2.2);
    }
  }

  void _handleComicPointerSignal(PointerSignalEvent event) {
    if (!_desktopInputEnabled || event is! PointerScrollEvent) {
      return;
    }

    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final zoomGesture = keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);

    if (zoomGesture) {
      if (event.scrollDelta.dy > 0) {
        _zoomComicOut();
      } else {
        _zoomComicIn();
      }
      return;
    }

    if (event.scrollDelta.dy > 0) {
      _nextComicPage();
    } else if (event.scrollDelta.dy < 0) {
      _previousComicPage();
    }
  }

  KeyEventResult _onComicKey(FocusNode _, KeyEvent event) {
    if (!_desktopInputEnabled || event is! KeyDownEvent || _mode != _ReaderMode.comic) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space) {
      _nextComicPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _previousComicPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _goToComicPage(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _goToComicPage(_comicPageCount - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _zoomComicIn();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _zoomComicOut();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      _resetComicZoom();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onReaderMenuSelected(String value) {
    switch (value) {
      case 'read':
        _setPlayed(true);
        return;
      case 'unread':
        _setPlayed(false);
        return;
      case 'reload':
        _prepareReaderContent();
        return;
      case 'view_bookmarks':
        _showBookmarksSheet();
        return;
      case 'theme-system':
        _setReaderThemeMode(_ReaderThemeMode.system);
        return;
      case 'theme-light':
        _setReaderThemeMode(_ReaderThemeMode.light);
        return;
      case 'theme-dark':
        _setReaderThemeMode(_ReaderThemeMode.dark);
        return;
      case 'theme-sepia':
        _setReaderThemeMode(_ReaderThemeMode.sepia);
        return;
      case 'invert-fixed-layout':
        _setFixedLayoutInvert(!_invertFixedLayout);
        return;
    }
  }

  Brightness get _effectiveReaderBrightness {
    return switch (_readerThemeMode) {
      _ReaderThemeMode.dark => Brightness.dark,
      _ReaderThemeMode.light => Brightness.light,
      _ReaderThemeMode.sepia => Brightness.light,
      _ReaderThemeMode.system => Theme.of(context).brightness,
    };
  }

  BookDocumentTheme get _currentEpubTheme {
    return switch (_readerThemeMode) {
      _ReaderThemeMode.dark => BookDocumentTheme.dark,
      _ReaderThemeMode.sepia => BookDocumentTheme.sepia,
      _ReaderThemeMode.light => BookDocumentTheme.light,
      _ReaderThemeMode.system =>
        _effectiveReaderBrightness == Brightness.dark
            ? BookDocumentTheme.dark
            : BookDocumentTheme.light,
    };
  }

  Color get _readerBackgroundColor {
    return switch (_readerThemeMode) {
      _ReaderThemeMode.dark => const Color(0xFF121212),
      _ReaderThemeMode.sepia => const Color(0xFFF4ECD8),
      _ReaderThemeMode.light => const Color(0xFFFAFAFA),
      _ReaderThemeMode.system => _effectiveReaderBrightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA),
    };
  }

  Future<void> _loadDisplayPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_readerThemePrefKey) ??
        _ReaderThemeMode.system.name;
    final invert = prefs.getBool(_fixedLayoutInvertPrefKey) ?? false;

    final theme = _ReaderThemeMode.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => _ReaderThemeMode.system,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _readerThemeMode = theme;
      _invertFixedLayout = invert;
    });
  }

  Future<void> _setReaderThemeMode(_ReaderThemeMode mode) async {
    if (_readerThemeMode == mode) {
      return;
    }

    setState(() {
      _readerThemeMode = mode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readerThemePrefKey, mode.name);

    if (_mode == _ReaderMode.epub) {
      await _refreshEpubTheme();
    }
  }

  Future<void> _setFixedLayoutInvert(bool value) async {
    setState(() {
      _invertFixedLayout = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fixedLayoutInvertPrefKey, value);
  }

  Future<void> _refreshEpubTheme() async {
    final bytes = _epubBytes;
    if (bytes == null || _mode != _ReaderMode.epub) {
      return;
    }

    final currentIndex = _epubChapterHtml.isEmpty
      ? 0
      : _currentEpubChapter.clamp(0, _epubChapterHtml.length - 1);
    final themed = _resolveEpubChapterHtml(bytes, _currentEpubTheme);

    if (!mounted) {
      return;
    }

    setState(() {
      _epubChapterHtml = themed;
    });

    final controller = _webController;
    if (controller != null) {
      await controller.setBackgroundColor(_readerBackgroundColor);
    }
    await _loadEpubChapter(currentIndex);
  }

  List<({String title, int page, int depth})> _flattenPdfOutline(
    List<PdfOutlineNode> nodes,
    int depth,
  ) {
    final result = <({String title, int page, int depth})>[];
    for (final node in nodes) {
      final page = node.dest?.pageNumber;
      if (page != null && page > 0) {
        result.add((title: node.title, page: page, depth: depth));
      }
      result.addAll(_flattenPdfOutline(node.children, depth + 1));
    }
    return result;
  }

  List<String> _resolveEpubChapterHtml(
    Uint8List bytes,
    BookDocumentTheme theme,
  ) {
    final cached = _epubThemeCache[theme];
    if (cached != null) {
      return cached;
    }

    final chapters = BookDocumentService.extractEpubChapterHtml(
      bytes,
      theme: theme,
    );
    _epubThemeCache[theme] = chapters;
    return chapters;
  }

  Widget _maybeInvertFixedLayout(Widget child) {
    if (!_invertFixedLayout) {
      return child;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255,
        0, -1, 0, 0, 255,
        0, 0, -1, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }

  List<PopupMenuEntry<String>> _buildReaderThemeEntries({
    bool includeFixedLayoutInvert = false,
    String invertLabel = 'Invert Colors (fixed layout)',
  }) {
    return [
      const PopupMenuDivider(),
      CheckedPopupMenuItem(
        value: 'theme-system',
        checked: _readerThemeMode == _ReaderThemeMode.system,
        child: const Text('Theme: System'),
      ),
      CheckedPopupMenuItem(
        value: 'theme-light',
        checked: _readerThemeMode == _ReaderThemeMode.light,
        child: const Text('Theme: Light'),
      ),
      CheckedPopupMenuItem(
        value: 'theme-dark',
        checked: _readerThemeMode == _ReaderThemeMode.dark,
        child: const Text('Theme: Dark'),
      ),
      CheckedPopupMenuItem(
        value: 'theme-sepia',
        checked: _readerThemeMode == _ReaderThemeMode.sepia,
        child: const Text('Theme: Sepia'),
      ),
      if (includeFixedLayoutInvert) ...[
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: 'invert-fixed-layout',
          checked: _invertFixedLayout,
          child: Text(invertLabel),
        ),
      ],
    ];
  }

  Future<void> _setPlayed(bool isPlayed) async {
    final item = _item;
    if (item == null || _markingPlayed) {
      return;
    }

    setState(() {
      _markingPlayed = true;
      _error = null;
    });

    final client = _resolveClient();

    try {
      if (isPlayed) {
        await client.userLibraryApi.markPlayed(item.id);
      } else {
        await client.userLibraryApi.unmarkPlayed(item.id);
      }

      await _refreshItem();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isPlayed ? 'Marked as read' : 'Marked as unread')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to update read state: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _markingPlayed = false;
        });
      }
    }
  }

  String _formatDuration(Duration? value) {
    if (value == null) {
      return 'Unknown';
    }

    if (value.inHours > 0) {
      final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
      return '${value.inHours}:$minutes';
    }

    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final fullscreenReader =
        _mode == _ReaderMode.comic ||
        _mode == _ReaderMode.pdf ||
        _mode == _ReaderMode.web ||
        _mode == _ReaderMode.epub;

    if (!_loading && fullscreenReader) {
      if (_mode != _ReaderMode.comic) {
        return _buildDocumentFullscreen();
      }
      return _buildComicFullscreen();
    }

    final item = _item;
    final title = item?.name ?? 'Book Reader';
    final canOpen = item != null &&
        (_extension == null || BookReaderService.isSupportedExtension(_extension));
    final playedPercentage = item?.playedPercentage;
    final playbackPosition = item?.playbackPosition;
    final hasProgress = (playedPercentage ?? 0) > 0;
    final isPlayed = item?.isPlayed ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_extension != null)
                            Chip(label: Text('Format: .$_extension')),
                          if (hasProgress)
                            Chip(
                              label: Text(
                                '${playedPercentage!.toStringAsFixed(0)}% read'
                                '${playbackPosition != null ? ' (${_formatDuration(playbackPosition)})' : ''}',
                              ),
                            )
                          else if (isPlayed)
                            const Chip(label: Text('Finished')),
                          OutlinedButton.icon(
                            onPressed: _markingPlayed
                                ? null
                                : () => _setPlayed(!isPlayed),
                            icon: _markingPlayed
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    isPlayed
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                  ),
                            label: Text(
                              _markingPlayed
                                  ? 'Updating...'
                                  : (isPlayed ? 'Mark Unread' : 'Mark as Read'),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _loadingContent || !canOpen
                                ? null
                                : _prepareReaderContent,
                            icon: _loadingContent
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Reload Reader'),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildReaderSurface()),
              ],
            ),
    );
  }

  Widget _buildComicFullscreen() {
    final item = _item;
    final title = item?.name ?? 'Book Reader';
    final isPlayed = item?.isPlayed ?? false;

    return Scaffold(
      backgroundColor: _invertFixedLayout ? Colors.white : Colors.black,
      body: _loadingContent
          ? const Center(child: CircularProgressIndicator())
          : _comicEntries.isEmpty
              ? const Center(
                  child: Text('No pages found.',
                      style: TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    Positioned.fill(
                      child: Focus(
                        autofocus: true,
                        onKeyEvent: _onComicKey,
                        child: Listener(
                          onPointerSignal: _handleComicPointerSignal,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _comicViewportCount,
                            onPageChanged: (viewportIndex) {
                              final pageIndex =
                                  _pageIndexFromViewport(viewportIndex);
                              _resetComicZoom();
                              _primeComicCacheAround(pageIndex);
                              setState(() {
                                _currentComicPage = pageIndex;
                              });
                              _saveComicState();
                            },
                            itemBuilder: (context, viewportIndex) {
                              final leftIndex =
                                  _pageIndexFromViewport(viewportIndex);
                              final leftBytes = _comicPageBytesAt(leftIndex);
                              if (leftBytes == null) {
                                return const Center(
                                  child: Text(
                                      'Failed to decode page image.',
                                      style: TextStyle(color: Colors.white)),
                                );
                              }

                              final rightIndex = _twoPageSpreadActive
                                  ? leftIndex + 1
                                  : null;
                              final rightBytes = rightIndex != null &&
                                      rightIndex < _comicPageCount
                                  ? _comicPageBytesAt(rightIndex)
                                  : null;

                              return GestureDetector(
                                onTap: _toggleOverlay,
                                onDoubleTap: _toggleComicZoom,
                                child: InteractiveViewer(
                                  transformationController:
                                      _comicTransformController,
                                  minScale: 1,
                                  maxScale: 5,
                                  onInteractionEnd: (_) {
                                    final zoom = _comicTransformController
                                        .value
                                        .getMaxScaleOnAxis();
                                    if (mounted) {
                                      setState(() {
                                        _comicZoom = zoom;
                                      });
                                    }
                                    _saveComicState();
                                  },
                                  child: _maybeInvertFixedLayout(
                                    SizedBox.expand(
                                      child: _twoPageSpreadActive
                                          ? Row(
                                              children: [
                                                Expanded(
                                                  child: _ComicPageImage(
                                                    bytes: leftBytes,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: rightBytes != null
                                                      ? _ComicPageImage(
                                                          bytes: rightBytes,
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            )
                                          : _ComicPageImage(bytes: leftBytes),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: !_overlayVisible,
                        child: AnimatedOpacity(
                          opacity: _overlayVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black87, Colors.transparent],
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    if (_epubTocEntries.isNotEmpty || _pdfOutline.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.menu_book,
                                            color: Colors.white),
                                        tooltip: 'Table of Contents',
                                        onPressed: _showTocPanel,
                                      ),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.center_focus_strong,
                                          color: Colors.white),
                                      tooltip:
                                          'Reset Zoom (${_comicZoom.toStringAsFixed(1)}x)',
                                      onPressed: _resetComicZoom,
                                    ),
                                    if (_desktopInputEnabled)
                                      IconButton(
                                        icon: Icon(
                                          _twoPageSpreadEnabled
                                              ? Icons.chrome_reader_mode
                                              : Icons.splitscreen,
                                          color: Colors.white,
                                        ),
                                        tooltip: _twoPageSpreadEnabled
                                            ? 'Single Page'
                                            : 'Two-Page Spread',
                                        onPressed: _toggleTwoPageSpread,
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        _bookmarks.isEmpty
                                            ? Icons.bookmark_add_outlined
                                            : Icons.bookmark_add,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Add Bookmark',
                                      onPressed: _addCurrentBookmark,
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.white),
                                      onSelected: _onReaderMenuSelected,
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value:
                                              isPlayed ? 'unread' : 'read',
                                          child: Text(isPlayed
                                              ? 'Mark Unread'
                                              : 'Mark as Read'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'reload',
                                          child: Text('Reload Reader'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'view_bookmarks',
                                          child: Text('Bookmarks...'),
                                        ),
                                        ..._buildReaderThemeEntries(
                                          includeFixedLayoutInvert: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: !_overlayVisible,
                        child: AnimatedOpacity(
                          opacity: _overlayVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black87, Colors.transparent],
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 8, 4, 4),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _currentComicPage > 0
                                          ? _previousComicPage
                                          : null,
                                      icon: const Icon(Icons.chevron_left,
                                          color: Colors.white),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: const SliderThemeData(
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white38,
                                          thumbColor: Colors.white,
                                          overlayColor: Colors.white24,
                                          valueIndicatorColor: Colors.white,
                                          valueIndicatorTextStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        child: Slider(
                                          value:
                                              (_viewportFromPageIndex(
                                                          _currentComicPage) +
                                                      1)
                                                  .toDouble(),
                                          min: 1,
                                          max: _comicViewportCount.toDouble(),
                                          divisions: _comicViewportCount > 1
                                              ? _comicViewportCount - 1
                                              : null,
                                          label: _currentComicPageLabel(),
                                          onChanged: (value) {
                                            final viewport =
                                                value.round() - 1;
                                            final page =
                                                _pageIndexFromViewport(
                                                    viewport);
                                            _goToComicPage(page);
                                          },
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _currentComicPage <
                                              _comicPageCount - 1
                                          ? _nextComicPage
                                          : null,
                                      icon: const Icon(Icons.chevron_right,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentComicPageLabel(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    if (_desktopInputEnabled)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: Text(
                                          'Arrows/PgUp/PgDn, +/- zoom, 0 reset',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: Colors.white70),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDocumentFullscreen() {
    final title = _item?.name ?? 'Book Reader';
    final isPlayed = _item?.isPlayed ?? false;
    final isEpub = _mode == _ReaderMode.epub;
    final isPdf = _mode == _ReaderMode.pdf;
    final chapterCount = _epubChapterHtml.length;
    final pdfPageCount = _pdfPageCount;

    return Scaffold(
      backgroundColor: _readerBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleOverlay,
              child: _buildReaderSurface(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_overlayVisible,
              child: AnimatedOpacity(
                opacity: _overlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        if (_epubTocEntries.isNotEmpty || _pdfOutline.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.menu_book, color: Colors.white),
                            tooltip: 'Table of Contents',
                            onPressed: _showTocPanel,
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _bookmarks.isEmpty
                                ? Icons.bookmark_add_outlined
                                : Icons.bookmark_add,
                            color: Colors.white,
                          ),
                          tooltip: 'Add Bookmark',
                          onPressed: _addCurrentBookmark,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: _onReaderMenuSelected,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: isPlayed ? 'unread' : 'read',
                              child: Text(isPlayed ? 'Mark Unread' : 'Mark as Read'),
                            ),
                            const PopupMenuItem(
                              value: 'reload',
                              child: Text('Reload Reader'),
                            ),
                            const PopupMenuItem(
                              value: 'view_bookmarks',
                              child: Text('Bookmarks...'),
                            ),
                            ..._buildReaderThemeEntries(
                              includeFixedLayoutInvert: isPdf,
                              invertLabel: 'Invert Colors (PDF)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isEpub && chapterCount > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _currentEpubChapter > 0
                                  ? () => _loadEpubChapter(_currentEpubChapter - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: const SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white38,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white24,
                                  valueIndicatorColor: Colors.white,
                                  valueIndicatorTextStyle: TextStyle(color: Colors.black),
                                ),
                                child: Slider(
                                  value: (_currentEpubChapter + 1).toDouble(),
                                  min: 1,
                                  max: chapterCount.toDouble(),
                                  divisions: chapterCount - 1,
                                  label: '${_currentEpubChapter + 1}/$chapterCount',
                                  onChanged: (value) {
                                    _loadEpubChapter(value.round() - 1);
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _currentEpubChapter < chapterCount - 1
                                  ? () => _loadEpubChapter(_currentEpubChapter + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentEpubChapter + 1}/$chapterCount',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (isPdf && pdfPageCount > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _currentPdfPage > 1 ? _previousPdfPage : null,
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: const SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white38,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white24,
                                  valueIndicatorColor: Colors.white,
                                  valueIndicatorTextStyle: TextStyle(color: Colors.black),
                                ),
                                child: Slider(
                                  value: _currentPdfPage.toDouble(),
                                  min: 1,
                                  max: pdfPageCount.toDouble(),
                                  divisions: pdfPageCount - 1,
                                  label: '$_currentPdfPage/$pdfPageCount',
                                  onChanged: (value) {
                                    _goToPdfPage(value.round());
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _currentPdfPage < pdfPageCount ? _nextPdfPage : null,
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_currentPdfPage/$pdfPageCount',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReaderSurface() {
    if (_loadingContent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Preparing in-app reader...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_mode == _ReaderMode.pdf) {
      final bytes = _pdfBytes;
      if (bytes == null) {
        return const Center(child: Text('PDF data not available.'));
      }
      return ColoredBox(
        color: _readerBackgroundColor,
        child: _maybeInvertFixedLayout(
          PdfViewer.data(
            bytes,
            sourceName: 'book.pdf',
            controller: _pdfController,
            params: PdfViewerParams(
              onViewerReady: (document, controller) async {
                if (!mounted) {
                  return;
                }
                final pageCount = controller.pageCount;
                final prefs = await SharedPreferences.getInstance();
                final initialPage = (widget.initialMode == 'pdf' && widget.initialPosition != null)
                    ? widget.initialPosition!
                    : (prefs.getInt(_pdfProgressPrefKey) ?? 1);
                final savedPage = initialPage.clamp(1, pageCount);
                final outline = await document.loadOutline();
                if (mounted) {
                  final flat = _flattenPdfOutline(outline, 0);
                  setState(() {
                    _pdfPageCount = pageCount;
                    _currentPdfPage = savedPage;
                    if (flat.isNotEmpty) _pdfOutline = flat;
                  });
                }
                if (savedPage > 1) {
                  await controller.goToPage(pageNumber: savedPage);
                }
              },
              onPageChanged: (pageNumber) {
                if (!mounted || pageNumber == null) {
                  return;
                }
                setState(() {
                  _currentPdfPage = pageNumber;
                });
                _pdfPageSaveDebounce?.cancel();
                _pdfPageSaveDebounce =
                    Timer(const Duration(milliseconds: 300), () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(_pdfProgressPrefKey, pageNumber);
                });
              },
            ),
          ),
        ),
      );
    }

    if (_mode == _ReaderMode.fallback) {
      final ext = _extension == null ? '' : '.$_extension';
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.desktop_windows_outlined, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Reader fallback mode active',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _fallbackMessage ??
                      'This platform cannot host the embedded document engine for $ext files.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Reload Reader after switching to a supported platform target (Android, iOS, macOS).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_fallbackExternalUri != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openFallbackExternally,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Externally'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_mode == _ReaderMode.epub && (!_supportsEmbeddedWebView && !kIsWeb && (PlatformDetection.isLinux || PlatformDetection.isWindows))) {
      if (_epubChapterHtml.isEmpty) {
        return const Center(child: Text('No EPUB chapters found.'));
      }

      final chapter = _epubChapterHtml[
          _currentEpubChapter.clamp(0, _epubChapterHtml.length - 1)];

      return SingleChildScrollView(
        key: ValueKey<String>('epub-${_readerThemeMode.name}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: HtmlWidget(
          chapter,
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final controller = _webController;
    if (controller == null) {
      return Center(
        child: Text(_error ?? 'Reader not ready.'),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_webLoadProgress < 100)
          Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(value: _webLoadProgress / 100),
          ),
      ],
    );
  }
}

class _BookmarkEntry {
  final _ReaderMode mode;
  final int position;
  final String label;
  final DateTime createdAt;

  const _BookmarkEntry({
    required this.mode,
    required this.position,
    required this.label,
    required this.createdAt,
  });

  String toJson() {
    return '{"mode":"${mode.name}","position":$position,"label":${_jsonString(label)},"createdAt":"${createdAt.toIso8601String()}"}';
  }

  static String _jsonString(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  factory _BookmarkEntry.fromJson(String raw) {
    final map = <String, dynamic>{};
    // minimal hand-parsed JSON for the simple flat structure we write
    final clean = raw.trim();
    final pairs = RegExp(r'"(\w+)"\s*:\s*(?:"([^"]*)"|([\d]+))')
        .allMatches(clean);
    for (final m in pairs) {
      final key = m.group(1)!;
      final strVal = m.group(2);
      final numVal = m.group(3);
      map[key] = strVal ?? int.parse(numVal!);
    }
    final modeName = map['mode'] as String? ?? 'epub';
    final mode = _ReaderMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => _ReaderMode.epub,
    );
    return _BookmarkEntry(
      mode: mode,
      position: map['position'] as int? ?? 0,
      label: map['label'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class _ComicPageImage extends StatelessWidget {
  final Uint8List bytes;

  const _ComicPageImage({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      ),
    );
  }
}
