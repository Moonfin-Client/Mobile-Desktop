import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_requests_view_model.dart';
import '../../navigation/destinations.dart';
import '../../widgets/navigation_layout.dart';
import '../../../l10n/app_localizations.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w200';

class SeerrRequestsScreen extends StatefulWidget {
  const SeerrRequestsScreen({super.key});

  @override
  State<SeerrRequestsScreen> createState() => _SeerrRequestsScreenState();
}

class _SeerrRequestsScreenState extends State<SeerrRequestsScreen> {
  SeerrRequestsViewModel? _vm;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = await GetIt.instance.getAsync<SeerrRepository>();
    final vm = SeerrRequestsViewModel(repo);
    vm.addListener(_onChanged);

    if (!mounted) {
      vm.dispose();
      return;
    }

    setState(() {
      _vm = vm;
      _initializing = false;
    });

    vm.load();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChanged);
    _vm?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final vm = _vm;
    if (_initializing || vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = vm.state;

    if (s.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (s.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: vm.load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (s.requests.isEmpty) {
      return Center(
        child: Text(l10n.noRequests, style: const TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: s.requests.length,
        itemBuilder: (context, index) {
          final req = s.requests[index];
          return _RequestCard(
            request: req,
            canManage: s.canManageRequests,
            isActioning: s.actioningRequestId == req.id,
            onTap: () => _onRequestTap(req),
            onApprove: () => vm.approveRequest(req.id),
            onDecline: () => vm.declineRequest(req.id),
          );
        },
      ),
    );
  }

  void _onRequestTap(SeerrRequest request) {
    final media = request.media;
    if (media == null) return;
    final tmdbId = media.tmdbId;
    if (tmdbId == null) return;
    context.push(
      Destinations.seerrMedia(tmdbId.toString()),
      extra: {'mediaType': request.type},
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SeerrRequest request;
  final bool canManage;
  final bool isActioning;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const _RequestCard({
    required this.request,
    required this.canManage,
    required this.isActioning,
    this.onTap,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = request.media;
    final posterPath = media?.posterPath;
    final title = media?.title ?? media?.name ?? l10n.unknown;
    final requester = request.requestedBy?.bestName ?? l10n.unknown;
    final date = request.createdAt?.split('T').first ?? '';

    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Row(
            children: [
              SizedBox(
                width: 93,
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: '$_tmdbPosterBase$posterPath',
                        fit: BoxFit.cover,
                        height: double.infinity,
                      )
                    : Container(
                        color: Colors.white10,
                        child: const Icon(Icons.movie,
                            color: Colors.white24, size: 40),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.type.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _StatusChip(request: request),
                          const Spacer(),
                          if (date.isNotEmpty)
                            Text(date,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.requestedByName(requester),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canManage &&
                              request.status == SeerrRequest.statusPending) ...[
                            if (isActioning)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white54),
                              )
                            else ...[
                              IconButton(
                                onPressed: onApprove,
                                icon: const Icon(Icons.check_circle_outline,
                                    color: Colors.green, size: 20),
                                tooltip: l10n.approve,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: onDecline,
                                icon: Icon(Icons.cancel_outlined,
                                    color: Colors.red[300], size: 20),
                                tooltip: l10n.declineAction,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SeerrRequest request;

  const _StatusChip({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = _statusInfo(l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  (String, Color) _statusInfo(AppLocalizations l10n) {
    final mediaStatus = request.media?.status;
    if (request.status == SeerrRequest.statusPending) {
      return (l10n.pendingStatus, Colors.grey);
    }
    if (request.status == SeerrRequest.statusDeclined) {
      return (l10n.declinedStatus, Colors.red);
    }
    if (mediaStatus == 5) return (l10n.seerrAvailableStatus, Colors.green);
    if (mediaStatus == 4) return (l10n.partiallyAvailable, Colors.orange);
    if (mediaStatus == 3) return (l10n.downloadingStatus, const Color(0xFF6366F1));
    if (request.status == SeerrRequest.statusApproved) {
      return (l10n.approvedStatus, Colors.blue);
    }
    return (l10n.unknown, Colors.grey);
  }
}
