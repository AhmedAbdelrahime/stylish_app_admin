// ignore_for_file: invalid_use_of_protected_member

part of 'admin_user_screen.dart';

extension _AdminUserScreenSections on _AdminUserScreenState {
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
                  onChanged: _onSearchChanged,
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
                    DropdownMenuItem(value: 'user', child: Text('Users')),
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
