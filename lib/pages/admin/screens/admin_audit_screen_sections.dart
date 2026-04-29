// ignore_for_file: invalid_use_of_protected_member

part of 'admin_audit_screen.dart';

extension _AdminAuditScreenSections on _AdminAuditScreenState {
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionIntro(
          title: 'Audit Trail',
          subtitle:
              'Review who changed what, when it happened, and which entity was affected from one professional audit view.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _AuditMetricCard(
              icon: Icons.history_edu_outlined,
              label: 'Total events',
              value: '${_logs.length}',
              accentColor: AppColors.redColor,
            ),
            _AuditMetricCard(
              icon: Icons.today_outlined,
              label: 'Today',
              value: '$_todayCount',
              accentColor: const Color(0xFF2558C5),
            ),
            _AuditMetricCard(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Active admins',
              value: '$_adminCount',
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
            label: 'Compliance',
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Use this page when you need to trace actions across products, orders, users, and promotions without giving the team direct database visibility.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          SizedBox(height: 18),
          _AuditGuidePoint(
            title: 'Search by actor or entity',
            description:
                'Support teams can jump straight to an admin name, entity ID, or action keyword when investigating changes.',
          ),
          SizedBox(height: 14),
          _AuditGuidePoint(
            title: 'Filter by entity type',
            description:
                'Narrow the feed to products, orders, users, coupons, banners, or any other audited entity.',
          ),
          SizedBox(height: 14),
          _AuditGuidePoint(
            title: 'Open the JSON details',
            description:
                'The details sheet keeps the structured payload readable without cluttering the main timeline.',
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
            title: 'Audit Library',
            subtitle:
                'Search by actor, action, entity ID, or any text inside the audit details payload.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: _inputDecoration('Search audit events').copyWith(
                    hintText: 'Search by actor, action, entity ID, or payload',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _entityFilter,
                  decoration: _inputDecoration('Entity filter'),
                  items: _entityOptions
                      .map(
                        (entity) => DropdownMenuItem<String>(
                          value: entity,
                          child: Text(
                            entity == 'all' ? 'All entities' : entity,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _entityFilter = value);
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

  InputDecoration _inputDecoration(String label) {
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
