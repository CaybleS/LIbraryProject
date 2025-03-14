import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfswap/Social/profile/add_fav_book.dart';
import 'package:shelfswap/add_book/custom_add/book_cover_changers.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/database/subscriptions.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/profile_info.dart';
import 'package:shelfswap/models/user.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen(this.user, {super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  UserModel? _userModel;
  ProfileInfo? _profileInfo;
  bool _showNameErr = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _favGenreController = TextEditingController();
  bool _picUploaded = false;
  String? _picFromDB;
  XFile? _profilePicFile;
  List<Book> _favBooks = [];

  bool _displayProcessing = false;
  late final VoidCallback _textUpdatedListener;
  final int nameCharLimit = 20;
  final int aboutMeCharLimit = 200;
  final int genreCharLimit = 50;
  bool _nameCharErr = false;
  bool _aboutCharErr = false;
  bool _genreCharErr = false;

  @override
  void initState() {
    super.initState();
    if (userIdToSubscription[widget.user.uid] == null) {
      userIdToSubscription[widget.user.uid] = setupUserSubscription(
          userIdToUserModel, widget.user.uid, userUpdated);
    }
    if (userIdToProfileSubscription[widget.user.uid] == null) {
      userIdToProfileSubscription[widget.user.uid] = setupProfileSubscription(
          userIdToProfile, widget.user.uid, profileUpdated);
    }

    _userModel = userIdToUserModel[widget.user.uid];
    _profileInfo = userIdToProfile[widget.user.uid];
    _nameController.text = _userModel!.name;
    if (_userModel!.photoUrl != null) {
      _picFromDB = _userModel!.photoUrl;
    }
    if (_profileInfo!.aboutMe != null) {
      _aboutMeController.text = _profileInfo!.aboutMe!;
    }
    if (_profileInfo!.favGenre != null) {
      _favGenreController.text = _profileInfo!.favGenre!;
    }
    if (_profileInfo!.favBooks.isNotEmpty) {
      _favBooks = List.from(_profileInfo!.favBooks);
    }

    _textUpdatedListener = () {
      setState(() {});
    };
    _aboutMeController.addListener(_textUpdatedListener);
    _nameController.addListener(_textUpdatedListener);
    _favGenreController.addListener(_textUpdatedListener);
  }

  @override
  void dispose() {
    _aboutMeController.removeListener(_textUpdatedListener);
    _nameController.removeListener(_textUpdatedListener);
    _favGenreController.removeListener(_textUpdatedListener);
    _nameController.dispose();
    _aboutMeController.dispose();
    _favGenreController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    setState(() {
      _displayProcessing = true;
    });

    String name = _nameController.text;
    String aboutMe = _aboutMeController.text;
    String favGenre = _favGenreController.text;
    _showNameErr = name.isEmpty;
    _nameCharErr = name.length > nameCharLimit;
    _aboutCharErr = aboutMe.length > aboutMeCharLimit;
    _genreCharErr = favGenre.length > genreCharLimit;

    if (_showNameErr || _nameCharErr || _aboutCharErr || _genreCharErr) {
      setState(() {
        _displayProcessing = false;
      });
      return;
    }

    Map<String, dynamic> userJson = {'name': name};

    if (_picUploaded && _profilePicFile != null) {
      String picName = const Uuid().v1();
      Reference imageRef = FirebaseStorage.instance.ref("profilePics/$picName");
      TaskSnapshot uploadTask =
          await imageRef.putFile(File(_profilePicFile!.path));

      if (uploadTask.state == TaskState.success) {
        String picURL = await uploadTask.ref.getDownloadURL();
        userJson['photoUrl'] = picURL;
        _picFromDB = picURL;
      } else {
        SharedWidgets.displayErrorDialog(
            context, "Failed to set profile picture");
      }
    } else if (_picFromDB == null) {
      userJson['photoUrl'] = null;
    }

    Map<String, dynamic> profileJson = {};

    if (aboutMe.isEmpty) {
      profileJson['aboutMe'] = null;
    } else {
      profileJson['aboutMe'] = aboutMe;
    }

    if (favGenre.isEmpty) {
      profileJson['favGenre'] = null;
    } else {
      profileJson['favGenre'] = favGenre;
    }

    Map<dynamic, dynamic> bookMap = {};

    int count = 0;
    for (Book book in _favBooks) {
      bookMap[count] = book.toJson();
      count++;
    }

    profileJson['favBooks'] = bookMap;

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/${widget.user.uid}');
    await userRef.update(userJson);

    DatabaseReference profileRef =
        FirebaseDatabase.instance.ref('profileInfo/${widget.user.uid}');
    await profileRef.update(profileJson);

    setState(() {
      _displayProcessing = false;
    });

    _picUploaded = false;
    _profilePicFile = null;

    SharedWidgets.displayPositiveFeedbackDialog(context, "Profile Saved");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
      ),
      body: _displayProcessing
          ? Center(child: SharedWidgets.displayCircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(15),
              child: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          flex: 1,
                          child: Text(
                            "Display Name:",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        Flexible(
                            flex: 3,
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: "Display Name",
                                  hintStyle: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25.0)),
                                  ),
                                  errorText: _showNameErr
                                      ? "Please enter a name"
                                      : (_nameCharErr
                                          ? "Over character limit"
                                          : null),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _nameController.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                                  suffixText:
                                      "${_nameController.text.length}/$nameCharLimit"),
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ))
                      ]),
                  const SizedBox(height: 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          flex: 1,
                          child: Text(
                            "Profile Picture:",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        Flexible(
                          child: CircleAvatar(
                            backgroundImage: (_picUploaded)
                                ? FileImage(File(_profilePicFile!.path))
                                : (_picFromDB != null)
                                    ? NetworkImage(_picFromDB!)
                                    : const AssetImage(
                                        "assets/profile_pic.jpg",
                                      ),
                            radius: 40,
                          ),
                        ),
                        Flexible(
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              ElevatedButton(
                                onPressed: () async {
                                  _profilePicFile =
                                      await selectCoverFromFile(context);
                                  if (_profilePicFile != null) {
                                    setState(() {
                                      _picUploaded = true;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.skyBlue,
                                    padding: const EdgeInsets.all(8)),
                                child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text("Upload From File",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black))),
                              ),
                              (_profilePicFile != null && _picUploaded) ||
                                      (!_picUploaded &&
                                          _userModel?.photoUrl != null)
                                  ? ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _profileInfo = null;
                                          _picFromDB = null;
                                          _picUploaded = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColor.skyBlue,
                                          padding: const EdgeInsets.all(8)),
                                      child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text("Clear picture",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black))),
                                    )
                                  : const SizedBox.shrink(),
                            ]))
                      ]),
                  const SizedBox(height: 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          flex: 1,
                          child: Text(
                            "About Me:",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        Flexible(
                            flex: 3,
                            child: TextField(
                              controller: _aboutMeController,
                              keyboardType: TextInputType
                                  .multiline, // create multiline textbox
                              maxLines: null,
                              decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: "About Me",
                                  hintStyle: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25.0)),
                                  ),
                                  errorText:
                                      _aboutCharErr ? "Over character limit" : null,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _aboutMeController
                                          .clear(); // clears the page's controller since dart passes objects by reference
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                                  suffixText:
                                      "${_aboutMeController.text.length}/$aboutMeCharLimit"),
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ))
                      ]),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Flexible(
                                    flex: 1,
                                    child: Text(
                                      "Favorite Books:",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                  ),
                                  Flexible(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddFavBook(widget.user,
                                                            _favBooks)));
                                            setState(() {});
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColor.skyBlue,
                                              padding: const EdgeInsets.all(8)),
                                          child: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text("Add Book",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black))),
                                        ),
                                        (_favBooks.isNotEmpty)
                                            ? ElevatedButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    _favBooks.clear();
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColor.skyBlue,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8)),
                                                child: const FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                        "Clear Fav Books",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black))),
                                              )
                                            : const SizedBox.shrink(),
                                      ]))
                                ]),
                            _favBooks.isNotEmpty
                                ? Flexible(
                                    child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _favBooks.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: SizedBox(
                                              width: 120,
                                              child: Column(children: [
                                                SizedBox(
                                                    height: 120,
                                                    child: AspectRatio(
                                                        aspectRatio: 0.7,
                                                        child: _favBooks[index]
                                                            .getCoverImage())),
                                                Text(
                                                  _favBooks[index].title!,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14),
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _favBooks.removeAt(index);
                                                    setState(() {});
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColor
                                                                  .cancelRed),
                                                  child: const Text("Remove",
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black)),
                                                ),
                                              ])));
                                    },
                                    separatorBuilder: (context, index) {
                                      return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 40, 0, 100),
                                          child: IconButton(
                                              onPressed: () {
                                                var temp = _favBooks[index];
                                                _favBooks[index] =
                                                    _favBooks[index + 1];
                                                _favBooks[index + 1] = temp;
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                  Icons.swap_horiz)));
                                    },
                                  ))
                                : const SizedBox.shrink()
                          ])),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          flex: 1,
                          child: Text(
                            "Favorite Genre:",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        Flexible(
                            flex: 3,
                            child: TextField(
                              controller: _favGenreController,
                              keyboardType: TextInputType
                                  .multiline, // create multiline textbox
                              maxLines: null,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: "Favorite Genre",
                                hintStyle: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                ),
                                errorText:
                                    _genreCharErr ? "Over character limit" : null,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _favGenreController
                                        .clear(); // clears the page's controller since dart passes objects by reference
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                                suffixText:
                                    "${_favGenreController.text.length}/$genreCharLimit",
                              ),
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ))
                      ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.skyBlue),
                            child: const Text("Cancel",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            onPressed: () {
                              _onSubmit();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.skyBlue),
                            child: const Text("Save Changes",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ))),
    );
  }
}
