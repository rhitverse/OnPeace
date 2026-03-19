import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:whatsapp_clone/common/encryption/encryption_service.dart';
import 'package:whatsapp_clone/common/enum/username_result.dart';
import 'package:whatsapp_clone/common/utils/common_cloudinary_repository.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/features/auth/otp_page.dart';
import 'package:whatsapp_clone/models/user_model.dart';
import 'package:whatsapp_clone/screens/mobile_screen_layout.dart';
import 'package:whatsapp_clone/screens/user/display_name.dart';
import 'package:whatsapp_clone/widgets/helpful_widgets/info_popup.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  Future<void> signInWithGoogle({required BuildContext context}) async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) return;

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await saveUserToFirestore(uid: user.uid, email: user.email);
      }
      await EncryptionService().setupKeys(user.uid);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isNewUser ? const DisplayName() : const MobileScreenLayout(),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        InfoPopup.show(context, "Google sign-in failed");
      }
    }
  }

  Future<void> signInWithPhone({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          showSnackBar(
            context: context,
            content: e.message ?? "Phone verification failed",
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpPage(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },

        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DisplayName()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context: context, content: e.message ?? "Invalid OTP");
    }
  }

  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final uid = _auth.currentUser?.uid;
      if (uid != null) await EncryptionService().setupKeys(uid);
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MobileScreenLayout()),
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> saveUserToFirestore({
    required String uid,
    String? email,
    String? phone,
  }) async {
    await _firestore.collection("users").doc(uid).set({
      "uid": uid,
      "email": email,
      "phone": phone,
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User creation failed',
      );
    }

    await user.sendEmailVerification();

    await saveUserToFirestore(uid: user.uid, email: user.email);
    await EncryptionService().setupKeys(user.uid);
  }

  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> saveUserDataToFirebase({
    required String displayname,
    required File? profilePic,
    required BuildContext context,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      final currentDisplayName = displayname.isNotEmpty
          ? displayname
          : (userData?['displayname'] ?? '');

      String photoUrl =
          userData?['profilePic'] ??
          'https://yt3.ggpht.com/a/default-user=s600-k-no-rp-mo';

      if (profilePic != null) {
        final cloudRepo = CommonCloudinaryRepository();
        if (photoUrl.contains('cloudinary')) {
          try {
            await cloudRepo.deleteFileFromCloudinary(photoUrl);
          } catch (_) {}
        }
        final uploaderUrl = await cloudRepo.storeFileToCloudinary(profilePic);

        if (uploaderUrl != null) {
          photoUrl = uploaderUrl;
        }
      }

      await _firestore.collection('users').doc(uid).update({
        'displayname': currentDisplayName,
        'profilePic': photoUrl,
      });
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context: context, content: e.toString());
      }
    }
  }

  Future<void> deleteProfilePicture({required BuildContext context}) async {
    try {
      final uid = _auth.currentUser!.uid;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData == null) return;

      final oldProfilePic = userData['profilePic'] as String?;

      if (oldProfilePic != null &&
          !oldProfilePic.contains('katie-notopoulos') &&
          oldProfilePic.contains('cloudinary')) {
        final cloudRepo = CommonCloudinaryRepository();
        await cloudRepo.deleteFileFromCloudinary(oldProfilePic);
      }
      const defaultPhotoUrl =
          'https://yt3.ggpht.com/a/default-user=s600-k-no-rp-mo';
      await _firestore.collection('users').doc(uid).update({
        'profilePic': defaultPhotoUrl,
      });

      if (context.mounted) {
        showSnackBar(context: context, content: 'Profile picture removed');
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to delete profile picture: ${e.toString()}',
        );
      }
    }
  }

  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'bio': '',
        'groupId': [],
        'username': null,
        'usernameSetAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UsernameResult> setUsername(String username) async {
    username = username.trim().toLowerCase();
    final uid = _auth.currentUser!.uid;
    final docRef = _firestore.collection('users').doc(uid);

    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    for (final doc in query.docs) {
      if (doc.id != uid) {
        return UsernameResult.alreadyExists;
      }
    }

    final userDoc = await docRef.get();
    final data = userDoc.data() ?? {};
    if (data['username'] == username) {
      return UsernameResult.success;
    }

    final Timestamp? usernameSetAt = data['usernameSetAt'];
    if (usernameSetAt != null) {
      final diffDays = DateTime.now().difference(usernameSetAt.toDate()).inDays;

      if (diffDays < 30) {
        return UsernameResult.toEarly;
      }
    }

    await docRef.update({
      'username': username,
      'usernameSetAt': FieldValue.serverTimestamp(),
    });

    return UsernameResult.success;
  }

  Future<void> updateUserBio(String bio) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({'bio': bio.trim()});
  }

  Future<void> saveUserBirthay({
    required String uid,
    required String birthday,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'birthday': birthday,
    });
  }

  Future<void> updateBirthday({
    required BuildContext context,
    required DateTime dob,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;

      final formattedDob =
          "${dob.year.toString().padLeft(4, '0')}-"
          "${dob.month.toString().padLeft(2, '0')}-"
          "${dob.day.toString().padLeft(2, '0')}";

      await saveUserBirthay(uid: uid, birthday: formattedDob);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update birthday")),
      );
    }
  }

  Stream<UserModel> getUserData() {
    final uid = _auth.currentUser!.uid;

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      return UserModel.fromMap(snapshot.data()!);
    });
  }
}
