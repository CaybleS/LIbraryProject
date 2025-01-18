import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/appbar.dart';

class Profile extends StatefulWidget {
  final User user;

  const Profile(this.user, {super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: displayAppBar(context, widget.user, "profile"),
        backgroundColor: Colors.grey[400],
        body: Card(
            margin: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 100,
                          child: _auth.currentUser!.photoURL != null
                              ? Image.network(
                                  _auth.currentUser!.photoURL!,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  "assets/profile_pic.jpg",
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _auth.currentUser!.displayName!,
                            style: const TextStyle(fontSize: 30),
                          ),
                          Text(
                            _auth.currentUser!.email!,
                            style: const TextStyle(fontSize: 20),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(129, 199, 132, 1)),
                          onPressed: () => {},
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          )),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(129, 199, 132, 1)),
                          onPressed: () => {},
                          child: const Text(
                            "Friends: 12",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Card(
                    color: Colors.blue[200],
                    child: SizedBox(
                        height: 130,
                        width: 500,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            "Generic long bio text. I am going to say a few things. This is a profile. A person is going to talk about themselves in a few sentences. Let's get things going.",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        )),
                  )
                ],
              ),
            )));
  }
}
