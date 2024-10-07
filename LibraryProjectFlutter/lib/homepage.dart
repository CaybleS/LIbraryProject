import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'book.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage(this.user, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void filterButtonClicked() {
    //TODO
  }

  void changeDisplay() {
    //TODO
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Expanded(child: SearchBar()),
                    IconButton(
                      onPressed: () => {filterButtonClicked()},
                      icon: const Icon(Icons.tune),
                      splashColor: Colors.white,
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[300]),
                        onPressed: () => {changeDisplay()},
                        child: const Text(
                          "All",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[300]),
                        onPressed: () => {changeDisplay()},
                        child: const Text(
                          "Favorites",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[300]),
                        onPressed: () => {changeDisplay()},
                        child: const Text(
                          "Lent",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ))
                  ],
                ),
                SizedBox(
                    height: 500,
                    child: ListView.builder(
                        itemCount: exampleLibrary.length,
                        itemBuilder: (BuildContext context, int index) {
                          Widget image;
                          if (exampleLibrary[index].imagePath != null) {
                            image = Image.asset(
                                exampleLibrary[index].imagePath.toString());
                          } else {
                            image = Image.asset("assets/No_Cover.jpg");
                          }
                          return Card(
                              margin: const EdgeInsets.all(5),
                              child: Row(children: [
                                SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: image,
                                ),
                                SizedBox(
                                    width: 250,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      verticalDirection: VerticalDirection.down,
                                      children: [
                                        Text(
                                          exampleLibrary[index].title,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 20),
                                          softWrap: true,
                                        ),
                                        Text(
                                          exampleLibrary[index].author,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ],
                                    )),
                              ]));
                        }))
              ],
            )));
  }
}
