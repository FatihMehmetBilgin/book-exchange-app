import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/api/api_setup.dart'; // ApiSetup dosyasının bulunduğu yer

class MyLibraryScreen extends StatefulWidget {
  final String userId; // Kullanıcı kimliği

  MyLibraryScreen({required this.userId});

  @override
  _MyLibraryScreenState createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Book> myLibraryBooks = [];
  List<Book> searchResults = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchLibraryBooks();
  }

  // Kullanıcının kütüphanesindeki kitapları getir
  Future<void> fetchLibraryBooks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('libraries')
          .doc(widget.userId)
          .collection('books')
          .get();

      setState(() {
        myLibraryBooks = snapshot.docs.map((doc) {
          return Book(
            title: doc['title'],
            author: doc['author'],
            imageUrl: doc['imageUrl'],
            description: doc['description'],
            id: doc.id,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching library books: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Kitap arama (ApiSetup ile)
  Future<void> searchBooks(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      final results =
          await ApiService().searchBooks(query); // ApiSetup içindeki metot
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      print("Error searching books: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Kitabı kütüphaneye ekleme
  void addBookToLibrary(Book book) async {
    try {
      await _firestore
          .collection('libraries')
          .doc(widget.userId)
          .collection('books')
          .doc(book.id)
          .set({
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'description': book.description,
      });

      setState(() {
        myLibraryBooks.add(book); // Yeni eklenen kitabı listeye ekle
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} added to your library')),
      );
    } catch (e) {
      print("Error adding book to library: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add book')),
      );
    }
  }

  // Kitabı kütüphaneden silme
  Future<void> deleteBookFromLibrary(String bookId) async {
    try {
      await _firestore
          .collection('libraries')
          .doc(widget.userId)
          .collection('books')
          .doc(bookId)
          .delete();

      setState(() {
        myLibraryBooks.removeWhere(
            (book) => book.id == bookId); // Silinen kitabı listeden çıkar
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book removed from your library')),
      );
    } catch (e) {
      print("Error deleting book: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Library',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Books",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (searchQuery.isNotEmpty) {
                      searchBooks(searchQuery);
                    }
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Gövde
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Kütüphanedeki Kitaplar
                      if (myLibraryBooks.isNotEmpty) ...[
                        Text(
                          'Your Library',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        ...myLibraryBooks.map((book) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: book.imageUrl.isNotEmpty
                                  ? Image.network(book.imageUrl,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Icon(Icons.book, size: 50),
                              title: Text(book.title),
                              subtitle: Text(book.author),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        deleteBookFromLibrary(book.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      SizedBox(height: 16),
                      // Arama Sonuçları
                      if (searchResults.isNotEmpty) ...[
                        Text(
                          'Search Results',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        ...searchResults.map((book) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: book.imageUrl.isNotEmpty
                                  ? Image.network(book.imageUrl,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Icon(Icons.book, size: 50),
                              title: Text(book.title),
                              subtitle: Text(book.author),
                              trailing: IconButton(
                                icon: Icon(Icons.add, color: Colors.green),
                                onPressed: () => addBookToLibrary(book),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
