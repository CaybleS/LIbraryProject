
List<Book> exampleLibrary = [
  Book("Lord of the Rings", "J.R.R. Tolkien"),
  Book("Alice's Adventures in Wonderland", "Lewis Carroll", imagePath: "assets/AliceCover.jpg"),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", imagePath: "assets/LionWitchCover.jpg")
];

class Book {
  String title;
  String author;
  String? imagePath;

  Book(this.title, this.author, {this.imagePath});
}
