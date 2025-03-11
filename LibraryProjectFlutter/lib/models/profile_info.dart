import 'package:shelfswap/models/book.dart';

// I'm going to store the profile stuff in a new section of the db since it will only be needed on the profile page
class ProfileInfo {
  String? aboutMe;
  String? favGenre;
  List<Book> favBooks = [];

  ProfileInfo({this.aboutMe, this.favGenre});

  factory ProfileInfo.fromJson(Map<dynamic, dynamic> json) {
    ProfileInfo profileInfo = ProfileInfo();
    profileInfo.aboutMe = json['aboutMe'];
    profileInfo.favGenre = json['favGenre'];
    if (json['favBooks'] != null) {
      List<dynamic> books = json['favBooks'];
      List<Book> favBooks = [];
      for (var record in books) {
        Book book = createBookFromJson(record);
        favBooks.add(book);
      }
      profileInfo.favBooks = List.from(favBooks);
    }

    return profileInfo;
  }

  Map<dynamic, dynamic> toJson() {
    Map<dynamic, dynamic> map = {};
    int count = 0;
    for (var book in favBooks) {
      map[count] = book.toJson();
      count++;
    }
    return {
      'aboutMe': aboutMe,
      'favGenre': favGenre,
      'favBooks': map
    };
  }
}
