import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'book_reader_service.dart';

enum BookDocumentTheme {
  light,
  dark,
  sepia,
}

class BookDocumentService {
  static Future<Uint8List> downloadBytes(
    List<Uri> uris,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      HttpException? lastError;

      for (final uri in uris) {
        if (uri.scheme == 'file') {
          final file = File.fromUri(uri);
          if (await file.exists()) {
            return await file.readAsBytes();
          }

          lastError = HttpException('Missing local file for book data: $uri');
          continue;
        }

        final request = await client.getUrl(uri);
        headers.forEach(request.headers.add);
        final response = await request.close();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return await consolidateHttpClientResponseBytes(response);
        }

        lastError = HttpException(
          'HTTP ${response.statusCode} while downloading book data from $uri',
        );
      }

      throw lastError ?? HttpException('Failed to download book data');
    } finally {
      client.close(force: true);
    }
  }

  static Future<String?> probeExtensionFromResponse(
    List<Uri> uris,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      for (final uri in uris) {
        if (uri.scheme == 'file') {
          final fromUri = BookReaderService.extractExtensionFromFileName(
            uri.pathSegments.isEmpty ? uri.path : uri.pathSegments.last,
          );
          if (BookReaderService.isSupportedExtension(fromUri)) {
            return fromUri;
          }
          continue;
        }

        final request = await client.getUrl(uri);
        headers.forEach(request.headers.add);
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
        final response = await request.close();

        if (response.statusCode < 200 || response.statusCode >= 400) {
          await response.drain<void>();
          continue;
        }

        final disposition = response.headers.value('content-disposition');
        final mime = response.headers.contentType?.mimeType.toLowerCase();
        await response.drain<void>();

        final fromDisposition =
            BookReaderService.extractExtensionFromContentDisposition(disposition);
        if (BookReaderService.isSupportedExtension(fromDisposition)) {
          return fromDisposition;
        }

        final fromMime = BookReaderService.extensionFromMime(mime);
        if (BookReaderService.isSupportedExtension(fromMime)) {
          return fromMime;
        }

        final fromUri = BookReaderService.extractExtensionFromFileName(
          uri.pathSegments.isEmpty ? uri.path : uri.pathSegments.last,
        );
        if (BookReaderService.isSupportedExtension(fromUri)) {
          return fromUri;
        }
      }
    } finally {
      client.close(force: true);
    }

    return null;
  }

  static List<String> extractEpubChapterHtml(
    Uint8List bytes, {
    BookDocumentTheme theme = BookDocumentTheme.light,
  }) {
    return _extractEpubChapterHtmlInternal(bytes, theme: theme);
  }

  /// Parses the table of contents from an EPUB (NCX or EPUB3 nav).
  /// Returns a flat ordered list of entries. Each entry contains a human-readable
  /// [title], the [chapterIndex] matching the corresponding index into the list
  /// returned by [extractEpubChapterHtml], and a [depth] for indentation
  /// (0 = top-level, 1 = sub-section, etc.).
  /// Returns an empty list if no TOC can be found.
  static List<({String title, int chapterIndex, int depth})> extractEpubTocEntries(
    Uint8List bytes,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final files = <String, List<int>>{};
      for (final file in archive.files) {
        if (file.isFile) {
          files[file.name] = file.content;
        }
      }
      final containerBytes = files['META-INF/container.xml'];
      if (containerBytes == null) return const [];
      final opfRelPath = _parseEpubContainer(utf8.decode(containerBytes));
      final opfDir = opfRelPath.contains('/')
          ? opfRelPath.substring(0, opfRelPath.lastIndexOf('/'))
          : '';
      final opfBytes = files[opfRelPath];
      if (opfBytes == null) return const [];
      final opfStr = utf8.decode(opfBytes);

      final spine = _parseEpubOpf(opfStr);
      final hrefToIndex = <String, int>{};
      for (var i = 0; i < spine.chapterHrefs.length; i++) {
        final h = spine.chapterHrefs[i];
        hrefToIndex[h] = i;
        final basename = h.contains('/') ? h.substring(h.lastIndexOf('/') + 1) : h;
        hrefToIndex.putIfAbsent(basename, () => i);
      }

      final ncxItemMatch = RegExp(
        r'<item\b[^>]*media-type="application/x-dtbncx\+xml"[^>]*/?>',
        caseSensitive: false,
      ).firstMatch(opfStr);
      if (ncxItemMatch != null) {
        final ncxHref = RegExp(r'href="([^"]+)"')
            .firstMatch(ncxItemMatch.group(0)!)
            ?.group(1);
        if (ncxHref != null) {
          final ncxPath = opfDir.isEmpty ? ncxHref : '$opfDir/$ncxHref';
          final ncxBytes = files[ncxPath];
          if (ncxBytes != null) {
            return _parseNcxEntries(utf8.decode(ncxBytes), hrefToIndex);
          }
        }
      }

      final navItemMatch = RegExp(
        r'<item\b[^>]*properties="[^"]*\bnav\b[^"]*"[^>]*/?>',
        caseSensitive: false,
      ).firstMatch(opfStr);
      if (navItemMatch != null) {
        final navHref = RegExp(r'href="([^"]+)"')
            .firstMatch(navItemMatch.group(0)!)
            ?.group(1);
        if (navHref != null) {
          final navPath = opfDir.isEmpty ? navHref : '$opfDir/$navHref';
          final navBytes = files[navPath];
          if (navBytes != null) {
            return _parseEpub3NavEntries(utf8.decode(navBytes), hrefToIndex);
          }
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static List<({String title, int chapterIndex, int depth})> _parseNcxEntries(
    String ncx,
    Map<String, int> hrefToIndex,
  ) {
    final result = <({String title, int chapterIndex, int depth})>[];
    var depth = 0;
    String? pendingTitle;
    final tokenReg = RegExp(
      r'<navPoint\b|</navPoint\b|<text[^>]*>(.*?)</text>|<content\b[^>]+src="([^"]*)"',
      dotAll: true,
      caseSensitive: false,
    );
    for (final m in tokenReg.allMatches(ncx)) {
      final tag = m.group(0)!.toLowerCase();
      if (tag.startsWith('<navpoint') && !tag.startsWith('</')) {
        depth++;
        pendingTitle = null;
      } else if (tag.startsWith('</navpoint')) {
        if (depth > 0) depth--;
      } else if (m.group(1) != null) {
        pendingTitle = m.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      } else if (m.group(2) != null && pendingTitle != null) {
        var src = m.group(2)!;
        if (src.contains('#')) src = src.substring(0, src.indexOf('#'));
        src = Uri.decodeFull(src.trim());
        final basename = src.contains('/')
            ? src.substring(src.lastIndexOf('/') + 1)
            : src;
        final idx = hrefToIndex[src] ?? hrefToIndex[basename];
        if (idx != null && pendingTitle.isNotEmpty) {
          result.add((title: pendingTitle, chapterIndex: idx, depth: depth - 1));
        }
        pendingTitle = null;
      }
    }
    return result;
  }

  static List<({String title, int chapterIndex, int depth})> _parseEpub3NavEntries(
    String navHtml,
    Map<String, int> hrefToIndex,
  ) {
    final result = <({String title, int chapterIndex, int depth})>[];
    final tocNavStart = RegExp(
      r'<nav\b[^>]*epub:type="[^"]*toc[^"]*"',
      caseSensitive: false,
    ).firstMatch(navHtml)?.start ?? 0;
    var listDepth = 0;
    final reg = RegExp(
      r'<ol\b|</ol\b|<a\b[^>]+href="([^"]*)"[^>]*>(.*?)</a>',
      dotAll: true,
      caseSensitive: false,
    );
    for (final m in reg.allMatches(navHtml, tocNavStart)) {
      final tag = m.group(0)!.toLowerCase();
      if (tag.startsWith('<ol')) {
        listDepth++;
      } else if (tag.startsWith('</ol')) {
        if (listDepth > 0) listDepth--;
      } else if (m.group(1) != null) {
        var href = m.group(1)!;
        if (href.contains('#')) href = href.substring(0, href.indexOf('#'));
        href = Uri.decodeFull(href.trim());
        final basename = href.contains('/')
            ? href.substring(href.lastIndexOf('/') + 1)
            : href;
        final idx = hrefToIndex[href] ?? hrefToIndex[basename];
        final title = (m.group(2) ?? '')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim();
        if (idx != null && title.isNotEmpty) {
          result.add((title: title, chapterIndex: idx, depth: (listDepth - 1).clamp(0, 10)));
        }
      }
    }
    return result;
  }

  static List<String> _extractEpubChapterHtmlInternal(
    Uint8List bytes, {
    BookDocumentTheme theme = BookDocumentTheme.light,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final files = <String, List<int>>{};
    for (final file in archive.files) {
      if (file.isFile) {
        files[file.name] = file.content;
      }
    }

    final containerBytes = files['META-INF/container.xml'];
    if (containerBytes == null) {
      throw StateError('Invalid EPUB: missing META-INF/container.xml');
    }

    final opfRelPath = _parseEpubContainer(utf8.decode(containerBytes));
    final opfDir = opfRelPath.contains('/')
        ? opfRelPath.substring(0, opfRelPath.lastIndexOf('/'))
        : '';

    final opfBytes = files[opfRelPath];
    if (opfBytes == null) {
      throw StateError('Invalid EPUB: missing OPF at $opfRelPath');
    }

    final spine = _parseEpubOpf(utf8.decode(opfBytes));

    final cssBuffer = StringBuffer();
    for (final cssHref in spine.cssHrefs) {
      final cssPath = opfDir.isEmpty ? cssHref : '$opfDir/$cssHref';
      final cssBytes = files[cssPath];
      if (cssBytes != null) {
        cssBuffer.writeln(utf8.decode(cssBytes));
      }
    }

    final chapters = <String>[];
    for (final chapterHref in spine.chapterHrefs) {
      final chapterPath = opfDir.isEmpty ? chapterHref : '$opfDir/$chapterHref';
      final chapterBytes = files[chapterPath];
      if (chapterBytes == null) {
        continue;
      }

      final chapterBody = _extractHtmlBody(utf8.decode(chapterBytes));
      final sanitized = _stripLocalImages(chapterBody);
      chapters.add(_wrapEpubChapterHtml(
        cssBuffer.toString(),
        sanitized,
        theme: theme,
      ));
    }

    if (chapters.isEmpty) {
      throw StateError('Invalid EPUB: no readable chapters found in spine');
    }

    return chapters;
  }

  static String _parseEpubContainer(String xml) {
    final match = RegExp(r'full-path="([^"]+)"').firstMatch(xml);
    if (match == null) {
      throw StateError('Invalid EPUB: no rootfile in container.xml');
    }

    return match.group(1)!;
  }

  static ({List<String> chapterHrefs, List<String> cssHrefs}) _parseEpubOpf(
    String xml,
  ) {
    final manifest = <String, ({String href, String mediaType})>{};
    final itemRegex = RegExp(r'<item\b([^>]*)/?\s*>', caseSensitive: false);
    for (final m in itemRegex.allMatches(xml)) {
      final attrs = m.group(1)!;
      final id = RegExp(r'id="([^"]+)"').firstMatch(attrs)?.group(1);
      final href = RegExp(r'href="([^"]+)"').firstMatch(attrs)?.group(1);
      final mt = RegExp(r'media-type="([^"]+)"').firstMatch(attrs)?.group(1);
      if (id != null && href != null && mt != null) {
        manifest[id] = (href: Uri.decodeFull(href), mediaType: mt);
      }
    }

    final chapterHrefs = <String>[];
    final spineRegex = RegExp(
      r'<itemref\b([^>]*)/?\s*>',
      caseSensitive: false,
    );
    for (final m in spineRegex.allMatches(xml)) {
      final idref =
          RegExp(r'idref="([^"]+)"').firstMatch(m.group(1)!)?.group(1);
      if (idref != null && manifest.containsKey(idref)) {
        chapterHrefs.add(manifest[idref]!.href);
      }
    }

    final cssHrefs = manifest.values
        .where((item) => item.mediaType == 'text/css')
        .map((item) => item.href)
        .toList();

    return (chapterHrefs: chapterHrefs, cssHrefs: cssHrefs);
  }

  static String _extractHtmlBody(String html) {
    final match = RegExp(
      r'<body[^>]*>(.*)</body>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1) ?? html;
  }

  static String _stripLocalImages(String body) {
    var sanitized = body.replaceAllMapped(
      RegExp(r'<img\b[^>]*>', caseSensitive: false),
      (match) {
        final tag = match.group(0) ?? '';
        final src = RegExp(r'src="([^"]*)"', caseSensitive: false)
            .firstMatch(tag)
            ?.group(1);
        if (src == null) {
          return '';
        }

        final isRemote = src.startsWith('http://') ||
            src.startsWith('https://') ||
            src.startsWith('data:');
        return isRemote ? tag : '';
      },
    );

    sanitized = sanitized.replaceAllMapped(
      RegExp(
        r'(src|href)="(?!https?://|data:|#|mailto:)([^"]+)"',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}="#"',
    );

    return sanitized;
  }

  static String _wrapEpubChapterHtml(
    String css,
    String body, {
    required BookDocumentTheme theme,
  }) {
    final colors = switch (theme) {
      BookDocumentTheme.light => (
          background: '#fafafa',
          foreground: '#222222',
          link: '#1b4f9c',
        ),
      BookDocumentTheme.dark => (
          background: '#121212',
          foreground: '#e7e7e7',
          link: '#8ab4f8',
        ),
      BookDocumentTheme.sepia => (
          background: '#f4ecd8',
          foreground: '#3e3023',
          link: '#6b4e2a',
        ),
    };

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: Georgia, serif;
      line-height: 1.6;
      padding: 16px;
      margin: 0 auto;
      max-width: 800px;
      color: ${colors.foreground};
      background: ${colors.background};
      overflow-wrap: anywhere;
    }
    a { color: ${colors.link}; }
    img { max-width: 100%; height: auto; }
    $css
  </style>
</head>
<body>
$body
</body>
</html>''';
  }
}
