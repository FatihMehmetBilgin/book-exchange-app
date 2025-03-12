import 'package:flutter/material.dart';
import 'package:book_exchange/services/navigation_service.dart'; // NavigationService import
import 'package:get_it/get_it.dart';
import '../data/api/api_setup.dart';
import 'my_library.dart';
import 'add_book.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ApiService _apiService = ApiService();
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  List<Book> recommendedBooks = [];
  List<Book> myLibraryBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      // Önerilen kitaplar ve kullanıcı kütüphanesi için veri çekimi
      final recommended = await _apiService.searchBooks("bestsellers");
      final library =
          await _apiService.searchBooks("flutter"); // Kullanıcı kitapları örnek

      setState(() {
        recommendedBooks = recommended;
        myLibraryBooks = library;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching books: $e");
    }
  }

  void addToLibrary(Book book) {
    setState(() {
      myLibraryBooks.add(book);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${book.title} added to your library!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Library',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(Icons.chat, color: Colors.green),
                          title: Text('Chat'),
                          onTap: () {
                            Navigator.pop(context); // Modal'ı kapat
                            _navigationService
                                .pushNamed('/user'); // UserPage'e yönlendir
                          },
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.library_books, color: Colors.blue),
                          title: Text('My Library'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MyLibraryScreen(userId: 'exampleUserId'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Önerilenler Bölümü
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedBooks.length,
                      itemBuilder: (context, index) {
                        final book = recommendedBooks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () => addToLibrary(book),
                            child: Container(
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(book.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      book.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Kullanıcının Kütüphanesi
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'My Library',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: myLibraryBooks.length,
                    itemBuilder: (context, index) {
                      final book = myLibraryBooks[index];
                      return ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(book.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        trailing: Icon(Icons.more_vert),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigationService.pushNamed('/addBook');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
