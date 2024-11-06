import 'package:flutter/material.dart';
import 'book.dart';

class BookPage extends StatefulWidget {
  final Book book;
  const BookPage(this.book, {super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  void changeStatus() {
    widget.book.available = !widget.book.available;
    widget.book.update();
    setState(() {});
  }

  Widget displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (widget.book.available) {
      availableTxt = "Available";
      availableTxtColor = const Color(0xFF43A047);
    } else {
      availableTxt = "Lent";
      availableTxtColor = Colors.red;
    }

    return Text(
      availableTxt,
      style: TextStyle(fontSize: 22, color: availableTxtColor),
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
                children: [
                  SizedBox(
                    height: 200,
                    width: 140,
                    child: Image.network(
                      widget.book.coverUrl.toString(),
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(children: [
                    SizedBox(
                        width: 200,
                        child: Text(
                          widget.book.title,
                          style: const TextStyle(fontSize: 30),
                        )),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(widget.book.author,
                            style: const TextStyle(fontSize: 25)))
                  ])
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Text("Status:", style: TextStyle(fontSize: 22)),
              displayStatus(),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    changeStatus();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                  child: const Text('Switch status',
                      style: TextStyle(fontSize: 16, color: Colors.black)))
            ],
          ),
        ));
  }
}
