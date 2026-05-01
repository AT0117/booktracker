import 'dart:convert';

import 'package:booktracker/inventory.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isScanning = false;
  String statusMessage = "Take a pic of the books barcode";
  String? scannedIsbn;
  String? bookTitle;
  String? bookAuthor;
  String? coverImageUrl;

  final ImagePicker imagePicker = ImagePicker();
  final BarcodeScanner barcodeScanner = BarcodeScanner();

  Future<void> scanBook() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image == null) return;

      setState(() {
        isScanning = true;
        statusMessage = "Analysing barcode...";
        bookTitle = null;
        bookAuthor = null;
        coverImageUrl = null;
      });

      final inputImage = InputImage.fromFilePath(image.path);
      final List<Barcode> barcodes = await barcodeScanner.processImage(
        inputImage,
      );
      if (barcodes.isEmpty) {
        setState(() {
          statusMessage = "No barcodes found!";
        });
        return;
      }

      final String isbn = (barcodes.first.rawValue ?? "").trim();

      setState(() {
        scannedIsbn = isbn;
        statusMessage = "Found ISBN: $isbn \n Fetching book details...";
      });

      await fetchBookDetails(isbn);
    } catch (e) {
      setState(() {
        statusMessage = "Error : $e";
      });
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> fetchBookDetails(String isbn) async {
    final url = Uri.parse(
      "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['totalItems'] > 0) {
          final volumeInfo = data['items'][0]['volumeInfo'];

          setState(() {
            statusMessage = "Book Found!";
            bookTitle = volumeInfo['title'] ?? "Unknown Title";

            if (volumeInfo['authors'] != null) {
              bookAuthor = (volumeInfo['authors'] as List).join(', ');
            } else {
              bookAuthor = "Unknown Author";
            }

            if (volumeInfo['imageLinks'] != null) {
              [
                coverImageUrl = volumeInfo['imageLinks']['thumbnail']
                    .toString()
                    .replaceAll('http:', 'https:'),
              ];
            }
          });
        } else {
          setState(() {
            statusMessage = "Barcode scanned ($isbn), but book not found";
          });
        }
      } else {
        setState(() {
          statusMessage =
              "GOOGLE API ERROR: ${response.statusCode} \n RESPONSE BODY: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Network Error";
      });
    }
  }

  Future<void> saveBookToInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingBooksJson = prefs.getString('saved_books');
    List<dynamic> savedBooks = [];
    if (existingBooksJson != null) {
      savedBooks = jsonDecode(existingBooksJson);
    }

    final Map<String, dynamic> newBook = {
      'isbn': scannedIsbn,
      'title': bookTitle,
      'author': bookAuthor,
      'imageUrl': coverImageUrl,
    };

    savedBooks.add(newBook);
    await prefs.setString('saved_books', json.encode(savedBooks));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Book added to inventory!')));

    setState(() {
      scannedIsbn = null;
      bookTitle = null;
      bookAuthor = null;
      coverImageUrl = null;
      statusMessage = "Snap a picture of the next book!";
    });
  }

  @override
  void dispose() {
    barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InventoryPage()),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    coverImageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.menu_book_rounded,
                  size: 100,
                  color: Colors.indigo.shade200,
                ),

              const SizedBox(height: 24),

              if (bookTitle != null) ...[
                Text(
                  bookTitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (bookAuthor != null) ...[
                Text(
                  "by $bookAuthor",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 40),

              if (isScanning)
                const CircularProgressIndicator()
              else if (bookTitle != null)
                ElevatedButton.icon(
                  onPressed: saveBookToInventory,
                  icon: const Icon(Icons.save),
                  label: const Text("Save to Inventory"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                )
              else
                // Default "Scan" button
                ElevatedButton.icon(
                  onPressed: scanBook,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Scan Book Barcode"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
