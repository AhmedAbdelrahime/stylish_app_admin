import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'admin_user_screen_sections.dart';
part 'admin_user_cards.dart';
part 'admin_user_sheet_widgets.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();

  SupabaseRealtimeReloader? _realtimeReloader;
  List<UserModel> _users = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  String _roleFilter = 'all';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeReloader?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: _supabase,
      channelName: 'admin-users-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['profiles'],
      onReload: () {
        if (_isSaving) return Future<void>.value();
        return _loadUsers(showLoading: false);
      },
    );
  }

  Future<void> _loadUsers({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final users = await _profileService.getAllProfiles();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  List<UserModel> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    return _users.where((user) {
      if (_roleFilter != 'all') {
        final matchesRole = _roleFilter == 'admin'
            ? user.isAdmin
            : !user.isAdmin;
        if (!matchesRole) return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        user.displayName,
        user.email,
        user.role ?? '',
        user.locationLabel,
        user.address ?? '',
        user.pincode ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _changeRole(UserModel user, String role) async {
    setState(() => _isSaving = true);
    try {
      await _profileService.updateUserRole(userId: user.userId, role: role);
      await _loadUsers();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text:
            '${user.displayName} is now ${role == 'admin' ? 'an admin' : 'a user'}.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openEditSheet(UserModel user) async {
    final parentContext = context;
    final nameController = TextEditingController(text: user.name ?? '');
    final emailController = TextEditingController(text: user.email);
    final imageController = TextEditingController(text: user.image ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final cityController = TextEditingController(text: user.city ?? '');
    final stateController = TextEditingController(text: user.state ?? '');
    final countryController = TextEditingController(text: user.country ?? '');
    final pincodeController = TextEditingController(text: user.pincode ?? '');
    String selectedRole = user.isAdmin ? 'admin' : 'user';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                    child: ListView(
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Edit user profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.hintColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SheetField(
                          controller: nameController,
                          label: 'Full name',
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: emailController,
                          label: 'Email',
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: imageController,
                          label: 'Image URL',
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: addressController,
                          label: 'Address',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SheetField(
                                controller: cityController,
                                label: 'City',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SheetField(
                                controller: stateController,
                                label: 'State',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SheetField(
                                controller: countryController,
                                label: 'Country',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SheetField(
                                controller: pincodeController,
                                label: 'Pincode',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: _sheetDecoration('Role'),
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() => selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  setState(() => _isSaving = true);
                                  try {
                                    await _profileService.adminUpdateProfile(
                                      UserModel(
                                        userId: user.userId,
                                        email: emailController.text.trim(),
                                        name: nameController.text.trim(),
                                        image:
                                            imageController.text.trim().isEmpty
                                            ? null
                                            : imageController.text.trim(),
                                        address:
                                            addressController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : addressController.text.trim(),
                                        city: cityController.text.trim().isEmpty
                                            ? null
                                            : cityController.text.trim(),
                                        state:
                                            stateController.text.trim().isEmpty
                                            ? null
                                            : stateController.text.trim(),
                                        country:
                                            countryController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : countryController.text.trim(),
                                        pincode:
                                            pincodeController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : pincodeController.text.trim(),
                                        role: selectedRole,
                                      ),
                                    );
                                    await _loadUsers();
                                    if (!mounted || !parentContext.mounted) {
                                      return;
                                    }
                                    AppSnackBar.show(
                                      context: parentContext,
                                      text:
                                          'User profile updated successfully.',
                                      icon: Icons.check_circle_outline,
                                      backgroundColor: Colors.green,
                                    );
                                  } catch (error) {
                                    if (!mounted || !parentContext.mounted) {
                                      return;
                                    }
                                    AppSnackBar.show(
                                      context: parentContext,
                                      text: SupabaseErrorMapper.map(error),
                                      icon: Icons.error_outline_rounded,
                                      backgroundColor: Colors.red,
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.redColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save user data'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    imageController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = _users.where((user) => user.isAdmin).length;
    final userCount = _users.length - adminCount;

    return RefreshIndicator(
      color: AppColors.redColor,
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
        children: [
          AdminResponsiveSplit(
            breakpoint: 1120,
            spacing: 20,
            primaryFlex: 5,
            secondaryFlex: 4,
            primary: _buildSummarySection(adminCount, userCount),
            secondary: _buildGuideCard(),
          ),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 18),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.redColor),
              ),
            )
          else if (_users.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.people_alt_outlined,
              title: 'No user profiles yet',
              description:
                  'As users and admins sign in, their profile records will appear here for review and management.',
            )
          else if (_filteredUsers.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'No matching users',
              description:
                  'Try a different search term or clear the current role filter.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredUsers.map((user) {
                return SizedBox(
                  width: 340,
                  child: _UserCard(
                    user: user,
                    isSaving: _isSaving,
                    onEdit: () => _openEditSheet(user),
                    onMakeAdmin: () => _changeRole(user, 'admin'),
                    onMakeUser: () => _changeRole(user, 'user'),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
