import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by title, author, or category',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: bookProvider.searchBooks,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bookProvider.books.length,
              itemBuilder: (context, index) {
                final book = bookProvider.books[index];
                return ListTile(
                  leading: book.imageUrl != null && book.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.imageUrl!,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 40),
                          ),
                        )
                      : const Icon(Icons.book, size: 40),
                  title: Text(book.title),
                  subtitle: Text('${book.author} - ${book.category}'),
                  trailing: Text('${book.availableCopies}/${book.totalCopies}'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}