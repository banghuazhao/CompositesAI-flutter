import 'package:domain/auth/entities/expert_upgrade_request.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewModels/settings_view_model.dart';

class ExpertRequestsPage extends StatefulWidget {
  const ExpertRequestsPage({super.key});

  @override
  State<ExpertRequestsPage> createState() => _ExpertRequestsPageState();
}

class _ExpertRequestsPageState extends State<ExpertRequestsPage> {
  late Future<List<ExpertUpgradeRequest>> _requestsFuture;
  final Set<String> _busyRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchRequests();
  }

  Future<List<ExpertUpgradeRequest>> _fetchRequests() {
    return context.read<SettingsViewModel>().fetchPendingExpertRequests();
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  Future<void> _reviewRequest(
    ExpertUpgradeRequest request, {
    required bool approve,
  }) async {
    setState(() => _busyRequestIds.add(request.id));
    final viewModel = context.read<SettingsViewModel>();

    try {
      if (approve) {
        await viewModel.approveExpertRequest(request);
      } else {
        await viewModel.denyExpertRequest(request);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Request approved' : 'Request denied'),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(request.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expert Requests')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<ExpertUpgradeRequest>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load requests',
                    subtitle: snapshot.error.toString(),
                  ),
                ],
              );
            }

            final requests = snapshot.data ?? const <ExpertUpgradeRequest>[];
            if (requests.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _EmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'No pending expert requests',
                    subtitle:
                        'New requests from normal users will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _ExpertRequestCard(
                  request: request,
                  isBusy: _busyRequestIds.contains(request.id),
                  onApprove: () => _reviewRequest(request, approve: true),
                  onDeny: () => _reviewRequest(request, approve: false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ExpertRequestCard extends StatelessWidget {
  const _ExpertRequestCard({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onDeny,
  });

  final ExpertUpgradeRequest request;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    final name = (user?.name?.trim().isNotEmpty == true)
        ? user!.name!.trim()
        : user?.email ?? 'Unknown user';
    final email = user?.email ?? request.userId;
    final note = request.requesterNotes.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                note,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onDeny,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onApprove,
                    icon: isBusy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
