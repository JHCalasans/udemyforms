import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:udemyforms/data/categories.dart';
import 'package:udemyforms/data/dummy_items.dart';
import 'package:udemyforms/models/category.dart';
import 'package:udemyforms/models/grocery.item.dart';
import 'package:udemyforms/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      "udemyflutter-72773-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception("FAILED TO FETCH GROCERY ITEMS.");
    }

    if (response.body == "null") {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItemsList = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value["category"],
          )
          .value;
      loadedItemsList.add(
        GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category),
      );
    }
    return loadedItemsList;
  }

  void _removeItem(GroceryItem item) async {
    final _index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https("udemyflutter-72773-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(_index, item);
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) {
          return const NewItem();
        },
      ),
    );

    // _loadItems();

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(
              Icons.add,
            ),
          )
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No items added yet."),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) {
              return Dismissible(
                key: ValueKey(snapshot.data![index].id),
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                child: ListTile(
                  title: Text(
                    snapshot.data![index].name,
                  ),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text(
                    snapshot.data![index].quantity.toString(),
                  ),
                ),
              );
            },
          );
        },
      ), // widget que lida com ações no futuro de acordo com a mudança de estado
    );
  }
}
