import 'package:flutter/material.dart';

/// Holds the currently selected date for dashboard calculations.
class DateProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  /// Updates the selected date/time and notifies listeners if changed.
  void setDate(DateTime date) {
    if (!_selectedDate.isAtSameMomentAs(date)) {
      _selectedDate = date;
      notifyListeners();
    }
  }
}
