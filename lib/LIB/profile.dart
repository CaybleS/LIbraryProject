import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'appbar.dart';

class Profile extends StatelessWidget {
  final User user;
  const Profile(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: displayAppBar(context, user, "profile"),
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
                              child: Image.asset(
                                "assets/profile_pic.jpg",
                                fit: BoxFit.cover,
                              ))),
                      const Column(children: [
                        Text(
                          "Profile Name",
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          "Friend Id",
                          style: TextStyle(fontSize: 20),
                        )
                      ])
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
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
                          padding: EdgeInsets.all(10),
                          child: Text(
                              "Generic long bio text. I am going to say a few things. This is a profile. A person is going to talk about themselves in a few sentences. Let's get things going.",
                              style: TextStyle(color: Colors.black, fontSize: 18),),
                        )),
                  )
                ],
              ),
            )));
  }
}
