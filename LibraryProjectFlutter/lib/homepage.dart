import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book_page.dart';
import 'package:library_project/database.dart';
import 'book.dart';
import 'appbar.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage(this.user, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _showing = "all";
  List<int> _shownList = [];
  List<Book> _userLibrary = [];

  @override
  void initState() {
    super.initState();

    updateList(_showing);
  }

  void filterButtonClicked() {
    //TODO
  }

  void addBookButtonClicked() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => AddBookPage(widget.user)));
    await updateList(_showing);
    setState(() {});
  }

  Future<void> changeDisplay(String state) async {
    await updateList(state);

    setState(() {
      _showing = state;
    });
  }

  Future<void> updateList(String state) async {
    _shownList.clear();
    _userLibrary = await getUserLibrary(widget.user);

    switch (state) {
      case "all":
        _shownList = Iterable<int>.generate(_userLibrary.length).toList();
        break;
      case "fav":
        for (int i = 0; i < _userLibrary.length; i++) {
          if (_userLibrary[i].favorite) {
            _shownList.add(i);
          }
        }
        break;
      case "lent":
        for (int i = 0; i < _userLibrary.length; i++) {
          if (!_userLibrary[i].available) {
            _shownList.add(i);
          }
        }
        break;
      default:
        break;
    }

    setState(() {});
  }

  void favoriteButtonClicked(int index) {
    _userLibrary[index].favoriteButtonClicked();
    setState(() {});
  }

  Widget displayShowButtons() {
    List<Color> buttonColor = [
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1)
    ];

    switch (_showing) {
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
                  if (_showing == "all") {null} else changeDisplay("all")
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
                  if (_showing == "fav") {null} else changeDisplay("fav")
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
                  if (_showing == "lent") {null} else changeDisplay("lent")
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
        appBar: displayAppBar(context, widget.user, "home"),
        backgroundColor: Colors.grey[400],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            addBookButtonClicked();
          },
          backgroundColor: Colors.green,
          label: const Text(
            "Add Book",
            style: TextStyle(fontSize: 20),
          ),
          icon: const Icon(
            Icons.add,
            size: 30,
          ),
          splashColor: Colors.blue,
        ),
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
                      icon: const Icon(
                        Icons.tune,
                        size: 30,
                      ),
                      splashColor: Colors.white,
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                displayShowButtons(),
                SizedBox(
                    height: 560,
                    child: ListView.builder(
                        itemCount: _shownList.length,
                        itemBuilder: (BuildContext context, int index) {
                          Widget image;
                          if (_userLibrary[_shownList[index]].imagePath !=
                                  null ||
                              _userLibrary[_shownList[index]].imagePath ==
                                  '') {
                            image = Image.asset(
                              _userLibrary[_shownList[index]]
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

                          if (_userLibrary[_shownList[index]].available) {
                            availableTxt = "Available";
                            availableTxtColor = const Color(0xFF43A047);
                          } else {
                            availableTxt = "Lent";
                            availableTxtColor = Colors.red;
                          }

                          Icon favIcon;

                          if (_userLibrary[_shownList[index]].favorite) {
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
                                                  _userLibrary[
                                                          _shownList[index]]
                                                      .title,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20),
                                                  softWrap: true,
                                                )),
                                            Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  _userLibrary[
                                                          _shownList[index]]
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
                                                    _shownList[index])
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
