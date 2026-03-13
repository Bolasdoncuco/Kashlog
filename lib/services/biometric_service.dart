import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('BiometricService: Error checking support: ${e.message}');
      return false;
    }
  }

  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      print('BiometricService: Error checking enrollment: ${e.message}');
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a KashLog',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Prioritize biometrics, fallback to app PIN handled manually
        ),
      );
    } on PlatformException catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }
}
