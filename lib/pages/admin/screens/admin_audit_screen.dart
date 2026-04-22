import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_audit_log_model.dart';
import 'package:hungry/pages/admin/data/admin_audit_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final AdminAuditService _auditService = AdminAuditService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminAuditLogModel> _logs = const [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _entityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _auditService.getAuditLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
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

  List<AdminAuditLogModel> get _filteredLogs {
    final query = _searchQuery.trim().toLowerCase();
    return _logs.where((log) {
      if (_entityFilter != 'all' && log.entityType != _entityFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        log.action,
        log.entityType,
        log.entityId ?? '',
        log.actorLabel,
        log.actorEmail,
        ...log.details.entries.map((entry) => '${entry.key} ${entry.value}'),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<String> get _entityOptions {
    final entities = _logs.map((log) => log.entityType).toSet().toList()..sort();
    return ['all', ...entities];
  }

  int get _todayCount {
    final now = DateTime.now();
    return _logs.where((log) {
      final createdAt = log.createdAt;
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  int get _adminCount =>
      _logs.map((log) => log.adminUserId).whereType<String>().toSet().length;

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Color _entityColor(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'product':
        return const Color(0xFF2558C5);
      case 'order':
        return const Color(0xFF1E8E5A);
      case 'coupon':
      case 'banner':
      case 'offer':
        return const Color(0xFF8A2BE2);
      case 'user':
      case 'profile':
        return const Color(0xFFB06A00);
      default:
        return AppColors.redColor;
    }
  }

  void _openLogDetails(AdminAuditLogModel log) {
    final prettyDetails = const JsonEncoder.withIndent('  ').convert(log.details);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
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
                    Text(
                      log.actionLabel,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blackColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(log.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.hintColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AuditDetailsCard(
                      title: 'Event summary',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuditDetailRow(label: 'Actor', value: log.actorLabel),
                          _AuditDetailRow(label: 'Email', value: log.actorEmail),
                          _AuditDetailRow(label: 'Entity', value: log.entityType),
                          _AuditDetailRow(
                            label: 'Entity ID',
                            value: log.entityId ?? 'No entity ID',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AuditDetailsCard(
                      title: 'JSON details',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.blackColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: SelectableText(
                          prettyDetails,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.redColor,
      onRefresh: _loadLogs,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
        children: [
          AdminResponsiveSplit(
            breakpoint: 1120,
            spacing: 20,
            primaryFlex: 5,
            secondaryFlex: 4,
            primary: _buildSummarySection(),
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
          else if (_logs.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.history_edu_outlined,
              title: 'No audit events yet',
              description:
                  'As admin actions get logged, they will appear here for review, support, and accountability.',
            )
          else if (_filteredLogs.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'No matching audit events',
              description:
                  'Try a different search term or clear the entity filter.',
            )
          else
            ..._filteredLogs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AuditLogCard(
                  log: log,
                  accentColor: _entityColor(log.entityType),
                  formatDateTime: _formatDateTime,
                  onViewDetails: () => _openLogDetails(log),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: _inputDecoration(
                    'Search audit events',
                  ).copyWith(
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
                          child: Text(entity == 'all' ? 'All entities' : entity),
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

class _AuditMetricCard extends StatelessWidget {
  const _AuditMetricCard({
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

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({
    required this.log,
    required this.accentColor,
    required this.formatDateTime,
    required this.onViewDetails,
  });

  final AdminAuditLogModel log;
  final Color accentColor;
  final String Function(DateTime value) formatDateTime;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${log.actionLabel} on ${log.entityType}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onViewDetails,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.blackColor,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${log.actorLabel} - ${formatDateTime(log.createdAt)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminTag(
                label: log.entityType,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                foregroundColor: accentColor,
                isCompact: true,
              ),
              AdminTag(label: log.action, isCompact: true),
              if ((log.entityId ?? '').isNotEmpty)
                AdminTag(label: log.entityId!, isCompact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditDetailsCard extends StatelessWidget {
  const _AuditDetailsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AuditDetailRow extends StatelessWidget {
  const _AuditDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditGuidePoint extends StatelessWidget {
  const _AuditGuidePoint({required this.title, required this.description});

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
