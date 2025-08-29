import 'dart:async';
import 'package:flutter/material.dart';

/// Holds the currently selected date for dashboard calculations.
class DateProvider extends ChangeNotifier {
  DateTime _selectedDate = _normalize(DateTime.now());
  Timer? _timer;

  DateProvider() {
    _scheduleNextTick();
  }

  DateTime get selectedDate => _selectedDate;

  /// Updates the selected date/time and notifies listeners if changed.
  void setDate(DateTime date) {
    final normalized = _normalize(date);
    if (!_selectedDate.isAtSameMomentAs(normalized)) {
      _selectedDate = normalized;
      notifyListeners();
    }
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    final duration = next.difference(now);
    _timer = Timer(duration, () {
      setDate(DateTime.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns the start of the current hour for today's date
  /// or midnight for historical dates.
  static DateTime _normalize(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateTime(now.year, now.month, now.day, now.hour);
    }
    return DateTime(date.year, date.month, date.day);
  }
}
