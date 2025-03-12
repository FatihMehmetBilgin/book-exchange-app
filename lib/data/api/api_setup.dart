import 'dart:convert';
import 'package:http/http.dart' as http;

class Book {
  final String title;
  final String author;
  final String imageUrl;
  final String description;
  final String id;

  Book({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.description,
    required this.id,
  });

  // JSON'dan veri alıp Book nesnesi oluşturma
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    return Book(
      title: volumeInfo['title'] ?? 'No Title',
      author: (volumeInfo['authors'] as List?)?.join(', ') ?? 'No Author',
      imageUrl: imageLinks['thumbnail'] ?? '',
      description: volumeInfo['description'] ?? 'No Description',
      id: json['id'] ?? '',
    );
  }
}

class ApiService {
  final String _baseUrl = "https://www.googleapis.com/books/v1/volumes";
  final String _apiKey =
      "AIzaSyBqC4DwuunRgy1zKL1Sf2zpG3eZXfIshyQ"; // API Key'inizi buraya ekleyin.

  // Singleton instance (tekil nesne oluşturma)
  static final ApiService _instance = ApiService._internal();

  ApiService._internal();
  factory ApiService() => _instance;

  // Kitapları Google Books API'den arar.
  Future<List<Book>> searchBooks(String query) async {
    final url = Uri.parse("$_baseUrl?q=$query&key=$_apiKey");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Book> books = [];

        for (var item in data['items']) {
          books.add(Book.fromJson(item));
        }

        return books;
      } else {
        throw Exception("Hata: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("API calling error: $e");
    }
  }
}
