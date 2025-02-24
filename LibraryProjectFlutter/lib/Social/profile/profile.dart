import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/profile/edit_profile.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/database/subscriptions.dart';
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
    pageDataUpdatedNotifier.addListener(_userProfileUpdatedListener);
    _updateProfile();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_userProfileUpdatedListener);
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

  void _addFriend() {
    String id = widget.profileUserId;
    if (id != '' && id != widget.user.uid) {
      if (!friendIDs.contains(id)) {
        sendFriendRequest(widget.user, id);
        SharedWidgets.displayPositiveFeedbackDialog(
            context, 'Friend Request Sent!');
        Navigator.pop(context);
      } else {
        SharedWidgets.displayErrorDialog(
            context, "You are already friends with this user");
      }
    } else {
      SharedWidgets.displayErrorDialog(context, "User not found");
    }
  }

  Widget _displayButtons() {
    bool isFriend = friendIDs.contains(widget.profileUserId);
    int friendCount =
        widget.user.uid == widget.profileUserId ? friendIDs.length : 0;
    return SizedBox(
        height: 50,
        child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.user.uid == widget.profileUserId
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.pink),
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
                          ))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.pink),
                          onPressed: () => {}, // TODO link messaging to profile
                          child: const Text(
                            "Message",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          )),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.pink),
                      onPressed: () async {
                        if (widget.user.uid == widget.profileUserId) {
                          bottombarItemTapped(homepageIndex);
                        } else {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FriendsLibraryPage(
                                      widget.user, _userInfo!)));
                        }
                      },
                      child: const Text(
                        "View Library",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      )),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.pink),
                      onPressed: () {
                        if (widget.user.uid == widget.profileUserId) {
                          bottombarItemTapped(friendsPageIndex);
                        } else {
                          // friend list of other user
                        }
                      }, // TODO friend count/list on profile
                      child: Text(
                        "Friends: $friendCount",
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      )),
                  widget.user.uid != widget.profileUserId
                      ? const SizedBox(
                          width: 20,
                        )
                      : const SizedBox.shrink(),
                  widget.user.uid != widget.profileUserId
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.pink),
                          onPressed: () async {
                            if (!isFriend) {
                              _addFriend();
                            } else {
                              // TODO unfriend button - we probably need the books lent check here too right?
                              if (booksLentToMe.any((book) =>
                                  book.lenderId == widget.profileUserId)) {
                                SharedWidgets.displayErrorDialog(context,
                                    "Cannot unfriend: User has books lent to you");
                              } else if (userLibrary.any((book) =>
                                  book.borrowerId == widget.profileUserId)) {
                                SharedWidgets.displayErrorDialog(context,
                                    "Cannot unfriend: You have books lent to this user");
                              } else {
                                await removeFriend(
                                    widget.user.uid, widget.profileUserId);
                                SharedWidgets.displayPositiveFeedbackDialog(
                                    context, "Removed Friend");
                              }
                            }
                            setState(() {});
                          },
                          child: Text(
                            isFriend ? "Unfriend" : "Add Friend",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 16),
                          ))
                      : const SizedBox.shrink()
                ],
              )
            ]));
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
                    Center(child: _displayButtons()),
                    const SizedBox(
                      height: 10,
                    ),
                    _profileInfo?.aboutMe != null
                        ? Card(
                            color: AppColor.skyBlue,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "About Me:\n${_profileInfo!.aboutMe!}",
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
