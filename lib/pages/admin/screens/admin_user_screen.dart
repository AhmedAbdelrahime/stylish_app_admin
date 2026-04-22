import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _users = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
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
        final matchesRole = _roleFilter == 'admin' ? user.isAdmin : !user.isAdmin;
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
        text: '${user.displayName} is now ${role == 'admin' ? 'an admin' : 'a user'}.',
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
                        _SheetField(controller: nameController, label: 'Full name'),
                        const SizedBox(height: 12),
                        _SheetField(controller: emailController, label: 'Email'),
                        const SizedBox(height: 12),
                        _SheetField(controller: imageController, label: 'Image URL'),
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
                                        image: imageController.text.trim().isEmpty
                                            ? null
                                            : imageController.text.trim(),
                                        address: addressController.text.trim().isEmpty
                                            ? null
                                            : addressController.text.trim(),
                                        city: cityController.text.trim().isEmpty
                                            ? null
                                            : cityController.text.trim(),
                                        state: stateController.text.trim().isEmpty
                                            ? null
                                            : stateController.text.trim(),
                                        country: countryController.text.trim().isEmpty
                                            ? null
                                            : countryController.text.trim(),
                                        pincode: pincodeController.text.trim().isEmpty
                                            ? null
                                            : pincodeController.text.trim(),
                                        role: selectedRole,
                                      ),
                                    );
                                    await _loadUsers();
                                    if (!mounted || !parentContext.mounted) return;
                                    AppSnackBar.show(
                                      context: parentContext,
                                      text: 'User profile updated successfully.',
                                      icon: Icons.check_circle_outline,
                                      backgroundColor: Colors.green,
                                    );
                                  } catch (error) {
                                    if (!mounted || !parentContext.mounted) return;
                                    AppSnackBar.show(
                                      context: parentContext,
                                      text: SupabaseErrorMapper.map(error),
                                      icon: Icons.error_outline_rounded,
                                      backgroundColor: Colors.red,
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isSaving = false);
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

  Widget _buildSummarySection(int adminCount, int userCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionIntro(
          title: 'User Management',
          subtitle:
              'Review user and admin accounts, update profile details, and manage access from one professional admin screen.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _UserMetricCard(
              icon: Icons.people_alt_outlined,
              label: 'Total users',
              value: '${_users.length}',
              accentColor: AppColors.redColor,
            ),
            _UserMetricCard(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admins',
              value: '$adminCount',
              accentColor: const Color(0xFF2558C5),
            ),
            _UserMetricCard(
              icon: Icons.person_outline_rounded,
              label: 'Users',
              value: '$userCount',
              accentColor: const Color(0xFF1E8E5A),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuideCard() {
    return const AdminSurfaceCard(
      backgroundColor: AppColors.blackColor,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTag(
            label: 'Access',
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Use this page to keep profile data clean and access roles controlled without giving support staff direct database access.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          SizedBox(height: 18),
          _UserGuidePoint(
            title: 'Search fast',
            description:
                'Lookup by name, email, role, address, or location when support needs to verify an account quickly.',
          ),
          SizedBox(height: 14),
          _UserGuidePoint(
            title: 'Promote carefully',
            description:
                'Role changes are one click, so keep admin access limited to trusted team members.',
          ),
          SizedBox(height: 14),
          _UserGuidePoint(
            title: 'Update profile data in one sheet',
            description:
                'Support can fix missing addresses, avatar links, and user details without leaving the admin workspace.',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'User Library',
            subtitle:
                'Search by name, email, role, or location, then open the profile sheet to update user data.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: _sheetDecoration('Search users').copyWith(
                    hintText: 'Search by user, email, role, or location',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _roleFilter,
                  decoration: _sheetDecoration('Role filter'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All roles')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('Users'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _roleFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _sheetDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.redColor, width: 1.4),
      ),
    );
  }
}

class _UserMetricCard extends StatelessWidget {
  const _UserMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AdminSurfaceCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSaving,
    required this.onEdit,
    required this.onMakeAdmin,
    required this.onMakeUser,
  });

  final UserModel user;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onMakeAdmin;
  final VoidCallback onMakeUser;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryColor,
                backgroundImage:
                    user.image?.trim().isNotEmpty == true
                        ? NetworkImage(user.image!)
                        : null,
                child: user.image?.trim().isNotEmpty == true
                    ? null
                    : Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blackColor,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminTag(
                label: user.roleLabel,
                backgroundColor: user.isAdmin
                    ? const Color(0xFFE7F0FF)
                    : const Color(0xFFE8F7ED),
                foregroundColor: user.isAdmin
                    ? const Color(0xFF2558C5)
                    : const Color(0xFF1E8E5A),
                isCompact: true,
              ),
              AdminTag(label: user.locationLabel, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.address?.trim().isNotEmpty == true
                ? user.address!
                : 'No address saved',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: isSaving ? null : onEdit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.blackColor,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              if (user.isAdmin)
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onMakeUser,
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('Make user'),
                )
              else
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onMakeAdmin,
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Make admin'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.redColor, width: 1.4),
        ),
      ),
    );
  }
}

class _UserGuidePoint extends StatelessWidget {
  const _UserGuidePoint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: AppColors.redColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFD5D5D5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
