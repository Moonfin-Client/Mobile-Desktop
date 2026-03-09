import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_binding.dart';

class ParentalSettingsScreen extends StatefulWidget {
  const ParentalSettingsScreen({super.key});

  @override
  State<ParentalSettingsScreen> createState() => _ParentalSettingsScreenState();
}

class _ParentalSettingsScreenState extends State<ParentalSettingsScreen> {
  late final PreferenceBinding<String> _blockedRatings;

  static const _ratings = [
    'G', 'PG', 'PG-13', 'R', 'NC-17',
    'TV-Y', 'TV-Y7', 'TV-G', 'TV-PG', 'TV-14', 'TV-MA',
    'NR',
  ];

  @override
  void initState() {
    super.initState();
    _blockedRatings = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      const Preference(key: 'blocked_ratings', defaultValue: ''),
    );
  }

  @override
  void dispose() {
    _blockedRatings.dispose();
    super.dispose();
  }

  Set<String> get _blocked => _blockedRatings.value.isEmpty
      ? {}
      : _blockedRatings.value.split(',').toSet();

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
    final blocked = _blocked;

    return Scaffold(
      appBar: AppBar(title: const Text('Parental Controls')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Block content with the following ratings:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ..._ratings.map((rating) => CheckboxListTile(
            title: Text(rating),
            value: blocked.contains(rating),
            onChanged: (_) => _toggle(rating),
          )),
        ],
      ),
    );
  }
}
