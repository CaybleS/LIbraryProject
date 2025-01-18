import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Firebase/database.dart';

class Book {
  String title;
  String author;
  bool available;
  bool favorite = false;
  String coverUrl;
  late DatabaseReference _id;
  // maybe dateCheckedOut at some point too, which should probably be an optional parameter, no idea what datatype it would be

  Book(this.title, this.author, this.available, this.coverUrl);

  void favoriteButtonClicked() {
    favorite = !favorite;
    update();
  }

  void setId(DatabaseReference id) {
    _id = id;
  }

  void update() {
    updateBook(this, _id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'available': available,
      'favorite': favorite,
      'coverUrl': coverUrl,
    };
  }

  Widget getCard(
      Function(int) favClicked, Function(int) bookClicked, int index) {
    Widget image;
    image = Image.network(
      coverUrl.toString(),
      fit: BoxFit.fill,
    );
    String availableTxt;
    Color availableTxtColor;

    if (available) {
      availableTxt = "Available";
      availableTxtColor = const Color(0xFF43A047);
    } else {
      availableTxt = "Lent";
      availableTxtColor = Colors.red;
    }

    Icon favIcon;

    if (favorite) {
      favIcon = const Icon(Icons.favorite);
    } else {
      favIcon = const Icon(Icons.favorite_border);
    }

    return InkWell(
        onTap: () {
          bookClicked(index);
        },
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
                              alignment: Alignment.topLeft,
                              child: Text(
                                title,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                          Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                author,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                                softWrap: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            softWrap: true,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            availableTxt,
                            style: TextStyle(
                                color: availableTxtColor, fontSize: 16),
                            softWrap: true,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            onPressed: () => {favClicked(index)},
                            icon: favIcon,
                            splashColor: Colors.white,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    )),
              )
            ])));
  }
}

Book createBook(record) {
  Book book = Book(record['title'], record['author'], record['available'],
      record['coverUrl']);
  book.favorite = record['favorite'];

  return book;
}
