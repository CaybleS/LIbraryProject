import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/book/book_page.dart';
import 'package:library_project/book/borrowed_book_page.dart';
import 'package:library_project/database/database.dart';
import 'appbar.dart';

class HomePage extends StatefulWidget {
  final User user;
  final List<Book> userLibrary;
  final ValueNotifier<int> refreshNotifier;

  const HomePage(this.user, this.userLibrary, this.refreshNotifier, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _showing = "all";
  List<int> _shownList = [];
  final List<LentBookInfo> _booksLentToMe = [];
  bool _usingBooksLentToMe = false;
  // What does this checksum do? Books lent to a user are stored in the database under the receiver, and only store data needed to find the book's path in the database
  // (not the book itself), so a checksum is computed from this minimum info and if its different from last time we know the books lent to this user changed without
  // even fetching the books themselves. Without this we would need to update booksLentToMe list everytime even if it remains the same. This is only possible since we
  // store basically only the book's database path under each user's list of books lent to them.
  String _lentBooksChecksum = "";
  late final VoidCallback _pageOpenedListener; // used to run some stuff everytime we go to this page from the bottombar

  @override
  void initState() {
    super.initState();
    _pageOpenedListener = () {
      if (widget.refreshNotifier.value == 0) {
        _updateList(_showing);
      }
    };
    _updateList(_showing);
    widget.refreshNotifier.addListener(_pageOpenedListener);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_pageOpenedListener);
    super.dispose();
  }

  Future<void> _getBooksLentToMe() async {
    // this takes in books lent to me list by reference and updates it if the user's books lent to them changed
    _lentBooksChecksum = await getLentToMeUserLibrary(_booksLentToMe, widget.user, _lentBooksChecksum);
  }

  void _filterButtonClicked() {
    //TODO
  }

  void _bookClicked(int index) async {
    if (_usingBooksLentToMe) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => BorrowedBookPage(_booksLentToMe[index], widget.user)));
    }
    else {
      String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (context) => BookPage(widget.userLibrary[index], widget.user, widget.userLibrary)));
      if (retVal != null) { // this signals that on this page the user clicked the "remove book" button
        widget.userLibrary.removeAt(index);
      }
    }
    await _updateList(_showing);
  }

  Future<void> _changeDisplay(String state) async {
    await _updateList(state);

    setState(() {
      _showing = state;
    });
  }

  Future<void> _updateList(String state) async {
    _shownList.clear();
    _usingBooksLentToMe = false;

    switch (state) {
      case "all":
        _shownList = Iterable<int>.generate(widget.userLibrary.length).toList();
        break;
      case "fav":
        for (int i = 0; i < widget.userLibrary.length; i++) {
          if (widget.userLibrary[i].favorite) {
            _shownList.add(i);
          }
        }
        break;
      case "lent":
        for (int i = 0; i < widget.userLibrary.length; i++) {
          if (widget.userLibrary[i].lentDbKey != null) {
            _shownList.add(i);
          }
        }
        break;
      case "lentToMe":
        _usingBooksLentToMe = true;
        await _getBooksLentToMe();
        _shownList = Iterable<int>.generate(_booksLentToMe.length).toList();
        break;
      default:
        break;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _favoriteButtonClicked(int index) {
    widget.userLibrary[index].favoriteButtonClicked();
    setState(() {});
  }

  Widget _displayShowButtons() {
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
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor[0], padding: const EdgeInsets.all(8)),
          onPressed: () => {
            if (_showing == "all") {null} else _changeDisplay("all")
          },
          child: const Text("All", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor[1], padding: const EdgeInsets.all(8)),
          onPressed: () => {
            if (_showing == "fav") {null} else _changeDisplay("fav")
          },
          child: const Text("Favorites", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor[2], padding: const EdgeInsets.all(8)),
          onPressed: () => {
            if (_showing == "lent") {null} else _changeDisplay("lent")
          },
          child: const Text("Lent", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor[3], padding: const EdgeInsets.all(8)),
          onPressed: () => {
            if (_showing == "lentToMe") {null} else _changeDisplay("lentToMe")
          },
          child: const Text("Lent to me", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: displayAppBar(context, widget.user, "home"),
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
                  onPressed: () => {_filterButtonClicked()},
                  icon: const Icon(
                    Icons.tune,
                    size: 30,
                  ),
                  splashColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            _displayShowButtons(),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _shownList.length,
                itemBuilder: (BuildContext context, int index) {
                  // BooksLentToMe stores each book as part of the object so we just create a list of books from it if needed
                  List<Book> shownLibrary = _usingBooksLentToMe ? _booksLentToMe.map((item) => item.book).toList() : widget.userLibrary;
                  Widget coverImage = shownLibrary[_shownList[index]].getCoverImage();
                  String availableTxt;
                  Color availableTxtColor;

                  if (shownLibrary[_shownList[index]].lentDbKey != null) {
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
                    onTap: () {_bookClicked(_shownList[index]);},
                    child: SizedBox(
                      height: 110,
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
                              child: AspectRatio(
                                aspectRatio: 0.7,
                                child: coverImage,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 12, // change this if you change card size id say to center the row
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      shownLibrary[_shownList[index]].title ?? "No title found",
                                      style: const TextStyle(color: Colors.black, fontSize: 18),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      shownLibrary[_shownList[index]].author ?? "No author found",
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                      softWrap: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _usingBooksLentToMe ? const SizedBox.shrink() : SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Flexible(
                                  child:
                                    Text(
                                      "Status:",
                                      style: TextStyle(color: Colors.black, fontSize: 16),
                                      softWrap: true,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      availableTxt,
                                      style: TextStyle(color: availableTxtColor, fontSize: 16),
                                      softWrap: true,
                                    ),
                                  ),
                                  Flexible(
                                    child: IconButton(
                                      onPressed: () => {_favoriteButtonClicked(_shownList[index])},
                                      icon: favIcon,
                                      splashColor: Colors.white,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
