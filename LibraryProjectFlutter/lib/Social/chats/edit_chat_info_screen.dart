import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/core/conditional_widget.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/models/chat.dart';
import 'package:shelfswap/models/message.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class EditChatInfoScreen extends StatefulWidget {
  const EditChatInfoScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<EditChatInfoScreen> createState() => _EditChatInfoScreenState();
}

class _EditChatInfoScreenState extends State<EditChatInfoScreen> {
  TextEditingController controller = TextEditingController();
  late Chat chat = widget.chat;
  bool uploadImageLoading = false;
  String chatName = '';
  String? imageLink;
  String? nameErrorText;

  @override
  void initState() {
    controller.text = chat.name;
    chatName = chat.name;
    imageLink = chat.chatImage;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        title: const Text(
          'Edit chat info',
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _saveChatInfo();
            },
            child: const Icon(Icons.check, size: 30),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: nameErrorText == null ? 70 : 83,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                        child: ConditionalWidget.single(
                          context: context,
                          conditionBuilder: (context) => chat.chatImage != null,
                          widgetBuilder: (context) {
                            return CachedNetworkImage(
                              imageUrl: chat.chatImage!,
                              fit: BoxFit.cover,
                              height: 70,
                              width: 70,
                              placeholder: (context, url) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: chat.avatarColor,
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: chat.avatarColor,
                              ),
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              child: Text(
                                chat.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.black, fontSize: 36),
                              ),
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
                  const SizedBox(width: 5),
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
                            hintText: 'Group name',
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
            InkWell(
              onTap: () {
                _uploadChatImage();
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(IconsaxPlusLinear.camera, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      chat.chatImage != null ? 'Set New Photo' : 'Set Photo',
                      style: const TextStyle(fontSize: 16, color: Colors.blueAccent, height: 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

      String url = await uploadTask.ref.getDownloadURL();
      chat = chat.copyWith(chatImage: url);
    }
    setState(() {
      uploadImageLoading = false;
    });
  }

  void _saveChatInfo() async {
    if (controller.text.isEmpty) {
      setState(() {
        nameErrorText = 'Group name cannot be empty';
      });
      return;
    }
    if (controller.text == chatName && imageLink == chat.chatImage) {
      Navigator.pop(context);
      return;
    }
    chat = chat.copyWith(name: controller.text);
    await dbReference.child('chats/${chat.id}').set(chat.toJson());
    if (mounted) Navigator.pop(context, chat);

    List<MessageModel> messages = [];
    if(controller.text != chatName){
      final textId = dbReference.child('messages/${chat.id}').push().key;
      MessageModel textMessage = MessageModel(
        id: textId!,
        text: '${userModel.value!.name} changed group name to «${controller.text}»',
        senderId: userModel.value!.uid,
        sentTime: DateTime.now().toUtc(),
        type: MessageType.event,
      );
      await dbReference.child('messages/${chat.id}/$textId').set(textMessage.toJson());
      messages.add(textMessage);
    }

    if (chat.chatImage != imageLink) {
      final textId = dbReference.child('messages/${chat.id}').push().key;
      MessageModel titleMessage = MessageModel(
        id: textId!,
        text: '${userModel.value!.name} updated group photo',
        senderId: userModel.value!.uid,
        sentTime: DateTime.now().toUtc(),
        type: MessageType.event,
      );
      await dbReference.child('messages/${chat.id}/$textId').set(titleMessage.toJson());
      final photoId = dbReference.child('messages/${chat.id}').push().key;
      MessageModel photoMessage = MessageModel(
        id: photoId!,
        text: chat.chatImage!,
        senderId: userModel.value!.uid,
        sentTime: DateTime.now().toUtc(),
        type: MessageType.event,
      );
      await dbReference.child('messages/${chat.id}/$photoId').set(photoMessage.toJson());
      messages.add(titleMessage);
    }

    for (final participantId in chat.participants) {
      await dbReference.child('userChats/$participantId/${chat.id}').update({
        'lastMessage': {
          'text': messages.last.text,
          'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          'sender': userModel.value!.uid
        },
        'unreadCount': participantId == userModel.value!.uid ? 0 : ServerValue.increment(messages.length),
      });
    }
  }
}
