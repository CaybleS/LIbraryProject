# Shelfswap

A mobile app designed for sharing books with your friends. Users can track the books they own, lend them to friends, and view friends' libraries. [Download on Google Play Store](https://play.google.com/store/apps/details?id=com.shelfswap&hl=en_US)

## Features

- **Track Personal Library:** Keep track of the books you own. Search the database to find your book, or upload your own with a photo and title
- **Lend & Borrow Books:** See what books you have lent out and to whom. Request and borrow books from your friends. Customize the amount of time that the book is lent for
- **Filter & Sort Libraries:** Find books easier using the filtering and sorting options within both your personal and friends' libraries
- **Social Network:** Connect with friends to share and view each other’s book collections
- **In-App Messaging:** Communicate with friends to coordinate book pickups, drop-offs, and other details. Create group chats or send pictures to show the condition of the book

## Software Stack

- **Frontend:** [Flutter](https://flutter.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) - authentication and database, [AWS](https://aws.amazon.com/) - storage and notifications

## Install & Run Locally
1. Install Flutter, the project runs on version 3.24.3
2. Install Android Studio, the project runs on 2023 23.3.1 Patch 1 (if you use other versions, it's probably not gonna work btw)
3. Git clone the project
4. `cd` to LibraryProjectFlutter directory
5. Create a Firebase project, and follow the steps where you add Firebase to an Android app. In this process, you will have an option to add an SHA key. You need to do this, but this will be done in a later step. Be careful with changing files because our file structure works.
6. Go to project settings and download `google-services.json` in project settings, and put it in `LibraryProjectFlutter\android\app`
7. To run in debug mode, you have to go to your java bin (for example, it may be `C:\Program Files\Java\jdk-23\bin`), get the Android `debug.keystore` file (for example mine is in `C:\Users\Jonathan\.android\debug.keystore`), and run the command `keytool -list -v -keystore "<debug.keystore directory>" -alias androiddebugkey -storepass android -keypass android`. This generates an SHA key. You need to go to Firebase project settings, scroll down, and go to the Android app that exists at the bottom. Add the SHA certificate fingerprint there that was generated as a result of this command.
8. To run the app, you need to create a `.env` file in the LibraryProjectFlutter directory following the format. Create an AWS account and get this info related to it, specifically AWS access key and secret access key
```
GOOGLE_BOOKS_API_KEY=<your Google Books api key>
AWS_ACCESS_KEY=<your AWS access key>
AWS_SECRET_ACCESS_KEY=<your AWS secret access key>
AWS_ACCOUNT_ID=<your AWS account id>
```
9. Our `.env` also contains an entry `AWS_SEND_NOTIFICATION_ENDPOINT=` which links to a lambda function that sends notifications. This Lambda function source code, and setup, can be found [here](https://github.com/jidoux/shelfswap-send-notification-lambda).

If you are running a non-deployed version of the app, you need to change your `build.gradle` in the `android/app/` directory.
**You need to comment out the lines:**
```
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```
```
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"]) //?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```
10. And then change the line: `signingConfig = signingConfigs.getByName("release")`, change the “release” text to “debug”
11. Run the app
