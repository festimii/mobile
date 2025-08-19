import 'package:flutter/material.dart';

/// Holds the currently selected date for dashboard calculations.
class DateProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  /// Updates the selected date and notifies listeners if changed.
  void setDate(DateTime date) {
    if (!_isSameDay(_selectedDate, date)) {
      _selectedDate = date;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
