import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../widgets/settings/preference_binding.dart';
import '../../../l10n/app_localizations.dart';

class ParentalSettingsScreen extends StatefulWidget {
  const ParentalSettingsScreen({super.key});

  @override
  State<ParentalSettingsScreen> createState() => _ParentalSettingsScreenState();
}

class _ParentalSettingsScreenState extends State<ParentalSettingsScreen> {
  late final PreferenceBinding<String> _blockedRatings;
  final List<String> _serverRatings = [];
  bool _loadingRatings = true;
  String? _ratingsError;

  @override
  void initState() {
    super.initState();
    _blockedRatings = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      const Preference(key: 'blocked_ratings', defaultValue: ''),
    );
    _loadServerRatings();
  }

  @override
  void dispose() {
    _blockedRatings.dispose();
    super.dispose();
  }

  Set<String> get _blocked => _blockedRatings.value.isEmpty
      ? {}
      : _blockedRatings.value.split(',').toSet();

  List<String> get _effectiveRatings {
    final merged = <String>{..._serverRatings, ..._blocked};
    final sorted = merged.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  Future<void> _loadServerRatings() async {
    try {
      final client = GetIt.instance<MediaServerClient>();
      final discovered = <String>{};
      const pageSize = 200;
      var startIndex = 0;
      var safetyPages = 0;

      while (safetyPages < 15) {
        final response = await client.itemsApi.getItems(
          includeItemTypes: const [
            'Movie',
            'Series',
            'Episode',
            'Video',
            'MusicVideo',
            'Book',
            'AudioBook',
          ],
          recursive: true,
          fields: 'OfficialRating',
          startIndex: startIndex,
          limit: pageSize,
          enableTotalRecordCount: true,
        );

        final items = response['Items'];
        final totalRecordCount = response['TotalRecordCount'] as num?;
        final page = items is List
            ? items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : const <Map<String, dynamic>>[];

        for (final item in page) {
          final rating = item['OfficialRating']?.toString().trim();
          if (rating != null && rating.isNotEmpty) {
            discovered.add(rating.toUpperCase());
          }
        }

        if (page.length < pageSize) {
          break;
        }

        startIndex += page.length;
        safetyPages += 1;
        if (totalRecordCount != null && startIndex >= totalRecordCount.toInt()) {
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _serverRatings
          ..clear()
          ..addAll(discovered.toList()..sort((a, b) => a.compareTo(b)));
        _loadingRatings = false;
        _ratingsError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRatings = false;
        _ratingsError = '$error';
      });
    }
  }

  void _toggle(String rating) {
    final current = _blocked;
    if (current.contains(rating)) {
      current.remove(rating);
    } else {
      current.add(rating);
    }
    _blockedRatings.value = current.join(',');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocked = _blocked;
    final ratings = _effectiveRatings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentalControls)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.blockContentWithRatings,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (_loadingRatings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ratings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _ratingsError == null
                    ? l10n.noContentRatingsFound
                    : l10n.couldNotLoadServerRatings,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            if (_ratingsError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Could not refresh ratings from server. Showing saved ratings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ...ratings.map((rating) => CheckboxListTile(
              title: Text(rating),
              value: blocked.contains(rating),
              onChanged: (_) => _toggle(rating),
            )),
          ],
        ],
      ),
    );
  }
}
