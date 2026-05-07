import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic.dart';

class TopicStatusBadge extends StatelessWidget {
  final int status;
  final bool showIcon;

  const TopicStatusBadge({super.key, required this.status, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 0:
        color = AppTheme.onSurfaceMuted;
        label = 'Not Started';
        icon = Icons.radio_button_unchecked_rounded;
        break;
      case 1:
        color = AppTheme.warning;
        label = 'In Progress';
        icon = Icons.timelapse_rounded;
        break;
      case 2:
        color = AppTheme.success;
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      default:
        color = AppTheme.onSurfaceMuted;
        label = 'Not Started';
        icon = Icons.radio_button_unchecked_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
