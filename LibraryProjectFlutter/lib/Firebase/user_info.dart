class AppUserInfo {
  late String userId;
  late String name;
  late String email;
  // late String username;
  // late String imageAddress;
  // late String status;

  AppUserInfo(this.userId, this.name, this.email/*, this.status*/);

  Map<String, dynamic> toJson() => {
        'uid': userId,
        'name': name,
        'email': email,
        // 'username': username,
        // 'imageAddress': imageAddress,
        // 'status': status,
      };
}

AppUserInfo createUserInfo(record) {
  AppUserInfo user = AppUserInfo(
      record['userId'], record['name'], record['email']/*, record['status']*/);
  return user;
}
