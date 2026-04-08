import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

import '../../../navigation/destinations.dart';
import '../providers/admin_user_providers.dart';
import 'admin_user_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class AdminUserEditScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserEditScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserEditScreen> createState() =>
      _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends ConsumerState<AdminUserEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MediaServerClient _client;

  ServerUser? _user;
  late Map<String, dynamic> _policy;
  List<VirtualFolderInfo>? _libraries;

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bitrateLimitController = TextEditingController();
  final _maxSessionsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _originalName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _client = GetIt.instance<MediaServerClient>();
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bitrateLimitController.dispose();
    _maxSessionsController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _client.adminUsersApi.getUserById(widget.userId),
        _client.adminLibraryApi.getVirtualFolders(),
      ]);
      if (!mounted) return;
      final user = results[0] as ServerUser;
      final libs = results[1] as List<VirtualFolderInfo>;
      setState(() {
        _user = user;
        _libraries = libs;
        _originalName = (user.name ?? '').trim();
        _nameController.text = _originalName;
        _policy = user.policy?.toJson() ?? <String, dynamic>{};
        _bitrateLimitController.text =
            (_policy['RemoteClientBitrateLimit'] as int?)?.toString() ?? '';
        _maxSessionsController.text =
            (_policy['MaxActiveSessions'] as int?)?.toString() ?? '';
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

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminUsernameRequired)),
      );
      return;
    }

    if (newName == _originalName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminNoProfileChanges)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _client.adminUsersApi.updateUser(widget.userId, {
        'Name': newName,
        'Configuration': <String, dynamic>{},
      });
      _originalName = newName;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminProfileSaved)),
        );
      }
      ref.invalidate(adminUsersListProvider);
      ref.invalidate(adminUserProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminSaveFailed(_formatError(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final detail = responseData['message'] ??
            responseData['Message'] ??
            responseData['error'] ??
            responseData['title'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }
      } else if (responseData is String && responseData.trim().isNotEmpty) {
        return responseData;
      }

      final status = error.response?.statusCode;
      if (status != null) {
        return 'Server returned HTTP $status';
      }
    }
    return error.toString();
  }

  Future<void> _savePolicy() async {
    final l10n = AppLocalizations.of(context);
    final bitrate = int.tryParse(_bitrateLimitController.text);
    final maxSessions = int.tryParse(_maxSessionsController.text);
    _policy['RemoteClientBitrateLimit'] = bitrate;
    _policy['MaxActiveSessions'] = maxSessions;

    setState(() => _saving = true);
    try {
      await _client.adminUsersApi
          .updateUserPolicy(widget.userId, _policy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminPermissionsSaved)),
        );
      }
      ref.invalidate(adminUsersListProvider);
      ref.invalidate(adminUserProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminSaveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePassword() async {
    final l10n = AppLocalizations.of(context);
    final pw = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (pw.isNotEmpty && pw != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPasswordsMismatch)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (pw.isEmpty) {
        await _client.adminUsersApi
            .updateUserPassword(widget.userId, resetPassword: true);
      } else {
        await _client.adminUsersApi
            .updateUserPassword(widget.userId, newPassword: pw);
      }
      if (mounted) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(pw.isEmpty ? 'Password reset' : 'Password updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _togglePolicy(String key, bool value) {
    setState(() => _policy[key] = value);
  }

  void _toggleFolderAccess(String folderId, bool enabled) {
    final folders = List<String>.from(
        _policy['EnabledFolders'] as List? ?? []);
    if (enabled) {
      if (!folders.contains(folderId)) folders.add(folderId);
    } else {
      folders.remove(folderId);
    }
    setState(() => _policy['EnabledFolders'] = folders);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminUserLoadFailed,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: _loadUser, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go(Destinations.adminUsers),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.adminBackToUsers),
              ),
              const Spacer(),
              Text(
                _user?.name?.isNotEmpty == true
                    ? _user!.name!
                    : 'User Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.profile),
            Tab(text: l10n.permissions),
            Tab(text: l10n.access),
            Tab(text: l10n.password),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildPermissionsTab(),
              _buildAccessTab(),
              _buildPasswordTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            FilledButton(
              onPressed: _saving ? null : _saveProfile,
              child: const Text('Save Profile'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => showAdminUserDeleteDialog(
                context,
                user: _user!,
                onDeleted: () {
                  ref.invalidate(adminUsersListProvider);
                  context.go(Destinations.adminUsers);
                },
              ),
              icon: const Icon(Icons.delete),
              label: const Text('Delete User'),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Admin'),
        if (_policy['IsAdministrator'] == true)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Administrators have complete access to all server features.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ),
        _policySwitch('IsAdministrator', 'Administrator'),
        _policySwitch('IsHidden', 'Hidden user'),
        _policySwitch('IsDisabled', 'Disabled'),
        _sectionHeader('Playback'),
        _policySwitch('EnableMediaPlayback', 'Allow media playback'),
        _policySwitch(
            'EnableAudioPlaybackTranscoding', 'Allow audio transcoding'),
        _policySwitch(
            'EnableVideoPlaybackTranscoding', 'Allow video transcoding'),
        _policySwitch('EnablePlaybackRemuxing', 'Allow remuxing'),
        _policySwitch('ForceRemoteSourceTranscoding',
            'Force remote source transcoding'),
        _sectionHeader('Content'),
        _policySwitch('EnableContentDeletion', 'Allow content deletion'),
        _policySwitch(
            'EnableContentDownloading', 'Allow content downloading'),
        _policySwitch('EnablePublicSharing', 'Allow public sharing'),
        _sectionHeader('Sessions'),
        _policySwitch('EnableRemoteControlOfOtherUsers',
            'Allow remote control of other users'),
        _policySwitch(
            'EnableSharedDeviceControl', 'Allow shared device control'),
        _policySwitch('EnableRemoteAccess', 'Allow remote access'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: _bitrateLimitController,
            decoration: const InputDecoration(
              labelText: 'Remote client bitrate limit (bps)',
              border: OutlineInputBorder(),
              helperText: 'Leave empty for no limit',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: _maxSessionsController,
            decoration: const InputDecoration(
              labelText: 'Max active sessions',
              border: OutlineInputBorder(),
              helperText: 'Leave empty for no limit',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        _sectionHeader('Features'),
        _policySwitch('EnableLiveTvAccess', 'Allow Live TV access'),
        _policySwitch(
            'EnableLiveTvManagement', 'Allow Live TV management'),
        _policySwitch(
            'EnableCollectionManagement', 'Allow collection management'),
        _policySwitch(
            'EnableSubtitleManagement', 'Allow subtitle management'),
        _policySwitch('EnableLyricManagement', 'Allow lyric management'),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _savePolicy,
            child: const Text('Save Permissions'),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessTab() {
    final enableAllFolders = _policy['EnableAllFolders'] as bool? ?? true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Library Access'),
        SwitchListTile(
          title: const Text('Enable access to all libraries'),
          value: enableAllFolders,
          onChanged: (v) => _togglePolicy('EnableAllFolders', v),
        ),
        if (!enableAllFolders && _libraries != null)
          ...() {
            final enabledFolders = List<String>.from(
                _policy['EnabledFolders'] as List? ?? []);
            return (_libraries!).map((lib) {
            final enabled = enabledFolders.contains(lib.itemId);
            return CheckboxListTile(
              title: Text(lib.name),
              subtitle: lib.collectionType != null
                  ? Text(lib.collectionType!)
                  : null,
              value: enabled,
              onChanged: (v) =>
                  _toggleFolderAccess(lib.itemId, v ?? false),
            );
          });
          }(),
        const Divider(height: 32),
        _sectionHeader('Device & Channel Access'),
        _policySwitch('EnableAllDevices', 'Enable access to all devices'),
        _policySwitch(
            'EnableAllChannels', 'Enable access to all channels'),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _savePolicy,
            child: const Text('Save Access'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Change Password',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            FilledButton(
              onPressed: _saving ? null : _savePassword,
              child: const Text('Set Password'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset Password'),
                          content: const Text(
                              'This will remove the password. The user will be able to log in without a password.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(true),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        await _savePassword();
                      }
                    },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _policySwitch(String key, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _policy[key] as bool? ?? false,
      onChanged: (v) => _togglePolicy(key, v),
    );
  }
}
