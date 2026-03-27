// example/lib/file_browser.dart
//
// File browser widget for exploring extracted RAR contents.
// Shows a file tree on the left and file content on the right.
// Supports viewing images and text files.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents a file or directory in the file tree.
class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final List<FileNode> children;
  bool isExpanded;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    List<FileNode>? children,
    this.isExpanded = false,
  }) : children = children ?? [];

  /// Create a file tree from a flat list of file paths.
  static FileNode buildTree(List<String> paths, {String rootName = 'Archive'}) {
    final root = FileNode(
      name: rootName,
      path: '',
      isDirectory: true,
      isExpanded: true,
    );

    for (final path in paths) {
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();
      var current = root;

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isLast = i == parts.length - 1;
        final currentPath = parts.sublist(0, i + 1).join('/');

        // Check if child already exists
        var child = current.children.cast<FileNode?>().firstWhere(
          (c) => c?.name == part,
          orElse: () => null,
        );

        if (child == null) {
          // Determine if this is a directory
          // If it's not the last part, it's definitely a directory
          // If it's the last part and ends with '/', it's a directory
          final isDir = !isLast || path.endsWith('/');

          child = FileNode(name: part, path: currentPath, isDirectory: isDir);
          current.children.add(child);
        }

        current = child;
      }
    }

    // Sort children: directories first, then alphabetically
    _sortTree(root);
    return root;
  }

  static void _sortTree(FileNode node) {
    node.children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    for (final child in node.children) {
      _sortTree(child);
    }
  }
}

/// Callback for loading file content.
typedef FileContentLoader = Future<Uint8List?> Function(String path);

/// Widget for browsing files from an archive.
class FileBrowser extends StatefulWidget {
  /// The root of the file tree.
  final FileNode root;

  /// Callback to load file content.
  final FileContentLoader? onLoadContent;

  /// Title to display in the app bar.
  final String title;

  /// RAR version string to display (e.g., RAR4, RAR5).
  final String? rarVersion;

  const FileBrowser({
    super.key,
    required this.root,
    this.onLoadContent,
    this.title = 'File Browser',
    this.rarVersion,
    this.warning,
  });

  /// Warning message to display (e.g. if listing failed but extraction worked).
  final String? warning;

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  FileNode? _selectedFile;
  Uint8List? _fileContent;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      // Side-by-side layout for wider screens
      return Row(
        children: [
          // File tree
          SizedBox(width: 300, child: _buildFileTree()),
          const VerticalDivider(width: 1),
          // Content viewer
          Expanded(child: _buildContentViewer()),
        ],
      );
    } else {
      // Stacked layout for narrow screens
      return Column(
        children: [
          // File tree (collapsible)
          Expanded(flex: 2, child: _buildFileTree()),
          const Divider(height: 1),
          // Content viewer
          Expanded(flex: 3, child: _buildContentViewer()),
        ],
      );
    }
  }

  Widget _buildFileTree() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.warning != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.warning!,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.folder_open),
                const SizedBox(width: 8),
                Expanded(child: _buildHeaderTitle(context)),
                Text(
                  '${_countFiles(widget.root)} files',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Tree view
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: widget.root.children
                  .map((child) => _buildTreeNode(child, 0))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _countFiles(FileNode node) {
    var count = 0;
    for (final child in node.children) {
      if (child.isDirectory) {
        count += _countFiles(child);
      } else {
        count++;
      }
    }
    return count;
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final theme = Theme.of(context);
    final version = widget.rarVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.root.name,
          style: theme.textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        if (version != null && version.isNotEmpty)
          Text(version, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTreeNode(FileNode node, int depth) {
    final isSelected = _selectedFile == node;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _onNodeTap(node),
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 + depth * 16.0,
              top: 8,
              bottom: 8,
              right: 8,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Row(
              children: [
                // Expand/collapse icon for directories
                if (node.isDirectory)
                  Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                // File/folder icon
                Icon(
                  node.isDirectory
                      ? (node.isExpanded ? Icons.folder_open : Icons.folder)
                      : _getFileIcon(node.name),
                  size: 20,
                  color: node.isDirectory
                      ? Colors.amber
                      : _getFileIconColor(node.name),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontWeight: node.isDirectory
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Children (if expanded)
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.text_snippet;
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'c':
      case 'cpp':
      case 'h':
      case 'cs':
      case 'go':
      case 'rs':
      case 'swift':
      case 'kt':
        return Icons.code;
      case 'html':
      case 'css':
        return Icons.web;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        return Icons.archive;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'wmv':
        return Icons.video_file;
      case 'exe':
      case 'msi':
      case 'dmg':
      case 'app':
        return Icons.apps;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'dart':
        return Colors.blue;
      case 'py':
        return Colors.green;
      case 'js':
      case 'ts':
        return Colors.yellow.shade700;
      case 'html':
        return Colors.orange;
      case 'css':
        return Colors.blue.shade300;
      case 'json':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _onNodeTap(FileNode node) {
    setState(() {
      if (node.isDirectory) {
        node.isExpanded = !node.isExpanded;
      } else {
        _selectedFile = node;
        _loadContent(node);
      }
    });
  }

  Future<void> _loadContent(FileNode node) async {
    if (widget.onLoadContent == null) {
      setState(() {
        _fileContent = null;
        _error = 'Content loading not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _fileContent = null;
    });

    try {
      final content = await widget.onLoadContent!(node.path);
      setState(() {
        _fileContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildContentViewer() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              children: [
                Icon(
                  _selectedFile != null
                      ? _getFileIcon(_selectedFile!.name)
                      : Icons.preview,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFile?.name ?? 'Select a file to preview',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedFile != null && _fileContent != null)
                  Text(
                    _formatSize(_fileContent!.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildContent() {
    if (_selectedFile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a file from the tree\nto preview its contents',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (_fileContent == null) {
      return const Center(child: Text('No content available'));
    }

    // Determine content type and display accordingly
    return _buildContentView(_selectedFile!.name, _fileContent!);
  }

  Widget _buildContentView(String fileName, Uint8List content) {
    final ext = fileName.split('.').last.toLowerCase();

    // Image files
    if (_isImageExtension(ext)) {
      return _buildImageView(content);
    }

    // Text-based files
    if (_isTextExtension(ext)) {
      return _buildTextView(content);
    }

    // Binary files - show hex view
    return _buildBinaryView(content);
  }

  bool _isImageExtension(String ext) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  bool _isTextExtension(String ext) {
    return [
      'txt',
      'md',
      'json',
      'xml',
      'yaml',
      'yml',
      'csv',
      'dart',
      'py',
      'js',
      'ts',
      'java',
      'c',
      'cpp',
      'h',
      'cs',
      'go',
      'rs',
      'swift',
      'kt',
      'rb',
      'php',
      'sh',
      'bash',
      'html',
      'css',
      'scss',
      'less',
      'sql',
      'log',
      'ini',
      'cfg',
      'properties',
      'env',
      'gitignore',
      'dockerfile',
    ].contains(ext);
  }

  Widget _buildImageView(Uint8List content) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.memory(
          content,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Failed to load image: $error'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextView(Uint8List content) {
    String text;
    try {
      text = utf8.decode(content, allowMalformed: true);
    } catch (e) {
      text = latin1.decode(content);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBinaryView(Uint8List content) {
    // Show hex dump with ASCII representation
    final lines = <Widget>[];
    const bytesPerLine = 16;
    const maxLines = 100; // Limit for performance

    for (
      var i = 0;
      i < content.length && i < maxLines * bytesPerLine;
      i += bytesPerLine
    ) {
      final end = (i + bytesPerLine).clamp(0, content.length);
      final bytes = content.sublist(i, end);

      // Address
      final address = i.toRadixString(16).padLeft(8, '0');

      // Hex bytes
      final hexBytes = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      final hexPadded = hexBytes.padRight(bytesPerLine * 3 - 1);

      // ASCII representation
      final ascii = bytes.map((b) {
        if (b >= 32 && b < 127) {
          return String.fromCharCode(b);
        }
        return '.';
      }).join();

      lines.add(
        Text(
          '$address  $hexPadded  $ascii',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      );
    }

    if (content.length > maxLines * bytesPerLine) {
      lines.add(const SizedBox(height: 16));
      lines.add(
        Text(
          '... ${content.length - maxLines * bytesPerLine} more bytes',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Binary file - showing hex dump (${_formatSize(content.length)})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ...lines,
        ],
      ),
    );
  }
}

/// Page wrapper for the file browser.
class FileBrowserPage extends StatelessWidget {
  final FileNode root;
  final FileContentLoader? onLoadContent;
  final String title;

  const FileBrowserPage({
    super.key,
    required this.root,
    this.onLoadContent,
    this.title = 'File Browser',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FileBrowser(root: root, onLoadContent: onLoadContent, title: title),
    );
  }
}
