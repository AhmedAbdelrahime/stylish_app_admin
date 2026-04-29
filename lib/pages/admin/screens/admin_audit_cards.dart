part of 'admin_audit_screen.dart';

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
            style: const TextStyle(fontSize: 13, color: AppColors.hintColor),
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
