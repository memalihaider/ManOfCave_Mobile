import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class TimePickerDialog extends StatefulWidget {
  const TimePickerDialog({super.key});

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  int _selectedHour = 9;
  int _selectedMinute = 0;
  String _selectedPeriod = 'AM';

  final List<int> hours = List.generate(12, (index) => index + 1);
  final List<int> minutes = [0, 15, 30, 45];
  final List<String> periods = ['AM', 'PM'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppSizes.spaceMedium16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppSizes.spaceMedium16),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge20),
                  topRight: Radius.circular(AppSizes.radiusLarge20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.white,
                    size: AppSizes.icon(24),
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: AppSizes.textLarge18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Time Display
            Padding(
              padding: EdgeInsets.all(AppSizes.spaceLarge24),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.spaceMedium16,
                  horizontal: AppSizes.spaceLarge24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                child: Text(
                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} $_selectedPeriod',
                  style: TextStyle(
                    fontSize: AppSizes.textExtraLarge22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),

            // Pickers Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceMedium16),
              child: Row(
                children: [
                  // Hour Picker
                  Expanded(
                    child: _buildPickerColumn(
                      title: 'Hour',
                      items: hours.map((h) => h.toString().padLeft(2, '0')).toList(),
                      selectedIndex: hours.indexOf(_selectedHour),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedHour = hours[index];
                        });
                      },
                    ),
                  ),

                  // Separator
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceSmall8),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: AppSizes.textExtraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),

                  // Minute Picker
                  Expanded(
                    child: _buildPickerColumn(
                      title: 'Minute',
                      items: minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                      selectedIndex: minutes.indexOf(_selectedMinute),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinute = minutes[index];
                        });
                      },
                    ),
                  ),

                  SizedBox(width: AppSizes.spaceMedium16),

                  // AM/PM Picker
                  Expanded(
                    child: _buildPickerColumn(
                      title: 'Period',
                      items: periods,
                      selectedIndex: periods.indexOf(_selectedPeriod),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedPeriod = periods[index];
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.spaceLarge24),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(AppSizes.spaceMedium16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(vertical: AppSizes.spaceMedium16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMedium16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Convert to TimeOfDay
                        int hourOfDay = _selectedHour;
                        if (_selectedPeriod == 'PM' && _selectedHour != 12) {
                          hourOfDay = _selectedHour + 12;
                        } else if (_selectedPeriod == 'AM' && _selectedHour == 12) {
                          hourOfDay = 0;
                        }

                        final selectedTime = TimeOfDay(
                          hour: hourOfDay,
                          minute: _selectedMinute,
                        );
                        Navigator.pop(context, selectedTime);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSizes.spaceMedium16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required String title,
    required List<String> items,
    required int selectedIndex,
    required void Function(int) onSelectedItemChanged,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          height: AppSizes.height(150),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: AppSizes.height(40),
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                final isSelected = index == selectedIndex;
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: isSelected ? AppSizes.textLarge18 : AppSizes.textMedium14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primaryGold : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}