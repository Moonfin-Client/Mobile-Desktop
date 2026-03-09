import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import 'preference_binding.dart';

class SwitchPreferenceTile extends StatefulWidget {
  final Preference<bool> preference;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SwitchPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  State<SwitchPreferenceTile> createState() => _SwitchPreferenceTileState();
}

class _SwitchPreferenceTileState extends State<SwitchPreferenceTile> {
  late final PreferenceBinding<bool> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _binding,
      builder: (context, value, _) => SwitchListTile(
        secondary: widget.icon != null ? Icon(widget.icon) : null,
        title: Text(widget.title),
        subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
        value: value,
        onChanged: (v) => _binding.value = v,
      ),
    );
  }
}

class EnumPreferenceTile<T extends Enum> extends StatefulWidget {
  final EnumPreference<T> preference;
  final String title;
  final IconData? icon;
  final String Function(T value) labelOf;

  const EnumPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    required this.labelOf,
    this.icon,
  });

  @override
  State<EnumPreferenceTile<T>> createState() => _EnumPreferenceTileState<T>();
}

class _EnumPreferenceTileState<T extends Enum> extends State<EnumPreferenceTile<T>> {
  late final PreferenceBinding<T> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: _binding,
      builder: (context, value, _) => ListTile(
        leading: widget.icon != null ? Icon(widget.icon) : null,
        title: Text(widget.title),
        subtitle: Text(widget.labelOf(value)),
        onTap: () => _showPicker(context, value),
      ),
    );
  }

  void _showPicker(BuildContext context, T current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.title),
        children: widget.preference.values.map((v) {
          return RadioListTile<T>(
            title: Text(widget.labelOf(v)),
            value: v,
            groupValue: current,
            onChanged: (selected) {
              if (selected != null) _binding.value = selected;
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class SliderPreferenceTile extends StatefulWidget {
  final Preference<int> preference;
  final String title;
  final IconData? icon;
  final double min;
  final double max;
  final int? divisions;
  final String Function(int value)? labelOf;

  const SliderPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.icon,
    required this.min,
    required this.max,
    this.divisions,
    this.labelOf,
  });

  @override
  State<SliderPreferenceTile> createState() => _SliderPreferenceTileState();
}

class _SliderPreferenceTileState extends State<SliderPreferenceTile> {
  late final PreferenceBinding<int> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _binding,
      builder: (context, value, _) => ListTile(
        leading: widget.icon != null ? Icon(widget.icon) : null,
        title: Text(widget.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelOf != null) Text(widget.labelOf!(value)),
            Slider(
              value: value.toDouble().clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: widget.labelOf?.call(value) ?? value.toString(),
              onChanged: (v) => _binding.value = v.round(),
            ),
          ],
        ),
      ),
    );
  }
}

class StringPickerPreferenceTile extends StatefulWidget {
  final Preference<String> preference;
  final String title;
  final IconData? icon;
  final Map<String, String> options;

  const StringPickerPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.icon,
    required this.options,
  });

  @override
  State<StringPickerPreferenceTile> createState() => _StringPickerPreferenceTileState();
}

class _StringPickerPreferenceTileState extends State<StringPickerPreferenceTile> {
  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) => ListTile(
        leading: widget.icon != null ? Icon(widget.icon) : null,
        title: Text(widget.title),
        subtitle: Text(widget.options[value] ?? value),
        onTap: () => _showPicker(context, value),
      ),
    );
  }

  void _showPicker(BuildContext context, String current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.title),
        children: widget.options.entries.map((e) {
          return RadioListTile<String>(
            title: Text(e.value),
            value: e.key,
            groupValue: current,
            onChanged: (selected) {
              if (selected != null) _binding.value = selected;
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}
