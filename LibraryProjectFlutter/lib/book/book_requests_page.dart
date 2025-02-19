import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:library_project/Social/friends_library/friend_book_page.dart';
import 'package:library_project/core/global_variables.dart';
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
      _updateList();
    };
    pageRefreshNotifier.addListener(_requestsChangedListener);
  }

  @override
  void dispose() {
    pageRefreshNotifier.removeListener(_requestsChangedListener);
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          child: const FittedBox(
            child: Text(
              "Received Requests",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
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
          child: const FittedBox(
            child: Text(
              "Sent Requests",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
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
        backgroundColor: AppColor.appbarColor,
      ),
      body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
                        String name = "<Not Your Friend>"; // TODO how to do this fr
                        Book book;
                        
                        switch (_showing) {
                          case _ListToShow.receivedRequests:
                            senderId = receivedBookRequests[index].senderId;
                            for (int i = 0; i < friends.length; i++) {
                              if (friends[i].uid == senderId) {
                                name = friends[i].name;
                                break;
                              }
                            }
                            dateSent = receivedBookRequests[index].sendDate;
                            book = receivedBookRequests[index].book;
                            break;
                          case _ListToShow.sentRequests:
                            receiverId = sentBookRequests[index].receiverId;
                            for (int i = 0; i < friends.length; i++) {
                              if (friends[i].uid == receiverId) {
                                name = friends[i].name;
                                break;
                              }
                            }
                            dateSent = sentBookRequests[index].sendDate;
                            book = sentBookRequests[index].book;
                            break;
                        }
                        Image coverImage = book.getCoverImage();
                        return InkWell(
                          onTap: () async {
                            // note that this book here, that we are going to, has the same DatabaseReference id, as the version of
                            // this book in the user library. Thus, it can be treated the same as any normal userLibrary book.
                            _showing == _ListToShow.receivedRequests
                            ? await Navigator.push(context, MaterialPageRoute(builder: (context) => BookPage(book, widget.user)))
                            : await Navigator.push(context, MaterialPageRoute(builder: (context) => FriendBookPage(widget.user, book, receiverId)));
                          },
                          child: SizedBox(
                            height: 150,
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
                                    ? Flexible( 
                                        child: Column(
                                          children: [
                                            Text(
                                              "Requested by $name",
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await displayLendDialog(context, book, widget.user, idToLendTo: senderId);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding: const EdgeInsets.all(8),
                                              ),
                                              child: const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  "Lend requested book",
                                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                book.unsendBookRequest(senderId, widget.user.uid);
                                                SharedWidgets.displayPositiveFeedbackDialog(context, "Request Denied");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: const EdgeInsets.all(8),
                                              ),
                                              child: const FittedBox(
                                                child: Text(
                                                  "Deny request",
                                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "Requested on ${DateFormat.yMd().format(dateSent.toLocal())}",
                                            ),
                                          ],
                                        ),
                                      )
                                    : Flexible(
                                        child: Column(
                                          children: [
                                            Text(
                                              "Sent to $name",
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                book.unsendBookRequest(widget.user.uid, receiverId);
                                                SharedWidgets.displayPositiveFeedbackDialog(context, "Request Unsent");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: const EdgeInsets.all(8),
                                              ),
                                              child: const FittedBox(
                                                child: Text(
                                                  "Unsend Request",
                                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "Sent on ${DateFormat.yMd().format(dateSent.toLocal())}",
                                            ),
                                          ],
                                        ),
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
