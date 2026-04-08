import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class AdminMetadataEditScreen extends StatefulWidget {
  final String itemId;

  const AdminMetadataEditScreen({super.key, required this.itemId});

  @override
  State<AdminMetadataEditScreen> createState() =>
      _AdminMetadataEditScreenState();
}

class _AdminMetadataEditScreenState extends State<AdminMetadataEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ItemsApi _itemsApi;
  late final AdminItemsApi _api;
  late final ImageApi _imageApi;

  bool _loading = true;
  bool _saving = false;
  ImageType? _busyImageType;
  String? _error;

  Map<String, dynamic> _raw = const {};
  Map<String, dynamic> _editorInfo = const {};
  List<Map<String, dynamic>> _externalIds = const [];

  final _nameController = TextEditingController();
  final _sortNameController = TextEditingController();
  final _originalTitleController = TextEditingController();
  final _premiereDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _productionYearController = TextEditingController();
  final _officialRatingController = TextEditingController();
  final _communityRatingController = TextEditingController();
  final _criticRatingController = TextEditingController();
  final _taglineController = TextEditingController();
  final _overviewController = TextEditingController();

  List<String> _genres = [];
  List<String> _tags = [];
  List<String> _studios = [];
  List<Map<String, String>> _people = const [];

  final Map<String, TextEditingController> _externalControllers = {};

  @override
  void initState() {
    super.initState();
    _itemsApi = GetIt.instance<MediaServerClient>().itemsApi;
    _api = GetIt.instance<MediaServerClient>().adminItemsApi;
    _imageApi = GetIt.instance<MediaServerClient>().imageApi;
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _sortNameController.dispose();
    _originalTitleController.dispose();
    _premiereDateController.dispose();
    _endDateController.dispose();
    _productionYearController.dispose();
    _officialRatingController.dispose();
    _communityRatingController.dispose();
    _criticRatingController.dispose();
    _taglineController.dispose();
    _overviewController.dispose();
    for (final c in _externalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await Future.wait<dynamic>([
        _itemsApi.getItem(widget.itemId),
        _api.getMetadataEditor(widget.itemId),
      ]);
      final raw = result[0] as Map<String, dynamic>;
      final editorInfo = result[1] as Map<String, dynamic>;
      final external = _asMapList(editorInfo['ExternalIdInfos']);

      if (!mounted) return;
      _hydrate(raw, external);
      setState(() {
        _raw = raw;
        _editorInfo = editorInfo;
        _externalIds = external;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _hydrate(Map<String, dynamic> raw, List<Map<String, dynamic>> external) {
    _nameController.text = (raw['Name'] ?? '').toString();
    _sortNameController.text =
        (raw['SortName'] ?? raw['ForcedSortName'] ?? '').toString();
    _originalTitleController.text = (raw['OriginalTitle'] ?? '').toString();
    _premiereDateController.text = _dateOnly(raw['PremiereDate']);
    _endDateController.text = _dateOnly(raw['EndDate']);
    _productionYearController.text = (raw['ProductionYear'] ?? '').toString();
    _officialRatingController.text = (raw['OfficialRating'] ?? '').toString();
    _communityRatingController.text = (raw['CommunityRating'] ?? '').toString();
    _criticRatingController.text = (raw['CriticRating'] ?? '').toString();
    _taglineController.text =
        _firstString(raw['Taglines']) ?? (raw['Tagline'] ?? '').toString();
    _overviewController.text = (raw['Overview'] ?? '').toString();

    _genres = _stringList(raw['Genres']);
    _tags = _stringList(raw['Tags']);
    _studios = _nameList(raw['Studios']);

    final peopleRaw = raw['People'];
    if (peopleRaw is List) {
      _people =
          peopleRaw
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .map(
                (e) => {
                  'Name': (e['Name'] ?? '').toString(),
                  'Role': (e['Role'] ?? '').toString(),
                  'Type': (e['Type'] ?? '').toString(),
                },
              )
              .toList();
    } else {
      _people = const [];
    }

    final providerIds =
        raw['ProviderIds'] is Map
            ? (raw['ProviderIds'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

    for (final c in _externalControllers.values) {
      c.dispose();
    }
    _externalControllers.clear();
    for (final idInfo in external) {
      final key = _externalKey(idInfo);
      final value = (providerIds[key] ?? '').toString();
      _externalControllers[key] = TextEditingController(text: value);
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }

  List<String> _nameList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e is Map ? (e['Name'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  String _dateOnly(dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String? _dateValue(String property, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final current = (_raw[property] ?? '').toString();
    if (current.length >= 10 && current.substring(0, 10) == trimmed) {
      return current;
    }

    return trimmed;
  }

  String? _nullIfEmpty(String s) => s.isEmpty ? null : s;

  String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first?.toString() ?? '';
      return first.isEmpty ? null : first;
    }
    return null;
  }

  String _externalKey(Map<String, dynamic> idInfo) {
    return (idInfo['Key'] ?? idInfo['Name'] ?? idInfo['Type'] ?? '').toString();
  }

  String _externalLabel(Map<String, dynamic> idInfo) {
    return (idInfo['DisplayName'] ??
            idInfo['Key'] ??
            idInfo['Name'] ??
            idInfo['Type'] ??
            '')
        .toString();
  }

  List<Map<String, dynamic>> _contentTypeOptions() {
    return _asMapList(_editorInfo['ContentTypeOptions']);
  }

  List<Map<String, String>> _fallbackContentTypeOptions() {
    return const [
      {'Value': '', 'Name': 'Default'},
      {'Value': 'movies', 'Name': 'Movies'},
      {'Value': 'music', 'Name': 'Music'},
      {'Value': 'tvshows', 'Name': 'Shows'},
      {'Value': 'books', 'Name': 'Books'},
      {'Value': 'homevideos', 'Name': 'Home Videos & Photos'},
      {'Value': 'musicvideos', 'Name': 'Music Videos'},
      {'Value': 'mixed', 'Name': 'Mixed Movies & Shows'},
    ];
  }

  List<Map<String, String>> _resolvedContentTypeOptions(String currentType) {
    final fromEditor =
        _contentTypeOptions()
            .map(
              (option) => {
                'Value': (option['Value'] ?? '').toString(),
                'Name': (option['Name'] ?? option['Value'] ?? '').toString(),
              },
            )
            .toList();

    final options =
        fromEditor.isNotEmpty ? fromEditor : _fallbackContentTypeOptions();
    if (currentType.isNotEmpty &&
        options.every((option) => option['Value'] != currentType)) {
      return [
        ...options,
        {'Value': currentType, 'Name': currentType},
      ];
    }
    return options;
  }

  String _imageUrl(ImageType type) {
    final tag = _imageTag(type);
    return switch (type) {
      ImageType.primary => _imageApi.getPrimaryImageUrl(
        widget.itemId,
        maxWidth: 600,
        tag: tag,
      ),
      ImageType.backdrop => _imageApi.getBackdropImageUrl(
        widget.itemId,
        maxWidth: 900,
        tag: tag,
      ),
      ImageType.logo => _imageApi.getLogoImageUrl(
        widget.itemId,
        maxWidth: 400,
        tag: tag,
      ),
      ImageType.banner => _imageApi.getBannerImageUrl(
        widget.itemId,
        maxWidth: 900,
        tag: tag,
      ),
      ImageType.thumb => _imageApi.getThumbImageUrl(
        widget.itemId,
        maxWidth: 500,
        tag: tag,
      ),
      _ => '',
    };
  }

  String? _imageTag(ImageType type) {
    final imageTags = _raw['ImageTags'];
    if (imageTags is Map) {
      final mapTag = imageTags[type.toServerString()];
      if (mapTag != null && mapTag.toString().isNotEmpty) {
        return mapTag.toString();
      }
    }

    final directTag = _raw['${type.toServerString()}ImageTag'];
    if (directTag != null && directTag.toString().isNotEmpty) {
      return directTag.toString();
    }

    final indexedTags = _raw['${type.toServerString()}ImageTags'];
    if (indexedTags is List && indexedTags.isNotEmpty) {
      final first = indexedTags.first?.toString() ?? '';
      if (first.isNotEmpty) {
        return first;
      }
    }

    return null;
  }

  String? _contentTypeForFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      _ => null,
    };
  }

  Future<void> _runImageAction(
    ImageType type,
    Future<void> Function() action,
  ) async {
    setState(() => _busyImageType = type);
    try {
      await action();
      await _load();
    } finally {
      if (mounted) {
        setState(() => _busyImageType = null);
      }
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final sortName = _sortNameController.text.trim();
    final tagline = _taglineController.text.trim();

    final update = <String, dynamic>{
      ..._raw,
      'Name': _nameController.text.trim(),
      'ForcedSortName': _nullIfEmpty(sortName),
      'OriginalTitle': _originalTitleController.text.trim(),
      'PremiereDate': _dateValue('PremiereDate', _premiereDateController.text),
      'EndDate': _dateValue('EndDate', _endDateController.text),
      'ProductionYear':
          int.tryParse(_productionYearController.text.trim()) ??
          _raw['ProductionYear'],
      'OfficialRating': _officialRatingController.text.trim(),
      'CommunityRating':
          double.tryParse(_communityRatingController.text.trim()) ??
          _raw['CommunityRating'],
      'CriticRating':
          double.tryParse(_criticRatingController.text.trim()) ??
          _raw['CriticRating'],
      'Taglines': tagline.isEmpty ? <String>[] : [tagline],
      'Overview': _overviewController.text.trim(),
      'Genres': _genres,
      'Tags': _tags,
      'Studios': _studios.map((s) => {'Name': s}).toList(),
      'People': _people,
      'ProviderIds': Map<String, String>.fromEntries(
        _externalIds.map((info) {
          final key = _externalKey(info);
          return MapEntry(key, _externalControllers[key]?.text.trim() ?? '');
        }),
      ),
    };

    setState(() => _saving = true);
    try {
      await _api.updateItem(widget.itemId, update);
      if (!mounted) return;
      setState(() {
        _raw = update;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataSaved)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataSaveFailed(e.toString()))));
    }
  }

  Future<void> _refreshMetadata() async {
    final l10n = AppLocalizations.of(context);
    var recursive = false;
    var replaceAllMetadata = false;
    var replaceAllImages = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateDialog) => AlertDialog(
                  title: Text(l10n.adminRefreshMetadata),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        value: recursive,
                        onChanged:
                            (v) => setStateDialog(() => recursive = v ?? false),
                        title: Text(l10n.adminMetadataRecursive),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: replaceAllMetadata,
                        onChanged:
                            (v) => setStateDialog(
                              () => replaceAllMetadata = v ?? false,
                            ),
                        title: Text(l10n.adminReplaceAllMetadata),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: replaceAllImages,
                        onChanged:
                            (v) => setStateDialog(
                              () => replaceAllImages = v ?? false,
                            ),
                        title: Text(l10n.adminReplaceAllImages),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.refresh),
                    ),
                  ],
                ),
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.refreshItem(
        widget.itemId,
        recursive: recursive,
        replaceAllMetadata: replaceAllMetadata,
        replaceAllImages: replaceAllImages,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMetadataRefreshRequested)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataRefreshFailed(e.toString()))));
    }
  }

  Future<void> _searchAndApplyRemote() async {
    final l10n = AppLocalizations.of(context);
    final queryController = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.adminSearchRemotePerson),
            content: TextField(
              controller: queryController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(ctx, queryController.text.trim()),
                child: Text(l10n.search),
              ),
            ],
          ),
    );
    queryController.dispose();

    if (query == null || query.isEmpty || !mounted) return;

    try {
      final results = await _api.searchRemotePerson({
        'SearchInfo': {'Name': query},
        'ItemId': widget.itemId,
      });

      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminNoRemoteMatches)),
        );
        return;
      }

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(l10n.adminRemoteResults),
              content: SizedBox(
                width: (MediaQuery.sizeOf(ctx).width - 32).clamp(280.0, 560.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final name =
                        (item['Name'] ?? item['SearchHint'] ?? 'Unknown')
                            .toString();
                    final provider =
                        (item['ProviderName'] ?? item['Provider'] ?? '')
                            .toString();
                    return ListTile(
                      title: Text(name),
                      subtitle: provider.isEmpty ? null : Text(provider),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
      );

      if (selected == null || !mounted) return;
      await _api.applyRemoteSearchResult(widget.itemId, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminRemoteMetadataApplied)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminRemoteSearchFailed(e.toString()))));
    }
  }

  Future<void> _addChip(String title, List<String> target) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: Text(l10n.add),
              ),
            ],
          ),
    );
    controller.dispose();

    if (value == null || !mounted) return;
    setState(() {
      if (!target.contains(value)) {
        target.add(value);
      }
    });
  }

  Future<void> _editPerson({int? index}) async {
    final l10n = AppLocalizations.of(context);
    final existing = index == null ? null : _people[index];
    final nameController = TextEditingController(text: existing?['Name'] ?? '');
    final roleController = TextEditingController(text: existing?['Role'] ?? '');
    final typeController = TextEditingController(
      text: existing?['Type'] ?? 'Actor',
    );

    final person = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(index == null ? l10n.adminMetadataAddPerson : l10n.adminMetadataEditPerson),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      labelText: l10n.adminMetadataRole,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: l10n.adminMetadataType,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    Navigator.pop(ctx);
                    return;
                  }
                  Navigator.pop(ctx, {
                    'Name': name,
                    'Role': roleController.text.trim(),
                    'Type': typeController.text.trim(),
                  });
                },
                child: Text(index == null ? l10n.add : l10n.save),
              ),
            ],
          ),
    );

    nameController.dispose();
    roleController.dispose();
    typeController.dispose();

    if (person == null || !mounted) return;
    setState(() {
      if (index == null) {
        _people = [..._people, person];
      } else {
        final next = [..._people];
        next[index] = person;
        _people = next;
      }
    });
  }

  Future<void> _changeContentType() async {
    final l10n = AppLocalizations.of(context);
    final currentType = (_editorInfo['ContentType'] ?? '').toString();
    final options = _resolvedContentTypeOptions(currentType);
    var selectedValue = currentType;

    if (selectedValue.isEmpty && options.isNotEmpty) {
      selectedValue = options.first['Value'] ?? '';
    }

    final value = await showDialog<String>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateDialog) => AlertDialog(
                  title: Text(l10n.adminUpdateContentType),
                  content: DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: InputDecoration(
                      labelText: l10n.adminContentType,
                      border: const OutlineInputBorder(),
                    ),
                    items:
                        options.map((option) {
                          final optionValue = option['Value'] ?? '';
                          final optionName = option['Name'] ?? optionValue;
                          return DropdownMenuItem<String>(
                            value: optionValue,
                            child: Text(
                              optionName.isEmpty ? l10n.adminMetadataDefault : optionName,
                            ),
                          );
                        }).toList(),
                    onChanged: (next) {
                      setStateDialog(() => selectedValue = next ?? '');
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, selectedValue),
                      child: Text(l10n.adminMetadataUpdate),
                    ),
                  ],
                ),
          ),
    );

    if (value == null || value.isEmpty || !mounted) return;
    try {
      await _api.updateContentType(widget.itemId, value);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataContentTypeUpdated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminMetadataContentTypeFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactHeader = screenWidth < 920;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminMetadataLoadFailed(_error!), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child:
              compactHeader
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminMetadataEditorTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _refreshMetadata,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.refresh),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _searchAndApplyRemote,
                            icon: const Icon(Icons.travel_explore),
                            label: Text(l10n.adminMetadataRemote),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _changeContentType,
                            icon: const Icon(Icons.category_outlined),
                            label: Text(l10n.adminMetadataType),
                          ),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.save),
                            label: Text(l10n.save),
                          ),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.adminMetadataEditorTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _refreshMetadata,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _searchAndApplyRemote,
                        icon: const Icon(Icons.travel_explore),
                        label: Text(l10n.adminMetadataRemote),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _changeContentType,
                        icon: const Icon(Icons.category_outlined),
                        label: Text(l10n.adminMetadataType),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.general),
            Tab(text: l10n.adminMetadataDetails),
            Tab(text: l10n.adminMetadataExternalIds),
            Tab(text: l10n.adminMetadataImages),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralTab(),
              _buildDetailsTab(),
              _buildExternalTab(),
              _buildImagesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_nameController, l10n.adminMetadataFieldTitle),
        const SizedBox(height: 12),
        _field(_sortNameController, l10n.adminMetadataFieldSortTitle),
        const SizedBox(height: 12),
        _field(_originalTitleController, l10n.adminMetadataFieldOriginalTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _premiereDateController,
                l10n.adminMetadataFieldPremiereDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_endDateController, l10n.adminMetadataFieldEndDate),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _productionYearController,
                l10n.adminMetadataFieldProductionYear,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_officialRatingController, l10n.adminMetadataFieldOfficialRating),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _communityRatingController,
                l10n.adminMetadataFieldCommunityRating,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _criticRatingController,
                l10n.adminMetadataFieldCriticRating,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_taglineController, l10n.adminMetadataFieldTagline),
        const SizedBox(height: 12),
        _field(_overviewController, l10n.adminMetadataFieldOverview, maxLines: 8),
      ],
    );
  }

  Widget _buildDetailsTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _chipEditor(l10n.adminMetadataGenres, _genres, () => _addChip(l10n.adminMetadataAddGenre, _genres)),
        const SizedBox(height: 12),
        _chipEditor(l10n.adminMetadataTags, _tags, () => _addChip(l10n.adminMetadataAddTag, _tags)),
        const SizedBox(height: 12),
        _chipEditor(
          l10n.adminMetadataStudios,
          _studios,
          () => _addChip(l10n.adminMetadataAddStudio, _studios),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.adminMetadataPeople,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _editPerson(),
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_people.isEmpty)
          Text(l10n.adminNoPeopleEntries)
        else
          ..._people.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final name = p['Name'] ?? '';
            final role = p['Role'] ?? '';
            final type = p['Type'] ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              subtitle: Text(
                [role, type].where((e) => e.isNotEmpty).join(' • '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editPerson(index: i),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final next = [..._people];
                        next.removeAt(i);
                        _people = next;
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExternalTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_externalIds.isEmpty)
          Text(l10n.adminNoExternalIds)
        else
          ..._externalIds.map((info) {
            final key = _externalKey(info);
            final label = _externalLabel(info);
            final controller =
                _externalControllers[key] ??
                (_externalControllers[key] = TextEditingController());
            final url =
                (info['UrlFormatString'] ?? info['Url'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(controller, label),
                  if (url.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        url,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildImagesTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _imageCard(
          ImageType.primary,
          l10n.adminMetadataImagePrimary,
          _imageUrl(ImageType.primary),
          aspectRatio: 2 / 3,
          maxPreviewWidth: 200,
        ),
        const SizedBox(height: 12),
        _imageCard(
          ImageType.backdrop,
          l10n.adminMetadataImageBackdrop,
          _imageUrl(ImageType.backdrop),
          aspectRatio: 16 / 9,
        ),
        const SizedBox(height: 12),
        _imageCard(
          ImageType.logo,
          l10n.adminMetadataImageLogo,
          _imageUrl(ImageType.logo),
          aspectRatio: 16 / 5,
          maxPreviewWidth: 400,
        ),
        const SizedBox(height: 12),
        _imageCard(
          ImageType.banner,
          l10n.adminMetadataImageBanner,
          _imageUrl(ImageType.banner),
          aspectRatio: 5 / 1,
        ),
        const SizedBox(height: 12),
        _imageCard(
          ImageType.thumb,
          l10n.adminMetadataImageThumb,
          _imageUrl(ImageType.thumb),
          aspectRatio: 16 / 9,
          maxPreviewWidth: 320,
        ),
      ],
    );
  }

  Widget _imageCard(
    ImageType imageType,
    String label,
    String url, {
    double aspectRatio = 16 / 9,
    double maxPreviewWidth = double.infinity,
  }) {
    final l10n = AppLocalizations.of(context);
    final busy = _busyImageType == imageType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxPreviewWidth),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: busy ? null : () => _searchRemoteImage(imageType),
                  child: Text(l10n.search),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : () => _uploadImage(imageType),
                  child: Text(l10n.adminMetadataUpload),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : () => _deleteImage(imageType),
                  child: Text(l10n.delete),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchRemoteImage(ImageType imageType) async {
    final l10n = AppLocalizations.of(context);
    try {
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (ctx) => _RemoteImagePickerDialog(
              api: _api,
              itemId: widget.itemId,
              imageType: imageType,
            ),
      );

      final imageUrl = (selected?['Url'] ?? '').toString();
      if (imageUrl.isEmpty || !mounted) {
        return;
      }

      await _runImageAction(imageType, () async {
        await _api.downloadRemoteImage(
          widget.itemId,
          imageType: imageType,
          imageUrl: imageUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminMetadataImageUpdated(imageType.toServerString())),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataImageDownloadFailed(e.toString()))));
    }
  }

  Future<void> _uploadImage(ImageType imageType) async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    final file = result.files.single;
    final contentType = _contentTypeForFileName(file.name);
    if (contentType == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminUnsupportedImageFormat)),
      );
      return;
    }

    final bytes =
        file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (!mounted) return;

    if (bytes == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminMetadataImageReadFailed)),
      );
      return;
    }

    try {
      await _runImageAction(imageType, () async {
        await _api.uploadItemImage(
          widget.itemId,
          imageType: imageType,
          bytes: bytes,
          contentType: contentType,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.adminMetadataImageUploaded(imageType.toServerString())),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminMetadataImageUploadFailed(e.toString()))),
      );
    }
  }

  Future<void> _deleteImage(ImageType imageType) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.adminMetadataDeleteImageTitle(imageType.toServerString())),
            content: Text(
              l10n.adminMetadataDeleteImageContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _runImageAction(imageType, () async {
        await _api.deleteItemImage(widget.itemId, imageType: imageType);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminMetadataImageDeleted(imageType.toServerString())),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminMetadataImageDeleteFailed(e.toString()))));
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _chipEditor(String label, List<String> values, VoidCallback onAdd) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (values.isEmpty)
              Text(l10n.none)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    values
                        .map(
                          (value) => Chip(
                            label: Text(value),
                            onDeleted: () {
                              setState(() {
                                values.remove(value);
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RemoteImagePickerDialog extends StatefulWidget {
  final AdminItemsApi api;
  final String itemId;
  final ImageType imageType;

  const _RemoteImagePickerDialog({
    required this.api,
    required this.itemId,
    required this.imageType,
  });

  @override
  State<_RemoteImagePickerDialog> createState() =>
      _RemoteImagePickerDialogState();
}

class _RemoteImagePickerDialogState extends State<_RemoteImagePickerDialog> {
  static const int _pageSize = 24;

  bool _loading = true;
  String? _error;
  String _providerName = '';
  int _page = 0;
  int _totalCount = 0;
  List<String> _providers = const [];
  List<Map<String, dynamic>> _images = const [];

  int get _totalPages =>
      _totalCount == 0 ? 1 : ((_totalCount - 1) ~/ _pageSize) + 1;

  double get _previewAspectRatio {
    return switch (widget.imageType) {
      ImageType.primary => 2 / 3,
      ImageType.backdrop => 16 / 9,
      ImageType.logo => 16 / 5,
      ImageType.banner => 5 / 1,
      ImageType.thumb => 16 / 9,
      _ => 16 / 9,
    };
  }

  double _gridChildAspectRatio(int crossAxisCount) {
    final preview = _previewAspectRatio;

    // Narrower cards on dense grids to preserve useful image area.
    if (crossAxisCount >= 3) {
      return switch (widget.imageType) {
        ImageType.primary => 0.68,
        ImageType.logo => 1.08,
        ImageType.banner => 1.65,
        _ => 0.92,
      };
    }

    return switch (widget.imageType) {
      ImageType.primary => 0.74,
      ImageType.logo => 1.16,
      ImageType.banner => 1.9,
      _ => preview > 1.7 ? 1.08 : 0.98,
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.getRemoteImages(
        widget.itemId,
        imageType: widget.imageType,
        startIndex: _page * _pageSize,
        limit: _pageSize,
        providerName: _providerName.isEmpty ? null : _providerName,
      );

      if (!mounted) return;
      setState(() {
        _images =
            (result['Images'] as List?)
                ?.whereType<Map>()
                .map((entry) => entry.cast<String, dynamic>())
                .toList() ??
            const [];
        if (_providers.isEmpty) {
          _providers =
              (result['Providers'] as List?)
                  ?.map((entry) => entry.toString())
                  .where((entry) => entry.isNotEmpty)
                  .toList() ??
              const [];
        }
        _totalCount = (result['TotalRecordCount'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < 700;

    return Dialog(
      insetPadding:
          compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 20)
              : const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? viewport.width : 960,
          maxHeight: viewport.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.adminMetadataChooseImage(widget.imageType.toServerString()),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrowToolbar = constraints.maxWidth < 560;
                  final pager = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed:
                            _loading || _page == 0
                                ? null
                                : () {
                                  setState(() => _page -= 1);
                                  _load();
                                },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${_page + 1} / $_totalPages'),
                      IconButton(
                        onPressed:
                            _loading || _page + 1 >= _totalPages
                                ? null
                                : () {
                                  setState(() => _page += 1);
                                  _load();
                                },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  );

                  if (narrowToolbar) {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _providerName,
                          decoration: InputDecoration(
                            labelText: l10n.adminMetadataProvider,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: '',
                              child: Text(l10n.adminAllProviders),
                            ),
                            ..._providers.map(
                              (provider) => DropdownMenuItem<String>(
                                value: provider,
                                child: Text(provider),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _providerName = value ?? '';
                              _page = 0;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(height: 8),
                        pager,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _providerName,
                          decoration: InputDecoration(
                            labelText: l10n.adminMetadataProvider,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: '',
                              child: Text(l10n.adminAllProviders),
                            ),
                            ..._providers.map(
                              (provider) => DropdownMenuItem<String>(
                                value: provider,
                                child: Text(provider),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _providerName = value ?? '';
                              _page = 0;
                            });
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      pager,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                onPressed: _load,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                        : _images.isEmpty
                        ? Center(child: Text(l10n.adminNoRemoteImages))
                        : LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final crossAxisCount =
                                maxWidth >= 980
                                    ? 4
                                    : maxWidth >= 660
                                    ? 3
                                    : maxWidth >= 420
                                    ? 2
                                    : 1;

                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: _gridChildAspectRatio(
                                      crossAxisCount,
                                    ),
                                  ),
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                final image = _images[index];
                                final previewUrl =
                                    (image['ThumbnailUrl'] ??
                                            image['Url'] ??
                                            '')
                                        .toString();
                                final providerName =
                                    (image['ProviderName'] ?? '').toString();
                                final size = [image['Width'], image['Height']]
                                    .where((value) => value != null)
                                    .map((value) => value.toString())
                                    .join(' x ');

                                return InkWell(
                                  onTap: () => Navigator.pop(context, image),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AspectRatio(
                                            aspectRatio: _previewAspectRatio,
                                            child:
                                                previewUrl.isEmpty
                                                    ? Container(
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                        ),
                                                      ),
                                                    )
                                                    : Image.network(
                                                      previewUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                providerName.isEmpty
                                                    ? l10n.adminMetadataRemoteImage
                                                    : providerName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleSmall,
                                              ),
                                              if (size.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    size,
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
