import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

class SocialAuthException implements Exception {
  const SocialAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firebase provider sign-in. Firebase keeps the provider session alive and
/// gives the app one consistent user profile for Google and Apple accounts.
class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      await _ensureFirebase();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const SocialAuthException('Google girişi ləğv edildi.');
      }
      final authentication = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return _userData(result.user, provider: 'google');
    } on SocialAuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw SocialAuthException(_firebaseMessage(error));
    } catch (error) {
      throw SocialAuthException('Google ilə giriş mümkün olmadı: $error');
    }
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      await _ensureFirebase();
      final rawNonce = DateTime.now().microsecondsSinceEpoch.toString();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: _appleWebOptions,
        nonce: nonce,
      );
      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const SocialAuthException('Apple hesabından token alınmadı.');
      }
      final credential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return _userData(result.user, provider: 'apple');
    } on SocialAuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw SocialAuthException(_firebaseMessage(error));
    } catch (error) {
      throw SocialAuthException('Apple ilə giriş mümkün olmadı: $error');
    }
  }

  WebAuthenticationOptions? get _appleWebOptions {
    final needsWebFlow = kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    if (!needsWebFlow) return null;
    if (ApiConfig.appleServiceId.isEmpty) {
      throw const SocialAuthException(
        'Apple girişi üçün APPLE_SERVICE_ID build parametrini təyin edin.',
      );
    }
    return WebAuthenticationOptions(
      clientId: ApiConfig.appleServiceId,
      redirectUri: Uri.parse(ApiConfig.appleRedirectUri),
    );
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  Map<String, dynamic> _userData(User? user, {required String provider}) {
    if (user == null) {
      throw const SocialAuthException('İstifadəçi məlumatı alınmadı.');
    }
    return {
      'id': user.uid,
      'name': user.displayName ?? user.email?.split('@').first ?? 'İstifadəçi',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'dateOfBirth': null,
      'photoUrl': user.photoURL,
      'authProvider': provider,
    };
  }

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Bu giriş üsulu Firebase Console-da aktiv deyil.';
      case 'account-exists-with-different-credential':
        return 'Bu e-poçt başqa giriş üsulu ilə qeydiyyatdan keçib.';
      case 'invalid-credential':
        return 'Giriş məlumatı etibarsızdır. Yenidən cəhd edin.';
      default:
        return 'Firebase autentifikasiya xətası: ${error.message ?? error.code}';
    }
  }
}
