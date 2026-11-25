/// Portal-canonical booking statuses: upcoming | in-progress | cancelled | closed
class BookingStatusValues {
  static const upcoming = 'upcoming';
  static const inProgress = 'in-progress';
  static const cancelled = 'cancelled';
  static const closed = 'closed';

  static const all = <String>[upcoming, inProgress, cancelled, closed];

  static const labels = <String, String>{
    upcoming: 'Upcoming',
    inProgress: 'Check-in',
    cancelled: 'Cancelled',
    closed: 'Closed',
  };

  /// Map any legacy/stored status to one of the 4 canonical values.
  static String normalize(String? status) {
    final normalized = (status ?? '').toLowerCase().trim();

    if (normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'rejected') {
      return cancelled;
    }

    if (normalized == 'closed' ||
        normalized == 'completed' ||
        normalized == 'delivered' ||
        normalized == 'paid') {
      return closed;
    }

    if (normalized == 'in-progress' ||
        normalized == 'in_progress' ||
        normalized == 'checked-in' ||
        normalized == 'checkedin' ||
        normalized == 'checkin') {
      return inProgress;
    }

    // Created / booked (including legacy pending/scheduled/approved/rescheduled)
    return upcoming;
  }

  static bool isActive(String? status) {
    final value = normalize(status);
    return value == upcoming || value == inProgress;
  }
}
