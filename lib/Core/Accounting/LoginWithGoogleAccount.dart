import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Models/AppUser.dart';
import 'AddUser.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<User?> signInWithGoogle() async {
  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication? googleSignInAuthentication =
  await googleSignInAccount?.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken);

  final UserCredential userCredential =
  await _auth.signInWithCredential(credential);
  final User? user = userCredential.user;
  const AppUser? appUser = null;
  if (user != null) {
    assert(!user.isAnonymous);
    final User currentUser = _auth.currentUser!;
    assert(currentUser.uid == user.uid);
    if (!(await userExists(user.uid))) {
      addUser(user , appUser!);
    }
    return user;
  } else {
    return null;
  }
}

void signOutGoogle() async {
  await googleSignIn.signOut();
}

User? loginClick() {
  User? userInstance;
  signInWithGoogle().then((user) => {
    if (user != null)
      {userInstance = user}
  });
  return userInstance;
}