//add_book.dart
import 'package:flutter/material.dart';
import '../data/api/api_setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final Geoflutterfire _geo = Geoflutterfire(); // GeoFlutterFire örneği
  List<Book> searchResults = [];
  Map<String, List<String>> bookOwners =
      {}; // Kitap ID'sine göre kullanıcı ID'lerini tutar.
  bool isLoading = false;
  Position? userPosition;

  Future<void> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Konum hizmetleri devre dışı.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Konum izni verilmedi.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Konum izni kalıcı olarak reddedildi.");
      }

      userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  Future<void> searchBooksNearby() async {
    if (userPosition == null) {
      await getUserLocation();
    }

    if (userPosition != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Kullanıcının konumunu alın
        final userLocation = _geo.point(
          latitude: userPosition!.latitude,
          longitude: userPosition!.longitude,
        );

        // Firestore koleksiyonuna erişim
        final collectionRef =
            FirebaseFirestore.instance.collection('libraries');

        // Sorgu oluştur
        final stream = _geo.collection(collectionRef: collectionRef).within(
              center: userLocation,
              radius: 10.0,
              field: 'location',
            );

        // Verileri dinleyin
        stream.listen((documents) {
          List<Book> books = documents
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                return Book.fromJson(data);
              })
              .whereType<Book>()
              .toList(); // Null olanları filtrele
          setState(() {
            searchResults = books;
          });
        });
      } catch (e) {
        print("Error searching nearby books: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> addToLibrary(Book book) async {
    final userId = "exampleUserId"; // Dinamik kullanıcı ID'si eklenmeli.
    final libraryRef =
        FirebaseFirestore.instance.collection('libraries').doc(userId);

    try {
      if (userPosition == null) {
        await getUserLocation();
      }

      final userLocation = _geo.point(
        latitude: userPosition!.latitude,
        longitude: userPosition!.longitude,
      );

      await libraryRef.collection('books').doc(book.id).set({
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        'description': book.description,
        'location': userLocation.data,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${book.title} added to your library!")),
      );
    } catch (e) {
      print("Error adding book to library: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add book to library.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Add Book',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Books',
                labelStyle: TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.blue),
                  onPressed: searchBooksNearby,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final book = searchResults[index];
                        final owners = bookOwners[book.id] ?? [];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(book.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              book.author,
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  addToLibrary(book),
                                              child: Text('Add to Library'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (owners.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Available with:',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        ...owners.map((owner) => ListTile(
                                              title: Text(
                                                owner,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              trailing: Icon(Icons.chat,
                                                  color: Colors.blue),
                                              onTap: () {
                                                // Mesajlaşma ekranına yönlendirme kodu buraya gelecek.
                                              },
                                            )),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
