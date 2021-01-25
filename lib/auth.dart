import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final _googleSignIn = GoogleSignIn();
  final _firebaseAuth = FirebaseAuth.instance;

  Future<void> signIn() async {
    final googleSignInAccount = await _googleSignIn.signIn();
    final googleAuth = await googleSignInAccount.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _firebaseAuth.signOut();
  }
}