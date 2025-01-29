import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/book/book_lend_page.dart';
import 'package:library_project/book/book_page.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

enum _ListToShow { receivedRequests, sentRequests }

class BookRequestsPage extends StatefulWidget {
  final User user;

  @override
  State<BookRequestsPage> createState() => _BookRequestsPageState();
  const BookRequestsPage(this.user, {super.key});
}

class _BookRequestsPageState extends State<BookRequestsPage> {
  late final VoidCallback _requestsChangedListener;
  _ListToShow _showing = _ListToShow.receivedRequests;

  @override
  void initState() {
    super.initState();
    _requestsChangedListener = () {
      if (refreshNotifier.value == homepageIndex) { // TODO ensure this is good for this and the update listeners in appwide_setup
        _updateList();
      }
    };
    refreshNotifier.addListener(_requestsChangedListener);
  }

  @override
  void dispose() {
    refreshNotifier.removeListener(_requestsChangedListener);
    super.dispose();
  }

  void _swapDisplay() {
    switch (_showing) {
      case _ListToShow.receivedRequests:
        _showing = _ListToShow.sentRequests;
        break;
      case _ListToShow.sentRequests:
        _showing = _ListToShow.receivedRequests;
        break;
    }
    _updateList();
  }

  void _updateList() {
    setState(() {});
  }

  Widget _displayShowButtons() {
    List<Color> buttonColor = List.filled(2, AppColor.skyBlue);

    switch (_showing) {
      case _ListToShow.receivedRequests:
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case _ListToShow.sentRequests:
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            if (_showing != _ListToShow.receivedRequests) {
              _swapDisplay();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[0],
            padding: const EdgeInsets.all(8),
          ),
          child: const Text(
            "Received Requests",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_showing != _ListToShow.sentRequests) {
              _swapDisplay();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[1],
            padding: const EdgeInsets.all(8),
          ),
          child: const Text(
            "Sent Requests",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Requests"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[400],
      body: Padding(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _displayShowButtons(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ListView.builder(
                      itemCount: _showing == _ListToShow.receivedRequests ? receivedBookRequests.length : sentBookRequests.length,
                      itemBuilder: (BuildContext context, int index) {
                        // this is not the safest way to do this; be careful with using senderId or receiverId here, one will always be uninitialized I believe
                        late String senderId;
                        late String receiverId;
                        late DateTime dateSent;
                        Book book;
                        
                        switch (_showing) {
                          case _ListToShow.receivedRequests:
                            senderId = receivedBookRequests[index].senderId;
                            dateSent = receivedBookRequests[index].sendDate.toLocal();
                            book = receivedBookRequests[index].book;
                            break;
                          case _ListToShow.sentRequests:
                            receiverId = sentBookRequests[index].receiverId;
                            dateSent = sentBookRequests[index].sendDate.toLocal();
                            book = sentBookRequests[index].book;
                            break;
                        }
                        Image coverImage = book.getCoverImage();
                        return InkWell(
                          onTap: () async {
                            // note that this book here, that we are going to, has the same DatabaseReference id, as the version of
                            // this book in the user library. Thus, it can be treated the same as any normal userLibrary book.
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => BookPage(book, widget.user)));
                          },
                          child: SizedBox(
                            height: 160,
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
                                  (_showing == _ListToShow.receivedRequests)
                                    ? Column(
                                        children: [
                                          Text(
                                            "Requested by ${senderId.substring(0, 10)}",
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await Navigator.push(context, MaterialPageRoute(builder: (context) => BookLendPage(book, widget.user, idToLendTo: senderId)));
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.all(8),
                                            ),
                                            child: const Text(
                                              "Lend requested book",
                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              book.unsendBookRequest(senderId, widget.user.uid);
                                              SharedWidgets.displayPositiveFeedbackDialog(context, "Request denied");
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: const EdgeInsets.all(8),
                                            ),
                                            child: const Text(
                                              "Deny request",
                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          ),
                                          Text(
                                            "Requested on ${dateSent.toString().substring(0, 10)}",
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            "Sent to ${receiverId.substring(0, 10)}",
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              book.unsendBookRequest(widget.user.uid, receiverId);
                                              SharedWidgets.displayPositiveFeedbackDialog(context, "Request unsent");
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: const EdgeInsets.all(8),
                                            ),
                                            child: const Text(
                                              "Unsend Request",
                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          ),
                                          Text(
                                            "Sent on ${dateSent.toString().substring(0, 10)}",
                                          ),
                                        ],
                                      ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
