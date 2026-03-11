import 'package:flutter/material.dart';
import 'package:whatsapp_clone/models/diary_model.dart';
import 'package:whatsapp_clone/screens/diary/repository/diary_repository.dart';

class DiaryController extends ChangeNotifier {
  final DiaryRepository _repo = DiaryRepository();

  List<DiaryModel> _entries = [];
  bool isLoading = false;
  String? errorMessage;
  List<DiaryModel> get entries => _entries;

  void listenToEntries() {
    isLoading = true;
    notifyListeners();

    _repo.getEntriesStream().listen(
      (data) {
        _entries = data;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = "Data load nahi hua: $e";
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addEntry(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _repo.addEntry(text.trim());
    } catch (e) {
      errorMessage = "Entry doesn't save: $e";
      notifyListeners();
    }
  }

  Future<void> updateEntry(String entryId, String newText) async {
    if (newText.trim().isEmpty) return;
    try {
      await _repo.updateEntry(entryId, newText.trim());
    } catch (e) {
      errorMessage = "Not Updated: $e";
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _repo.deleteEntry(entryId);
    } catch (e) {
      errorMessage = "Delete failed :$e";
      notifyListeners();
    }
  }

  List<DiaryModel> entriesForMonth(int month, int year) {
    final monthNames = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return _entries
        .where((e) => e.month == monthNames[month] && e.createdAt.year == year)
        .toList();
  }

  List<DiaryModel> entriesForDay(DateTime day) {
    return _entries
        .where(
          (e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day,
        )
        .toList();
  }
}
