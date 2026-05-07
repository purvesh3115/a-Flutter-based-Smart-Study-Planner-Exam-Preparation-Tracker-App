import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubjectProgressCard extends StatelessWidget {
  final String subjectName;
  final double completion;
  final int topicCount;
  final Color color;
  final bool isLowest;
  final VoidCallback? onTap;

  const SubjectProgressCard({
    super.key,
    required this.subjectName,
    required this.completion,
    required this.topicCount,
    required this.color,
    this.isLowest = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completion * 100).toStringAsFixed(0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowest
                ? AppTheme.accent.withOpacity(0.5)
                : color.withOpacity(0.2),
            width: isLowest ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subjectName,
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLowest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Needs Attention',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completion,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$topicCount topic${topicCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
