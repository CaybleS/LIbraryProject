

List<Book> exampleLibrary = [
  Book("Lord of the Rings", "J.R.R. Tolkien", true),
  Book("Alice's Adventures in Wonderland", "Lewis Carroll", imagePath: "assets/AliceCover.jpg", false),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", true, imagePath: "assets/LionWitchCover.jpg"),
  Book("Lord of the Rings", "J.R.R. Tolkien", true),
  Book("Alice's Adventures in Wonderland", "Lewis Carroll", imagePath: "assets/AliceCover.jpg", false),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", true, imagePath: "assets/LionWitchCover.jpg"),
  Book("Lord of the Rings", "J.R.R. Tolkien", true),
  Book("Alice's Adventures in Wonderland", "Lewis Carroll", imagePath: "assets/AliceCover.jpg", false),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", true, imagePath: "assets/LionWitchCover.jpg")
];

class Book {
  String title;
  String author;
  bool available;
  bool favorite = false;
  String? imagePath;

  Book(this.title, this.author, this.available, {this.imagePath});
}
