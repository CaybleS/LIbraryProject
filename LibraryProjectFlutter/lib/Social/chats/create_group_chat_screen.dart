import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:library_project/Social/chats/chat_screen.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/core/conditional_widget.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:library_project/ui/widgets/user_avatar_widget.dart';
import 'package:uuid/uuid.dart';

class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final controller = TextEditingController();
  List<UserModel> friendsResult = userIdToUserModel.entries.where((MapEntry friend) => friendIDs.contains(friend.value.uid)).map((entry) => entry.value).toList();
  List<UserModel> members = [];
  String? nameErrorText;
  String? imageUrl;
  bool uploadImageLoading = false;
  bool showLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Create Group Chat',
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createChat();
        },
        backgroundColor: Colors.green,
        heroTag: UniqueKey(),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 83,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _uploadChatImage();
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                              child: ConditionalWidget.single(
                                context: context,
                                conditionBuilder: (context) => imageUrl != null,
                                widgetBuilder: (context) {
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    fit: BoxFit.cover,
                                    height: 70,
                                    width: 70,
                                    placeholder: (context, url) {
                                      return Container(
                                        width: 70,
                                        height: 70,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: SharedWidgets.displayCircularProgressIndicator(2.5),
                                      );
                                    },
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  );
                                },
                                fallbackBuilder: (context) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    width: 70,
                                    height: 70,
                                    alignment: Alignment.center,
                                    child: const Icon(IconsaxPlusLinear.gallery_add, color: Colors.white, size: 30),
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(uploadImageLoading ? 0.4 : 0),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(20),
                              child: uploadImageLoading ? SharedWidgets.displayCircularProgressIndicator(2.5) : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 7),
                            TextField(
                              controller: controller,
                              onChanged: (value) {
                                setState(() {
                                  nameErrorText = null;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Enter group name',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(25)),
                                ),
                                errorText: nameErrorText,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    controller.clear();
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              ),
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.builder(
                    itemCount: friendsResult.length,
                    itemBuilder: (BuildContext context, int index) {
                      final user = friendsResult[index];
                      bool isSelected = members.contains(user);
                      return InkWell(
                        onTap: () {
                          if (members.contains(user)) {
                            members.remove(user);
                          } //
                          else {
                            members.add(user);
                          }
                          setState(() {});
                        },
                        child: Card(
                          margin: const EdgeInsets.all(5),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(1, 0, 5, 0),
                                  child: UserAvatarWidget(photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                        softWrap: true,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user.username,
                                        style: const TextStyle(color: Colors.black, fontSize: 14),
                                        softWrap: true,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedOpacity(
                                  opacity: isSelected ? 1 : 0,
                                  duration: const Duration(milliseconds: 100),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
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
              ],
            ),
          ),
          if (showLoading)
            Container(
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.4),
              child: SharedWidgets.displayCircularProgressIndicator(3.5),
            ),
        ],
      ),
    );
  }

  void createChat() async {
    if (controller.text.trim().isEmpty) {
      setState(() {
        nameErrorText = 'Group name cannot be empty';
      });
      return;
    }
    if (members.isEmpty) {
      SharedWidgets.displayErrorDialog(context, "Group cannot be empty");
      return;
    }
    setState(() {
      showLoading = true;
    });
    members.add(userModel.value!);
    String chatId = _database.child('chats/').push().key!;
    Chat chat = Chat(
      id: chatId,
      name: controller.text.trim(),
      avatarColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      participants: members.map((e) => e.uid).toList(),
      type: ChatType.group,
      createdBy: userModel.value!.uid,
      chatImage: imageUrl,
    );

    await _database.child('chats/$chatId').set(chat.toJson());
    final messageId = _database.child('messages/$chatId').push().key;
    MessageModel message = MessageModel(
      id: messageId!,
      text: '${userModel.value!.name} created the group «${controller.text.trim()}»',
      senderId: userModel.value!.uid,
      sentTime: DateTime.now().toUtc(),
      type: MessageType.event,
    );
    await _database.child('messages/$chatId/$messageId').set(message.toJson());

    for (var member in members) {
      await _database.child('userChats/${member.uid}/$chatId').set({
        'lastMessage': {
          'text': '${userModel.value!.name} created the group «${controller.text.trim()}»',
          'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          'sender': userModel.value!.uid,
        },
        'unreadCount': 0,
      });
    }
    setState(() {
      showLoading = false;
    });
    showBottombar = false;
    refreshBottombar.value = true;
    if (mounted) {
      Navigator.pop(context);
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );
    }
    showBottombar = true;
    refreshBottombar.value = true;
  }

  _uploadChatImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (xFile != null) {
      setState(() {
        uploadImageLoading = true;
      });
      File image = File(xFile.path);
      String filename = const Uuid().v1();

      final Reference imageRef = FirebaseStorage.instance.ref().child('chatImages/$filename');

      var uploadTask = await imageRef.putFile(image).catchError((error) {
        return null;
      });

      imageUrl = await uploadTask.ref.getDownloadURL();
    }
    setState(() {
      uploadImageLoading = false;
    });
  }
}
