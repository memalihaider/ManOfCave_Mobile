import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<DateTime> availableDates;
  final Function(DateTime) onDateSelected;
  final Function(int) onMonthChanged;

  const CalendarWidget({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.availableDates,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(widget.currentMonth.year, widget.currentMonth.month, 1);
    final lastDay = DateTime(widget.currentMonth.year, widget.currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;
    final totalCells = ((daysInMonth + startingWeekday - 1) / 7).ceil() * 7;

    return Container(
      padding: AppSizes.paddingAll(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => widget.onMonthChanged(-1),
                icon: Icon(
                  Icons.chevron_left,
                  size: 24.sp,
                  color: AppColors.primaryGold,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                ),
              ),
              Text(
                _getMonthYear(widget.currentMonth),
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              IconButton(
                onPressed: () => widget.onMonthChanged(1),
                icon: Icon(
                  Icons.chevron_right,
                  size: 24.sp,
                  color: AppColors.primaryGold,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Week Days
          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),

          // Calendar Days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - startingWeekday + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                widget.currentMonth.year,
                widget.currentMonth.month,
                dayNumber,
              );

              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final isAvailable = widget.availableDates.any((d) => _isSameDay(d, date));
              final isPast = date.isBefore(DateTime.now()) && !isToday;

              return _buildCalendarDay(
                dayNumber.toString(),
                isSelected: isSelected,
                isToday: isToday,
                isAvailable: isAvailable,
                isPast: isPast,
                onTap: () => isAvailable && !isPast ? widget.onDateSelected(date) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
      String day, {
        required bool isSelected,
        required bool isToday,
        required bool isAvailable,
        required bool isPast,
        required VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold
              : isToday
              ? AppColors.primaryGold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(
            color: isToday && !isSelected
                ? AppColors.primaryGold
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.white
                    : isPast
                    ? Colors.grey[400]
                    : isAvailable
                    ? AppColors.primaryDark
                    : Colors.grey[500],
              ),
            ),
            if (isAvailable && !isPast)
              Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 6.w,
                height: 6.h,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}