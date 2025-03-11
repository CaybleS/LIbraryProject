import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.avatarColor,
    this.width = 50,
    this.height = 50,
    this.radius = 50,
    this.fontSize = 20,
  });

  final String? photoUrl;
  final String name;
  final Color avatarColor;
  final double width;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: photoUrl != null
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              height: height,
              width: width,
              placeholder: (context, url) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: SharedWidgets.displayCircularProgressIndicator(2),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              width: width,
              height: height,
              alignment: Alignment.center,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              ),
            ),
    );
  }
}
