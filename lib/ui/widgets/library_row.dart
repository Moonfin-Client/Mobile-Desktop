import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'horizontal_scroll_section.dart';

class LibraryRow extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onSeeAll;
  final double? rowHeight;

  const LibraryRow({
    super.key,
    required this.title,
    required this.children,
    this.onSeeAll,
    this.rowHeight,
  });

  @override
  State<LibraryRow> createState() => _LibraryRowState();
}

class _LibraryRowState extends State<LibraryRow> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasItems = widget.children.isNotEmpty;
    return HorizontalScrollSection(
      title: widget.title,
      headerPadding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      contentSpacing: 0,
      trailing: widget.onSeeAll == null
          ? null
          : TextButton(
              onPressed: widget.onSeeAll,
              child: Text(l10n.seeAll),
            ),
      showControls: hasItems,
      builder: (_, scrollController) => SizedBox(
        height: (widget.rowHeight ?? 220) + 10,
        child: hasItems
            ? ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                itemCount: widget.children.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => widget.children[i],
              )
            : Center(
                child: Text(
                  l10n.noItems,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                      ),
                ),
              ),
      ),
    );
  }
}
