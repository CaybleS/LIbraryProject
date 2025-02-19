import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/profile/edit_profile.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/subscriptions.dart';
// import 'package:library_project/models/book.dart';
import 'package:library_project/models/profile_info.dart';
import 'package:library_project/models/user.dart';
import '../../core/appbar.dart';
import '../../ui/colors.dart';
import '../../ui/shared_widgets.dart';
import '../friends_library/friends_library_page.dart';

class Profile extends StatefulWidget {
  final User user;
  final String profileUserId;

  const Profile(this.user, this.profileUserId, {super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final VoidCallback _userProfileUpdatedListener;
  UserModel? _userInfo;
  ProfileInfo? _profileInfo;

  @override
  void initState() {
    super.initState();
    if (userIdToSubscription[widget.profileUserId] == null) {
      userIdToSubscription[widget.profileUserId] = setupUserSubscription(
          userIdToUserModel, widget.profileUserId, userUpdated);
    }
    if (userIdToProfileSubscription[widget.profileUserId] == null) {
      userIdToProfileSubscription[widget.profileUserId] =
          setupProfileSubscription(
              userIdToProfile, widget.profileUserId, profileUpdated);
    }
    _userProfileUpdatedListener = () {
      // since offstage loads this page into memory at all times via the bottombar we just run the refresh logic if its the selectedIndex
      if (selectedIndex == profileIndex) {
        // _userInfo = userIdToUserModel[widget.profileUserId]!;
        _updateProfile();
      }
    };
    pageRefreshNotifier.addListener(_userProfileUpdatedListener);
    _updateProfile();
  }

  @override
  void dispose() {
    pageRefreshNotifier.removeListener(_userProfileUpdatedListener);
    super.dispose();
  }

  void _updateProfile() async {
    while (userIdToUserModel[widget.profileUserId] == null ||
        userIdToProfile[widget.profileUserId] == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _userInfo = userIdToUserModel[widget.profileUserId]!;
    _profileInfo = userIdToProfile[widget.profileUserId]!;

    setState(() {});
  }

  Widget _displayButtons() {
    return widget.user.uid == widget.profileUserId
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(widget.user)));
                  },
                  child: const Text(
                    "Edit Profile",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  )),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                  onPressed: () => {}, // TODO friend count/list on profile
                  child: const Text(
                    "Friends: 12",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ))
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                  onPressed: () => {}, // TODO link messaging to profile
                  child: const Text(
                    "Message",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  )),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                FriendsLibraryPage(widget.user, _userInfo!)));
                  },
                  child: const Text(
                    "View Library",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  )),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                  onPressed: () => {}, // TODO friend count/list on profile
                  child: const Text(
                    "Friends: 12",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ))
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(widget.user),
        body: (_userInfo != null && _profileInfo != null)
            ? Padding(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          backgroundImage: _userInfo!.photoUrl != null
                              ? NetworkImage(
                                  _userInfo!.photoUrl!,
                                )
                              : const AssetImage(
                                  "assets/profile_pic.jpg",
                                ),
                          radius: 40,
                        ),
                        // ClipOval(
                        //   child: SizedBox(
                        //     width: 100,
                        //     child: _userInfo!.photoUrl != null
                        //         ? Image.network(
                        //             _userInfo!.photoUrl!,
                        //           )
                        //         : Image.asset(
                        //       "assets/profile_pic.jpg",
                        //     ),
                        //   ),
                        // ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userInfo!.name,
                              style: const TextStyle(fontSize: 25),
                            ),
                            Text(
                              _userInfo!.email,
                              style: const TextStyle(fontSize: 16),
                            )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _displayButtons(),
                    const SizedBox(
                      height: 10,
                    ),
                    _profileInfo?.aboutMe != null
                        ? Card(
                            color: AppColor.skyBlue,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                _profileInfo!.aboutMe!,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                            ))
                        : const SizedBox.shrink(),
                    _profileInfo!.favBooks.isNotEmpty
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Card(
                                color: AppColor.skyBlue,
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Favorite Books:",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14),
                                          ),
                                          Flexible(
                                              child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: _profileInfo
                                                      ?.favBooks.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        child: SizedBox(
                                                            width: 120,
                                                            child: Column(
                                                                children: [
                                                                  SizedBox(
                                                                      height:
                                                                          120,
                                                                      child: AspectRatio(
                                                                          aspectRatio:
                                                                              0.7,
                                                                          child: _profileInfo!
                                                                              .favBooks[index]
                                                                              .getCoverImage())),
                                                                  Text(
                                                                    _profileInfo!
                                                                        .favBooks[
                                                                            index]
                                                                        .title!,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            14),
                                                                    softWrap:
                                                                        true,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  )
                                                                ])));
                                                  }))
                                        ]))))
                        : const SizedBox.shrink(),
                    _profileInfo?.favGenre != null
                        ? Card(
                            color: AppColor.skyBlue,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "Favorite Genre: ${_profileInfo!.favGenre!}",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                            ))
                        : const SizedBox.shrink(),
                  ],
                )),
              )
            : Center(child: SharedWidgets.displayCircularProgressIndicator()));
  }
}
