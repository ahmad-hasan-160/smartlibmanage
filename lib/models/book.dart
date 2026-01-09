class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String isbn;
  final int totalCopies;
  final int availableCopies;
  final String description;
  final String? imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.isbn,
    required this.totalCopies,
    required this.availableCopies,
    required this.description,
    this.imageUrl,
  });

  factory Book.fromMap(String id, Map<String, dynamic> data) {
    return Book(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      isbn: data['isbn'] ?? '',
      totalCopies: data['totalCopies'] ?? 0,
      availableCopies: data['availableCopies'] ?? 0,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'isbn': isbn,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}