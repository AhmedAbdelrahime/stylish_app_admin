import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/data/admin_audit_log_model.dart';
import 'package:hungry/pages/admin/data/admin_audit_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'admin_audit_screen_sections.dart';
part 'admin_audit_cards.dart';
part 'admin_audit_details_widgets.dart';
part 'admin_audit_guide_widgets.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AdminAuditService _auditService = AdminAuditService();
  final TextEditingController _searchController = TextEditingController();

  SupabaseRealtimeReloader? _realtimeReloader;
  List<AdminAuditLogModel> _logs = const [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _entityFilter = 'all';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _loadLogs();
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
      channelName: 'admin-audit-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['admin_audit_logs', 'profiles'],
      onReload: () => _loadLogs(showLoading: false),
    );
  }

  Future<void> _loadLogs({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

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
    final entities = _logs.map((log) => log.entityType).toSet().toList()
      ..sort();
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
    final prettyDetails = const JsonEncoder.withIndent(
      '  ',
    ).convert(log.details);

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
                          _AuditDetailRow(
                            label: 'Actor',
                            value: log.actorLabel,
                          ),
                          _AuditDetailRow(
                            label: 'Email',
                            value: log.actorEmail,
                          ),
                          _AuditDetailRow(
                            label: 'Entity',
                            value: log.entityType,
                          ),
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
}
