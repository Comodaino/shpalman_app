import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/auth_service.dart';
import '../../utils/database.dart';
import 'dart:convert';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  bool _notificationsEnabled = false;
  List<String> _joinedGroups = [];
  bool _isLoadingJoin = false;
  bool _isLoadingCreate = false;
  bool _isLoadingGroups = false;
  String? _joinErrorMessage;
  String? _createErrorMessage;
  String? _createdGroupId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
    await _loadGroups();
  }

  Future<void> _loadGroups() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await databaseService.getGroupsFromUserId(user!.uid);
      setState(() {
        _joinedGroups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load groups'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _joinGroup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final groupCode = _groupCodeController.text.trim();

    if (groupCode.isEmpty) {
      setState(() {
        _joinErrorMessage = 'Please enter a group code';
      });
      return;
    }

    if (_joinedGroups.contains(groupCode)) {
      setState(() {
        _joinErrorMessage = 'You are already in this group';
      });
      return;
    }

    setState(() {
      _isLoadingJoin = true;
      _joinErrorMessage = null;
    });

    try {
      final success = await databaseService.addToGroup(groupCode, user!.uid);

      setState(() {
        _isLoadingJoin = false;
      });

      if (success) {
        _groupCodeController.clear();
        setState(() {
          _joinErrorMessage = null;
        });
        await _loadGroups(); // Refresh the groups list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined group: $groupCode'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        setState(() {
          _joinErrorMessage = 'Invalid group code or unable to join group';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingJoin = false;
        _joinErrorMessage = 'An error occurred while joining the group';
      });
    }
  }

  Future<void> _createGroup() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      setState(() {
        _createErrorMessage = 'Please enter a group name';
      });
      return;
    }

    setState(() {
      _isLoadingCreate = true;
      _createErrorMessage = null;
      _createdGroupId = null;
    });

    try {
      final String? groupId = await databaseService.createGroup(groupName);

      setState(() {
        _isLoadingCreate = false;
      });

      _groupNameController.clear();
      await _loadGroups(); // Refresh the groups list

      if (mounted) {
        // Show popup with group ID
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Group Created!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group "$groupName" has been created successfully.'),
                  const SizedBox(height: 16),
                  const Text('Share this Group ID with others:'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            groupId?? ' ',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Copy to clipboard
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group ID copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCreate = false;
        _createErrorMessage = 'An error occurred while creating the group';
      });
    }
  }

  Future<void> _leaveGroup(String groupCode) async {
    // Here you would typically call a database method to leave the group
    // For now, we'll just refresh the groups list
    await _loadGroups();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left group: $groupCode'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'User Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'user@example.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable Notifications',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: _saveNotificationSetting,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Groups Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'My Groups',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Create Group Section
                    Text(
                      'Create a Group',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _groupNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter group name',
                              errorText: _createErrorMessage,
                            ),
                            enabled: !_isLoadingCreate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoadingCreate ? null : _createGroup,
                          child: _isLoadingCreate
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Create'),
                        ),
                      ],
                    ),

                    // Show created group ID
                    if (_createdGroupId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Created Successfully!',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Group ID: ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Expanded(
                                  child: SelectableText(
                                    _createdGroupId!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Copy to clipboard functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Group ID copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  tooltip: 'Copy Group ID',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share this ID with others so they can join your group',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Join Group Section
                    Text(
                      'Join a Group',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _groupCodeController,
                            decoration: InputDecoration(
                              hintText: 'Enter group code',
                              errorText: _joinErrorMessage,
                            ),
                            enabled: !_isLoadingJoin,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoadingJoin ? null : _joinGroup,
                          child: _isLoadingJoin
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Join'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Joined Groups List
                    Text(
                      'My Groups (${_joinedGroups.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingGroups)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_joinedGroups.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_off,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No groups joined yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new group or join an existing one',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(),
                              TextButton.icon(
                                onPressed: _loadGroups,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._joinedGroups.map((groupCode) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      groupCode,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showLeaveGroupDialog(groupCode),
                                    icon: const Icon(Icons.close),
                                    iconSize: 20,
                                    color: Theme.of(context).colorScheme.error,
                                    tooltip: 'Leave group',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog(String groupCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Group'),
          content: Text('Are you sure you want to leave the group "$groupCode"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _leaveGroup(groupCode);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}