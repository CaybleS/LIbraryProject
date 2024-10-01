import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<User?> signInWithGoogle() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication? googleSignInAuthentication = await googleSignInAccount?.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
    idToken: googleSignInAuthentication?.idToken,
    accessToken: googleSignInAuthentication?.accessToken
  );

  final UserCredential userCredential = await _auth.signInWithCredential(credential);
  final User? user = userCredential.user;

  if (user != null) {
    assert(!user.isAnonymous);

    final User currentUser = _auth.currentUser!;
    assert(currentUser.uid == user.uid);

    return user;
  } else {
    return null;
  }
}

void signOutGoogle() async {
  await googleSignIn.signOut();
}