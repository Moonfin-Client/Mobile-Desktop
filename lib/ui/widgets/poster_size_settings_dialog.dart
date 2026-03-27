import 'package:flutter/material.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';

const _jellyfinBlue = Color(0xFF00A4DC);

class PosterSizeSettingsDialog extends StatefulWidget {
  final UserPreferences prefs;
  final VoidCallback? onChanged;
  final EnumPreference<ImageType>? imageTypePreference;

  const PosterSizeSettingsDialog({
    super.key,
    required this.prefs,
    this.onChanged,
    this.imageTypePreference,
  });

  @override
  State<PosterSizeSettingsDialog> createState() =>
      _PosterSizeSettingsDialogState();
}

class _PosterSizeSettingsDialogState extends State<PosterSizeSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final currentSize = widget.prefs.get(UserPreferences.posterSize);
    final currentImageType = widget.imageTypePreference != null
        ? widget.prefs.get(widget.imageTypePreference!)
        : null;
    return Dialog(
      backgroundColor: const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(26)),
      ),
      child: SizedBox(
        width: 340,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Display',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            if (currentImageType != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  'Image Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(115),
                  ),
                ),
              ),
              for (final type in ImageType.values)
                _imageTypeTile(type, currentImageType == type),
              Divider(color: Colors.white.withAlpha(20)),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                'Poster Size',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(115),
                ),
              ),
            ),
            for (final size in PosterSize.values)
              _posterSizeTile(size, currentSize == size),
          ],
        ),
      ),
    );
  }

  Widget _imageTypeTile(ImageType type, bool selected) {
    final label = switch (type) {
      ImageType.poster => 'Poster',
      ImageType.thumb => 'Thumbnail',
      ImageType.banner => 'Banner',
    };
    return InkWell(
      onTap: () {
        final preference = widget.imageTypePreference;
        if (preference == null) return;
        widget.prefs.set(preference, type);
        widget.onChanged?.call();
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterSizeTile(PosterSize size, bool selected) {
    final label = switch (size) {
      PosterSize.small => 'Small',
      PosterSize.medium => 'Medium',
      PosterSize.large => 'Large',
      PosterSize.extraLarge => 'Extra Large',
    };
    return InkWell(
      onTap: () {
        widget.prefs.set(UserPreferences.posterSize, size);
        widget.onChanged?.call();
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _jellyfinBlue : Colors.white.withAlpha(128),
          width: 2,
        ),
        color: selected ? _jellyfinBlue : Colors.transparent,
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
