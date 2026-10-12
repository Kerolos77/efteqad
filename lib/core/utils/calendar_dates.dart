/// Local calendar-day arithmetic: DST days may contain23 or25 hours.
/// Constructing a day offset preserves date membership and local day boundaries.
DateTime calendarDay(DateTime date, [int offsetDays = 0]) =>
    DateTime(date.year, date.month, date.day + offsetDays);
