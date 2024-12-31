import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/book/book_page.dart';
import '../database/database.dart';
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
  List<LentBookInfo> _booksLentToMe = [];
  bool _usingBooksLentToMe = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // need to get user library when page first starts but the initState cant await anything, so it needs to be awaited here
  Future<void> _loadInitialData() async {
    // fun fact: this function ONLY needs to be called once, straight up. Since dart passes objects by reference, we can just update this list in
    // other files as its appended to or removed from. This should also work with friends and other stuff as well. Its more coupling + complexity
    // but saves many DB reads so its optimal for sure. Currently this is my approach, but I also thought of using path_provider and storing books
    // in app documents directory json file with a last modified timestamp and just comparing that to a database's last modified timestamp and if same use local
    // files. This was a solution to allow users to track lent books even with no internet connection but it also can be used to optimize reads I think.
    _userLibrary = await getUserLibrary(widget.user);
    _booksLentToMe = await getLentToMeUserLibrary(widget.user);
    await updateList(_showing);
  }

  void filterButtonClicked() {
    //TODO
  }

  void bookClicked(int index) async {
    if (_usingBooksLentToMe) {
      return;
    }
    String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (context) => BookPage(_userLibrary[index], widget.user)));
    if (retVal != null) {
      _userLibrary.removeAt(index);
      _shownList.removeAt(index);
    }
    await updateList(_showing);
    setState(() {});
  }

  void addBookButtonClicked() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => AddBookHomepage(widget.user, _userLibrary)));
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
    _usingBooksLentToMe = false;

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
          if (_userLibrary[i].lentDbPath != null) {
            _shownList.add(i);
          }
        }
        break;
      case "lentToMe":
        _usingBooksLentToMe = true;
        _booksLentToMe = await getLentToMeUserLibrary(widget.user);
        _shownList = Iterable<int>.generate(_booksLentToMe.length).toList();
        break;
      default:
        break;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void favoriteButtonClicked(int index) {
    _userLibrary[index].favoriteButtonClicked();
    setState(() {});
  }

  Widget displayShowButtons() {
    List<Color> buttonColor = [
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
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
      case "lentToMe":
        buttonColor[3] = const Color.fromARGB(255, 117, 117, 117);
        break;
      default:
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[0], padding: const EdgeInsets.all(8),
            ),
            onPressed: () => {
                  if (_showing == "all") {null} else changeDisplay("all")
                },
            child: const Text(
              "All",
              style: TextStyle(color: Colors.black, fontSize: 16),
            )),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[1], padding: const EdgeInsets.all(8),
            ),
            onPressed: () => {
                  if (_showing == "fav") {null} else changeDisplay("fav")
                },
            child: const Text(
              "Favorites",
              style: TextStyle(color: Colors.black, fontSize: 16),
            )),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[2], padding: const EdgeInsets.all(8),
            ),
            onPressed: () => {
                  if (_showing == "lent") {null} else changeDisplay("lent")
                },
            child: const Text(
              "Lent",
              style: TextStyle(color: Colors.black, fontSize: 16),
            )),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[3], padding: const EdgeInsets.all(8),
            ),
            onPressed: () => {
                  if (_showing == "lentToMe") {null} else changeDisplay("lentToMe")
                },
            child: const Text(
              "Lent to me",
              style: TextStyle(color: Colors.black, fontSize: 16),
            )),
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
                          List<Book> shownLibrary = _usingBooksLentToMe ?  _booksLentToMe.map((item) => item.book).toList() : _userLibrary;
                          Widget image;
                          image = shownLibrary[_shownList[index]].getCoverImage();
                          String availableTxt;
                          Color availableTxtColor;

                          if (shownLibrary[_shownList[index]].lentDbPath != null) {
                            availableTxt = "Lent";
                            availableTxtColor = Colors.red;
                          } else {
                            availableTxt = "Available";
                            availableTxtColor = const Color(0xFF43A047);
                          }

                          Icon favIcon;

                          if (shownLibrary[_shownList[index]].favorite) {
                            favIcon = const Icon(Icons.favorite);
                          } else {
                            favIcon = const Icon(Icons.favorite_border);
                          }

                          return InkWell(
                              onTap: () {bookClicked(_shownList[index]);},
                              child: Card(
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
                                                  width: 80,
                                                ),
                                                Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      shownLibrary[_shownList[index]].title ?? "No title found",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 20),
                                                      softWrap: true,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    )),
                                                Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      shownLibrary[_shownList[index]].author ?? "No author found",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16),
                                                      softWrap: true,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    )),
                                              ],
                                            ))),
                                    _usingBooksLentToMe ? const SizedBox.shrink() : SizedBox(
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
                                                alignment:
                                                    Alignment.bottomRight,
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
                                  ])));
                        }))
              ],
            )));
  }
}