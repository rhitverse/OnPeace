import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_peace/models/diary_model.dart';
import 'package:on_peace/screens/diary/repository/diary_repository.dart';

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
        errorMessage = "Data load failed: $e";
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addEntry({
    required String title,
    required String body,
    int weatherIndex = 0,
    int moodIndex = 0,
    List<File> mediaFiles = const [],
    List<String> mediaTypes = const [],
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty && mediaFiles.isEmpty)
      return;

    try {
      await _repo.addEntry(
        title,
        body,
        weatherIndex: weatherIndex,
        moodIndex: moodIndex,
        mediaFiles: mediaFiles,
        mediaTypes: mediaTypes,
      );

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = "Entry doesn't save: $e";
      notifyListeners();
    }
  }

  Future<void> updateEntry(String entryId, String newText) async {
    if (newText.trim().isEmpty) return;
    try {
      await _repo.updateEntry(entryId, newText.trim());
      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _entries[index] = _entries[index].copyWith(text: newText.trim());
      }
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = "Not Updated: $e";
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      _entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
      await _repo.deleteEntry(entryId);
    } catch (e) {
      errorMessage = "Delete failed :$e";
      notifyListeners();
    }
  }

  Future<void> updateEntryWithMedia({
    required String entryId,
    required String newTitle,
    required String newText,
    required List<String> existingUrls,
    required List<String> existingTypes,
    required List<String> urlsToDelete,
    required List<File> newFiles,
    required List<String> newTypes,
  }) async {
    try {
      await _repo.updateEntryWithMedia(
        entryId: entryId,
        newText: newText,
        newTitle: newTitle,
        existingUrls: existingUrls,
        urlsToDelete: urlsToDelete,
        newFiles: newFiles,
        newTypes: newTypes,
        existingTypes: existingTypes,
      );

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = "Update failed: $e";
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
