part of 'admin_category_screen.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.blackColor,
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: AppColors.redColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.check, size: 16, color: AppColors.redColor),
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
