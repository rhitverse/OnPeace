import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_peace/common/enum/username_result.dart';
import 'package:on_peace/features/auth/repository/auth_repository.dart';
import 'package:on_peace/features/auth/repository/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/screens/user/display_name.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authControllerProvider = Provider(
  (ref) => AuthController(
    authRepository: ref.read(authRepositoryProvider),
    ref: ref,
  ),
);

class AuthController {
  Future<void> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    await _authRepository.sendPasswordResetEmail(
      context: context,
      email: email,
    );
  }

  final AuthRepository _authRepository;
  final ProviderRef ref;
  AuthController({required AuthRepository authRepository, required this.ref})
    : _authRepository = authRepository;

  Future<void> signInWithGoogle({required BuildContext context}) async {
    await _authRepository.signInWithGoogle(context: context);
    await _authRepository.ensureUserDocument();
  }

  Future<void> signInWithPhone({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    await _authRepository.signInWithPhone(
      context: context,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.signInWithEmail(
        context: context,
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "User doesn't exist";
          break;

        case 'wrong-password':
          message = "Incorrect password";
          break;

        case 'invalid-credential':
          message =
              "This email is registered with Google. Please use Google Sign-In.";
          break;

        case 'invalid-email':
          message = "Invalid email address";
          break;

        case 'user-disabled':
          message = "This account has been disabled";
          break;

        case 'too-many-requests':
          message = "Too many attempts. Try again later";
          break;

        default:
          message = "Login failed. Please try again";
      }

      InfoPopup.show(context, message);
    }
  }

  Future<void> signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.signUpWithEmail(email: email, password: password);

      if (!context.mounted) return;

      InfoPopup.show(
        context,
        "Account created! Please check your email to verify your account",
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DisplayName()),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "This email is already registered";
          break;
        case 'weak-password':
          message = "Password should be at least 6 characters";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        default:
          message = e.message ?? "Signup failed";
      }

      InfoPopup.show(context, message);
      rethrow;
    } catch (e) {
      if (!context.mounted) return;
      InfoPopup.show(context, "An error occurred. Please try again");
    }
  }

  Future<void> verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String otp,
  }) async {
    await _authRepository.verifyOtp(
      context: context,
      verificationId: verificationId,
      otp: otp,
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> saveUserDataToFirebase(
    BuildContext context,
    String displayname,
    File? profilePic,
  ) async {
    _authRepository.saveUserDataToFirebase(
      displayname: displayname,
      profilePic: profilePic,
      context: context,
    );
  }

  Future<UsernameResult> setUsername({required String username}) async {
    final result = await _authRepository.setUsername(username);
    return result;
  }

  Future<void> updateBirthday({
    required BuildContext context,
    required DateTime dob,
  }) async {
    await _authRepository.updateBirthday(context: context, dob: dob);
  }

  Future<void> updateShowBirthday(bool value) async {
    await _authRepository.updateShowBirthday(value);
  }

  Future<void> updateShowBirthYear(bool value) async {
    await _authRepository.updateShowBirthYear(value);
  }

  Future<void> updateBio(String bio) async {
    await _authRepository.updateUserBio(bio);
  }

  Future<void> deleteProfilePicture({required BuildContext context}) async {
    await _authRepository.deleteProfilePicture(context: context);
  }
}
