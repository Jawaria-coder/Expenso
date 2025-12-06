import 'package:local_auth/local_auth.dart';

class FingerprintAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    return await _auth.canCheckBiometrics;
  }

  Future<bool> authenticate() async {
    bool isAuthenticated = false;

    try {
      while (!isAuthenticated) {
        isAuthenticated = await _auth.authenticate(
          localizedReason: 'Please authenticate using your fingerprint',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true, // Attempts to keep the auth active
          ),
        );

        if (!isAuthenticated) {
          print("Authentication required to continue.");
        }

      }
      return true;
    } catch (e) {
      print('Error using fingerprint: $e');
      return false;
    }
  }
}