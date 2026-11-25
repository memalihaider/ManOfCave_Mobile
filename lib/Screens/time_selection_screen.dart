import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/booking_controller.dart';
import '../controlers/branches_controller.dart';
import '../models/booking_model.dart';
import '../models/branch_model.dart';
import '../widgets/elevated_button.dart';
import '../widgets/service_dummy_card.dart';
import 'staff_selection_screen.dart';

class TimeSelectionScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final int serviceDuration;
  final double servicePrice;
  final String branchName;
  final String branchAddress;

  const TimeSelectionScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDuration,
    required this.servicePrice,
    required this.branchName,
    required this.branchAddress,
  });

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  // ========== CONTROLLERS ==========
  final BookingController _bookingController = Get.find<BookingController>();
  final BranchController _branchController = Get.find<BranchController>();

  // ========== STATE VARIABLES ==========
  DateTime? _selectedDate;
  String? _selectedTime;
  List<Booking> _existingBookingsForDate = [];
  List<TimeSlot> _availableTimeSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ========== BRANCH TIMING INFO ==========
  String? _branchOpeningTime;
  String? _branchClosingTime;
  bool _isBranchOpenToday = true;
  Branch? _selectedBranch;

  // ========== INIT ==========
  @override
  void initState() {
    super.initState();
    _loadBranchData();
  }

  // ========== BRANCH DATA LOADING ==========
  Future<void> _loadBranchData() async {
    setState(() => _isLoading = true);

    try {
      // Find selected branch
      for (var branch in _branchController.branches) {
        if (branch.name == widget.branchName) {
          _selectedBranch = branch;
          break;
        }
      }

      if (_selectedBranch != null) {
        // Get today's timings
        final todayName = _getDayName(DateTime.now().weekday).toLowerCase();
        final todayTiming = _selectedBranch!.weeklyTimings[todayName];

        if (todayTiming != null) {
          _branchOpeningTime = todayTiming.opening;
          _branchClosingTime = todayTiming.closing;
          _isBranchOpenToday = !todayTiming.closed;
        } else {
          // Fallback to default hours
          _branchOpeningTime = _selectedBranch!.openingTime;
          _branchClosingTime = _selectedBranch!.closingTime;
          _isBranchOpenToday = true;
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading branch data';
      print('Error loading branch data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== DATE SELECTION ==========
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.primaryDark,
            ),
            dialogBackgroundColor: AppColors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableTimeSlots = [];
      });

      // Load bookings for this specific date
      await _loadBookingsForDate(picked);

      // Generate time slots based on branch hours
      _generateTimeSlotsForDate(picked);
    }
  }

  // ========== LOAD BOOKINGS FOR SELECTED DATE ==========
  Future<void> _loadBookingsForDate(DateTime date) async {
    setState(() => _isLoading = true);

    try {
      _existingBookingsForDate = await _bookingController.loadBookingsForDate(
        date: date,
        branchName: widget.branchName,
      );

      print('📅 Found ${_existingBookingsForDate.length} bookings for ${_formatDate(date)}');
    } catch (e) {
      _errorMessage = 'Error loading bookings';
      print('Error loading bookings for date: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== GENERATE TIME SLOTS ==========
  void _generateTimeSlotsForDate(DateTime date) {
    if (_selectedBranch == null ||
        _branchOpeningTime == null ||
        _branchClosingTime == null) {
      return;
    }

    final dayName = _getDayName(date.weekday).toLowerCase();
    final dayTiming = _selectedBranch!.weeklyTimings[dayName];

    // Check if branch is closed on this day
    if (dayTiming != null && dayTiming.closed) {
      setState(() {
        _availableTimeSlots = [];
      });
      return;
    }

    // Parse opening and closing times
    final openingParts = (dayTiming?.opening ?? _branchOpeningTime!)
        .split(':')
        .map(int.parse)
        .toList();
    final closingParts = (dayTiming?.closing ?? _branchClosingTime!)
        .split(':')
        .map(int.parse)
        .toList();

    final openingTime = DateTime(
      date.year, date.month, date.day,
      openingParts[0], openingParts[1],
    );
    final closingTime = DateTime(
      date.year, date.month, date.day,
      closingParts[0], closingParts[1],
    );

    // Get current time for today's date comparison
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    // Generate time slots based on service duration (e.g., 30 mins)
    final List<TimeSlot> slots = [];
    var currentSlot = openingTime;

    while (currentSlot.isBefore(closingTime)) {
      final slotEnd = currentSlot.add(Duration(minutes: widget.serviceDuration));

      // Check if slot fits within branch hours
      if (slotEnd.isBefore(closingTime) || slotEnd.isAtSameMomentAs(closingTime)) {

        // ========== TODAY'S DATE LOGIC ==========
        // If it's today, only show slots that are in the future
        if (isToday && currentSlot.isBefore(now)) {
          // Skip past slots
          currentSlot = currentSlot.add(Duration(minutes: widget.serviceDuration));
          continue;
        }

        final timeString = _formatTimeForDisplay(currentSlot);
        final timeValue = _formatTimeOfDayFromDateTime(currentSlot);

        // Check if this time slot is already booked
        final isBooked = _existingBookingsForDate.any((booking) =>
        booking.time == timeString
        );

        slots.add(TimeSlot(
          displayTime: timeString,
          value: timeString,
          dateTime: currentSlot,
          isBooked: isBooked,
        ));
      }

      currentSlot = currentSlot.add(Duration(minutes: widget.serviceDuration));
    }

    setState(() {
      _availableTimeSlots = slots;
    });
  }

  // ========== TIME SLOT SELECTION ==========
  void _selectTimeSlot(TimeSlot slot) {
    if (slot.isBooked) {
      Get.snackbar(
        'Time Slot Unavailable',
        'This time is already booked. Please select another time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: AppColors.white,
        margin: EdgeInsets.all(AppSizes.spaceMedium16),
        borderRadius: AppSizes.radiusMedium12,
      );
      return;
    }

    setState(() {
      _selectedTime = slot.value;
    });
  }

  // ========== PROCEED TO BOOKING ==========
  void _proceedToBooking() {
    if (_selectedDate == null || _selectedTime == null) {
      Get.snackbar(
        'Missing Information',
        'Please select both date and time',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(AppSizes.spaceMedium16),
        borderRadius: AppSizes.radiusMedium12,
      );
      return;
    }

    // Find the selected time slot to get display format
    TimeSlot? selectedSlot;
    for (var slot in _availableTimeSlots) {
      if (slot.value == _selectedTime) {
        selectedSlot = slot;
        break;
      }
    }

    final String formattedTime = selectedSlot?.displayTime ?? _selectedTime!;

    Get.to(() => StaffSelectionScreen(
      selectedDate: _selectedDate!,
      selectedTime: formattedTime,
      serviceName: widget.serviceName,
      serviceDuration: widget.serviceDuration,
      servicePrice: widget.servicePrice,
      branchName: widget.branchName,
      branchAddress: widget.branchAddress,
      serviceId: widget.serviceId,
    ));
  }

  // ========== FORMATTING HELPERS ==========
  String _formatTimeOfDayFromDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeForDisplay(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTimeString(String? time) {
    if (time == null) return '';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }

  // ========== CHECK IF DATE IS TODAY ==========
  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // ========== BUILD UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Select Date & Time',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryGold,
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.spaceMedium16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Summary Card
                  ServiceSummaryCard(
                    serviceName: widget.serviceName,
                    duration: widget.serviceDuration,
                    price: widget.servicePrice,
                    branchName: widget.branchName,
                    branchAddress: widget.branchAddress,
                  ),

                  SizedBox(height: AppSizes.spaceLarge24),

                  // Branch Hours Card
                  if (_branchOpeningTime != null && _branchClosingTime != null)
                    _buildBranchHoursCard(),

                  SizedBox(height: AppSizes.spaceLarge24),

                  // Date Selection Section
                  _buildDateSelectionSection(),

                  SizedBox(height: AppSizes.spaceLarge24),

                  // Time Selection Section
                  if (_selectedDate != null) _buildTimeSelectionSection(),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildBranchHoursCard() {
    return Container(
      padding: EdgeInsets.all(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: AppSizes.iconMedium24,
            color: AppColors.primaryGold,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch Hours Today',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${_formatTimeString(_branchOpeningTime)} - ${_formatTimeString(_branchClosingTime)}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: _isBranchOpenToday ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.spaceSmall8,
              vertical: AppSizes.spaceSmall8,
            ),
            decoration: BoxDecoration(
              color: _isBranchOpenToday
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
            ),
            child: Text(
              _isBranchOpenToday ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: _isBranchOpenToday ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),

        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Container(
            padding: EdgeInsets.all(AppSizes.spaceMedium16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryGold,
                    size: AppSizes.iconMedium24,
                  ),
                ),
                SizedBox(width: AppSizes.spaceMedium16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Text(
                        _selectedDate != null
                            ? '${_getDayName(_selectedDate!.weekday)}, ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                          color: _selectedDate != null
                              ? AppColors.primaryDark
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryGold,
                  size: AppSizes.iconMedium24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Time',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedDate != null && _isDateToday(_selectedDate!))
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.spaceSmall8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  'Future slots only',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        if (_availableTimeSlots.isEmpty)
          _buildEmptyTimeSlots()
        else
          _buildTimeSlotsGrid(),

        SizedBox(height: AppSizes.spaceMedium16),

        if (_existingBookingsForDate.isNotEmpty)
          _buildBookingsInfo(),
      ],
    );
  }

  Widget _buildEmptyTimeSlots() {
    return Container(
      padding: EdgeInsets.all(AppSizes.spaceLarge24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_filled,
            size: AppSizes.iconLarge60,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'No time slots available',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            _selectedDate != null && _isDateToday(_selectedDate!)
                ? 'All slots for today have passed. Please select another date.'
                : 'Please select another date',
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.spaceSmall8,
        mainAxisSpacing: AppSizes.spaceSmall8,
        childAspectRatio: 1.5,
      ),
      itemCount: _availableTimeSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableTimeSlots[index];
        final isSelected = _selectedTime == slot.value;

        return InkWell(
          onTap: () => _selectTimeSlot(slot),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Container(
            decoration: BoxDecoration(
              color: slot.isBooked
                  ? Colors.grey[200]
                  : isSelected
                  ? AppColors.primaryGold
                  : AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              border: Border.all(
                color: slot.isBooked
                    ? Colors.grey[400]!
                    : isSelected
                    ? AppColors.primaryGold
                    : AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.displayTime,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: slot.isBooked
                        ? FontWeight.normal
                        : isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: slot.isBooked
                        ? Colors.grey[500]
                        : isSelected
                        ? AppColors.white
                        : AppColors.primaryDark,
                    decoration: slot.isBooked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (slot.isBooked)
                  Padding(
                    padding: EdgeInsets.only(top: AppSizes.spaceSmall8),
                    child: Icon(
                      Icons.block,
                      size: AppSizes.iconSmall14,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsInfo() {
    return Container(
      padding: EdgeInsets.all(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppSizes.iconMedium24,
            color: Colors.orange,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Text(
              '${_existingBookingsForDate.length} booking${_existingBookingsForDate.length > 1 ? 's' : ''} already scheduled for this date',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.all(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedDate != null && _selectedTime != null)
              _buildSelectedInfo(),
            CustomElevatedButton(
              onPressed: _proceedToBooking,
              text: "Continue to Staff Selection",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInfo() {
    return Container(
      padding: EdgeInsets.all(AppSizes.spaceMedium16),
      margin: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.primaryGold,
              size: AppSizes.iconMedium24,
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Appointment',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                Text(
                  '${_getDayName(_selectedDate!.weekday)}, ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} • ${_formatTimeString(_selectedTime)}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== TIME SLOT MODEL ==========
class TimeSlot {
  final String displayTime;
  final String value;
  final DateTime dateTime;
  final bool isBooked;

  TimeSlot({
    required this.displayTime,
    required this.value,
    required this.dateTime,
    required this.isBooked,
  });
}