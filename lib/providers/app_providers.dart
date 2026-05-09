import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../const/app_config.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

// Current user provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((
  ref,
) {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        // Validate the data before creating user
        if (userData is Map<String, dynamic> &&
            userData['name'] is String &&
            userData['linkedinUrl'] is String) {
          state = User.fromJson(userData);
        } else {
          // Clear corrupted data
          await prefs.remove('current_user');
        }
      }
    } catch (e) {
      // Clear corrupted data on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    }
  }

  Future<void> updateUser(User user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    state = null;
  }

  Future<void> addScannedBox(int boxId) async {
    if (state != null) {
      final updatedUser = state!.copyWith(
        scannedBoxes: {...state!.scannedBoxes, boxId},
      );
      await updateUser(updatedUser);
    }
  }
}

// Firebase Realtime Database Service for Questions
class QuestionService {
  static FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://namma-bingo-d007c-default-rtdb.firebaseio.com/',
  );

  static Future<List<String>> fetchQuestions() async {
    try {
      final snapshot = await _db.ref('questions').get();
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is List) {
          return data.map((e) => e.toString()).toList()..shuffle();
        } else if (data is Map) {
          // Handle map if keys are indices
          final List<String> questions = [];
          final sortedKeys = data.keys.toList()
            ..sort(
              (a, b) =>
                  int.parse(a.toString()).compareTo(int.parse(b.toString())),
            );
          for (var key in sortedKeys) {
            questions.add(data[key].toString());
          }
          return questions..shuffle();
        }
      }
      return []; // Return empty list instead of fallback
    } catch (e) {
      debugPrint('Error fetching questions from Firebase: $e');
      return []; // Return empty list on error
    }
  }
}

// Dynamic questions provider
final questionsProvider = FutureProvider<List<String>>((ref) async {
  return QuestionService.fetchQuestions();
});

// Bingo boxes state provider
final bingoBoxesProvider =
    StateNotifierProvider<BingoBoxesNotifier, List<BingoBox>>((ref) {
      return BingoBoxesNotifier();
    });

class BingoBoxesNotifier extends StateNotifier<List<BingoBox>> {
  List<String> _questions = [];

  BingoBoxesNotifier() : super([]) {
    _loadBoxes();
  }

  static List<BingoBox> _generateInitialBoxes(int count) {
    return List.generate(count, (index) => BingoBox(id: index + 1));
  }

  void updateQuestions(List<String> newQuestions) {
    _questions = newQuestions;
    // If we have more questions than current state, expand it
    if (newQuestions.length > state.length) {
      final additional = List.generate(
        newQuestions.length - state.length,
        (index) => BingoBox(id: state.length + index + 1),
      );
      state = [...state, ...additional];
      _saveBoxes();
    }
  }

  Future<void> _loadBoxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boxesJson = prefs.getString('bingo_boxes');
      if (boxesJson != null) {
        final List<dynamic> boxesData = jsonDecode(boxesJson);
        final List<BingoBox> boxes = boxesData.map((boxData) {
          return BingoBox(
            id: boxData['id'] ?? 0,
            isSelected: boxData['isSelected'] ?? false,
            scannedBy: boxData['scannedBy'],
            scannedByName: boxData['scannedByName'],
            scannedByProfilePicture: boxData['scannedByProfilePicture'],
            scannedByLinkedIn: boxData['scannedByLinkedIn'],
            questionAnswered: boxData['questionAnswered'],
            scannedAt: boxData['scannedAt'] != null
                ? DateTime.tryParse(boxData['scannedAt'])
                : null,
          );
        }).toList();

        // Ensure we have all required boxes
        if (boxes.length >= _questions.length) {
          state = boxes;
        } else {
          state = _generateInitialBoxes(_questions.length);
          await _saveBoxes();
        }
      } else {
        state = _generateInitialBoxes(_questions.length);
        await _saveBoxes();
      }
    } catch (e) {
      // If there's an error loading, start fresh
      state = _generateInitialBoxes(_questions.length);
      await _saveBoxes();
    }
  }

  Future<void> _saveBoxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final boxesData = state
          .map(
            (box) => {
              'id': box.id,
              'isSelected': box.isSelected,
              'scannedBy': box.scannedBy,
              'scannedByName': box.scannedByName,
              'scannedByProfilePicture': box.scannedByProfilePicture,
              'scannedByLinkedIn': box.scannedByLinkedIn,
              'questionAnswered': box.questionAnswered,
              'scannedAt': box.scannedAt?.toIso8601String(),
            },
          )
          .toList();
      await prefs.setString('bingo_boxes', jsonEncode(boxesData));
    } catch (e) {
      // Handle save error silently
      debugPrint('Error saving boxes: $e');
    }
  }

  void selectBox(
    int boxId,
    String scannedBy,
    String scannedByName,
    String? profilePictureUrl, {
    String? linkedInUrl,
    String? questionAnswered,
  }) {
    state = state.map((box) {
      if (box.id == boxId) {
        return box.copyWith(
          isSelected: true,
          scannedBy: scannedBy,
          scannedByName: scannedByName,
          scannedByProfilePicture: profilePictureUrl,
          scannedByLinkedIn: linkedInUrl,
          questionAnswered: questionAnswered,
          scannedAt: DateTime.now(),
        );
      }
      return box;
    }).toList();

    // Save to local storage
    _saveBoxes();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bingo_boxes');
    state = _generateInitialBoxes(_questions.length);
    await _saveBoxes();
  }

  bool isBoxScanned(int boxId) {
    return state.firstWhere((box) => box.id == boxId).isSelected;
  }

  int get completedCount {
    return state.where((box) => box.isSelected).length;
  }

  String getCurrentQuestion() {
    final completed = completedCount;
    if (completed < _questions.length) {
      return _questions[completed];
    }
    return "All questions completed!";
  }

  List<String> getCompletedQuestions() {
    final completed = completedCount;
    return _questions.take(completed).toList();
  }

  String getQuestionForBox(int boxId) {
    if (boxId > 0 && boxId <= _questions.length) {
      return _questions[boxId - 1];
    }
    return "No question available";
  }

  int get questionsCount => _questions.length;
}

// Scan status provider
final scanStatusProvider = StateProvider<String?>((ref) => null);
