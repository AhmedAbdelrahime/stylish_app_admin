part of 'admin_user_screen.dart';

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
                backgroundImage: user.image?.trim().isNotEmpty == true
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
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                  ),
                  label: const Text('Make admin'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
