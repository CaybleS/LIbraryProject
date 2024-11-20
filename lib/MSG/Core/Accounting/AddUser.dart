import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../Models/AppUser.dart';


final dbReference = FirebaseDatabase.instance.ref();

Future<void> addUserProperties(String userId, Map<String, dynamic> properties) async {

  await dbReference.child('users').child(userId).update(properties);
}

Future<bool> userExists(String id) async {
  DatabaseEvent event = await dbReference.child('users/$id').once();
  return (event.snapshot.value != null);
}

void addUser(User user ,AppUser appUser) {
  dbReference.child('users/${user.uid}');
  addUserProperties(user.uid ,appUser.toMap());
}
