import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusLevelBar extends StatelessWidget {
  final String status;
  final int completed;

  const StatusLevelBar({
    super.key,
    required this.status,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final levelGoal = _getLevelGoal(status);
    final progress = completed / levelGoal;
    final progressColor = _getColorByStatus(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
            Text(
              '$completed/$levelGoal project selesai',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0), // Memastikan nilai antara 0 dan 1
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 10.h,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ],
    );
  }

  int _getLevelGoal(String status) {
    switch (status) {
      case 'Intermediate':
        return 25;
      case 'Expert':
        return 40;
      case 'Beginner':
      default:
        return 10;
    }
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Intermediate':
        return Colors.blue.shade600;
      case 'Expert':
        return Colors.orange.shade800;
      case 'Beginner':
      default:
        return Colors.green.shade700;
    }
  }
}
