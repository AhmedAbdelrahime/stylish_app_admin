part of 'admin_dashboard_screen.dart';

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final String change;
  final IconData icon;
  final _DashboardStatTone tone;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final tone = _resolveTone();

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: tone.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: tone.color),
          ),
          const SizedBox(height: 18),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stat.change,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tone.color,
            ),
          ),
        ],
      ),
    );
  }

  _DashboardStatToneStyle _resolveTone() {
    switch (stat.tone) {
      case _DashboardStatTone.positive:
        return const _DashboardStatToneStyle(Colors.green);
      case _DashboardStatTone.warning:
        return const _DashboardStatToneStyle(Colors.orange);
      case _DashboardStatTone.critical:
        return const _DashboardStatToneStyle(AppColors.redColor);
      case _DashboardStatTone.neutral:
        return const _DashboardStatToneStyle(AppColors.redColor);
    }
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({required this.order});

  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order.orderCode,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.blackColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              order.displayCustomerName,
              style: const TextStyle(color: AppColors.hintColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _DashboardSnapshot._formatMoney(
                order.totalAmount,
                order.currency,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.blackColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _DashboardSnapshot._titleCase(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return AppColors.redColor;
    }
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.hintColor,
        letterSpacing: .3,
      ),
    );
  }
}

class _InsightBar extends StatelessWidget {
  const _InsightBar({
    required this.label,
    required this.value,
    required this.widthFactor,
  });

  final String label;
  final String value;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * widthFactor.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: AppColors.redColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LabeledValue {
  const _LabeledValue({
    required this.label,
    required this.value,
    required this.widthFactor,
  });

  final String label;
  final String value;
  final double widthFactor;
}

enum _DashboardStatTone { positive, warning, critical, neutral }

class _DashboardStatToneStyle {
  const _DashboardStatToneStyle(this.color);

  final Color color;
}

enum _AlertSeverity { critical, warning, info, success }

class _DashboardAlert {
  const _DashboardAlert({
    required this.title,
    required this.description,
    required this.severity,
  });

  final String title;
  final String description;
  final _AlertSeverity severity;
}

class _PulseMetricRow extends StatelessWidget {
  const _PulseMetricRow({
    required this.label,
    required this.value,
    required this.helper,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blackColor,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.hintColor,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress.clamp(0.0, 1.0),
            color: color,
            backgroundColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final _DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(alert.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AdminTag(
            label: style.label,
            backgroundColor: style.accent.withValues(alpha: 0.14),
            foregroundColor: style.accent,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  _AlertStyle _styleFor(_AlertSeverity severity) {
    switch (severity) {
      case _AlertSeverity.critical:
        return const _AlertStyle(
          label: 'Critical',
          accent: AppColors.redColor,
          border: Color(0xFFFFD5D1),
          background: Color(0xFFFFF3F2),
          icon: Icons.error_outline,
        );
      case _AlertSeverity.warning:
        return const _AlertStyle(
          label: 'Warning',
          accent: Colors.orange,
          border: Color(0xFFFFE2B3),
          background: Color(0xFFFFF7E8),
          icon: Icons.warning_amber_outlined,
        );
      case _AlertSeverity.info:
        return const _AlertStyle(
          label: 'Info',
          accent: Colors.blue,
          border: Color(0xFFD6E7FF),
          background: Color(0xFFF3F8FF),
          icon: Icons.info_outline,
        );
      case _AlertSeverity.success:
        return const _AlertStyle(
          label: 'Stable',
          accent: Colors.green,
          border: Color(0xFFD4F0D7),
          background: Color(0xFFF0FBF1),
          icon: Icons.verified_outlined,
        );
    }
  }
}

class _AlertStyle {
  const _AlertStyle({
    required this.label,
    required this.accent,
    required this.border,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color accent;
  final Color border;
  final Color background;
  final IconData icon;
}
