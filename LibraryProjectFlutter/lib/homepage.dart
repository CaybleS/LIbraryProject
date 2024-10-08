import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'book.dart';

class HomePage extends StatefulWidget {
  final User user;
  String showing = "all";
  List<int> shownList = [];

  HomePage(this.user, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();

    widget.shownList = Iterable<int>.generate(exampleLibrary.length).toList();
  }

  void filterButtonClicked() {
    //TODO
  }

  Future<void> changeDisplay(String state) async {
    await updateList(state);

    setState(() {
      widget.showing = state;
    });
  }

  Future<void> updateList(String state) async {
    widget.shownList.clear();

    switch (state) {
      case "all":
        widget.shownList = Iterable<int>.generate(exampleLibrary.length).toList();
        break;
      case "fav":
        for (int i = 0; i < exampleLibrary.length; i++) {
          if (exampleLibrary[i].favorite) {
            widget.shownList.add(i);
          }
        }
        break;
      case "lent":
        for (int i = 0; i < exampleLibrary.length; i++) {
          if (!exampleLibrary[i].available) {
            widget.shownList.add(i);
          }
        }
        break;
      default:
        break;
    }

    setState(() {
      widget.showing = state;
    });
  }

  void favoriteButtonClicked(int index) {
    exampleLibrary[index].favorite = !exampleLibrary[index].favorite;
    setState(() {});
  }

  Widget displayShowButtons() {
    List<Color> buttonColor = [
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1)
    ];

    switch (widget.showing) {
      case "all":
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "fav":
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "lent":
        buttonColor[2] = const Color.fromARGB(255, 117, 117, 117);
        break;
      default:
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor[0]),
            onPressed: () => {
                  if (widget.showing == "all") {null} else changeDisplay("all")
                },
            child: const Text(
              "All",
              style: TextStyle(color: Colors.black, fontSize: 20),
            )),
        const SizedBox(
          width: 10,
        ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor[1]),
            onPressed: () => {
                  if (widget.showing == "fav") {null} else changeDisplay("fav")
                },
            child: const Text(
              "Favorites",
              style: TextStyle(color: Colors.black, fontSize: 20),
            )),
        const SizedBox(
          width: 10,
        ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor[2]),
            onPressed: () => {
                  if (widget.showing == "lent")
                    {null}
                  else
                    changeDisplay("lent")
                },
            child: const Text(
              "Lent",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ))
      ],
    );
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
                displayShowButtons(),
                SizedBox(
                    height: 500,
                    child: ListView.builder(
                        itemCount: widget.shownList.length,
                        itemBuilder: (BuildContext context, int index) {
                          Widget image;
                          if (exampleLibrary[widget.shownList[index]].imagePath !=
                              null) {
                            image = Image.asset(
                              exampleLibrary[widget.shownList[index]]
                                  .imagePath
                                  .toString(),
                              fit: BoxFit.fill,
                            );
                          } else {
                            image = Image.asset("assets/No_Cover.jpg",
                                fit: BoxFit.fill);
                          }

                          String availableTxt;
                          Color availableTxtColor;

                          if (exampleLibrary[widget.shownList[index]].available) {
                            availableTxt = "Available";
                            availableTxtColor = const Color(0xFF43A047);
                          } else {
                            availableTxt = "Lent";
                            availableTxtColor = Colors.red;
                          }

                          Icon favIcon;

                          if (exampleLibrary[widget.shownList[index]].favorite) {
                            favIcon = const Icon(Icons.favorite);
                          } else {
                            favIcon = const Icon(Icons.favorite_border);
                          }

                          return Card(
                              margin: const EdgeInsets.all(5),
                              child: Row(children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  height: 100,
                                  width: 70,
                                  child: image,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                    width: 190,
                                    height: 100,
                                    child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  exampleLibrary[
                                                          widget.shownList[index]]
                                                      .title,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20),
                                                  softWrap: true,
                                                )),
                                            Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  exampleLibrary[
                                                          widget.shownList[index]]
                                                      .author,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16),
                                                  softWrap: true,
                                                )),
                                          ],
                                        ))),
                                SizedBox(
                                  height: 100,
                                  width: 70,
                                  child: Align(
                                      alignment: Alignment.topRight,
                                      child: Column(
                                        children: [
                                          const Align(
                                            alignment: Alignment.topRight,
                                            child: Text(
                                              "Status:",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16),
                                              softWrap: true,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Text(
                                              availableTxt,
                                              style: TextStyle(
                                                  color: availableTxtColor,
                                                  fontSize: 16),
                                              softWrap: true,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: IconButton(
                                              onPressed: () => {
                                                favoriteButtonClicked(
                                                    widget.shownList[index])
                                              },
                                              icon: favIcon,
                                              splashColor: Colors.white,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      )),
                                )
                              ]));
                        }))
              ],
            )));
  }
}
