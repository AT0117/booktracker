import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> inventory = [];

  Future<void> loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingBooksJson = prefs.getString('saved_books');

    if (existingBooksJson != null) {
      setState(() {
        inventory = json.decode(existingBooksJson);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inventory')),
      body: inventory.isEmpty
          ? const Center(child: Text("Your inventory is empty!"))
          : ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final book = inventory[inventory.length - 1 - index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: book['imageUrl'] != null
                        ? Image.network(
                            book['imageUrl'],
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.book),
                    title: Text(book['title'] ?? 'Unknown Title'),
                    subtitle: Text(book['author'] ?? 'Unknown Author'),
                    trailing: Text(
                      book['isbn'] ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
