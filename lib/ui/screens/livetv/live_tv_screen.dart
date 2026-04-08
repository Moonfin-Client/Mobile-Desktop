import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';
import '../../widgets/navigation_layout.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 80),
            children: [
              ListTile(
                leading: const Icon(Icons.tv),
                title: Text(l10n.guide),
                onTap: () => context.push(Destinations.liveTvGuide),
              ),
              ListTile(
                leading: const Icon(Icons.fiber_dvr),
                title: Text(l10n.recordings),
                onTap: () => context.push(Destinations.liveTvRecordings),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l10n.schedule),
                onTap: () => context.push(Destinations.liveTvSchedule),
              ),
              ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(l10n.seriesRecordings),
                onTap: () => context.push(Destinations.liveTvSeriesRecordings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
