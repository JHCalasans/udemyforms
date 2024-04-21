import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:udemyforms/data/categories.dart';
import 'package:udemyforms/models/category.dart';
import 'package:udemyforms/models/grocery.item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>(); // mantém o estado interno no build
  var _enteredName = "";
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables];
  var _isSending = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      final url = Uri.https(
        "udemyflutter-72773-default-rtdb.firebaseio.com",
        "shopping-list.json",
      );
      final response = await http.post(
        url,
        headers: {
          "Content-type": "application/json",
        },
        body: json.encode({
          "category": _selectedCategory!.title,
          "quantity": _enteredQuantity,
          "name": _enteredName,
        }),
      );

      if (response.statusCode == HttpStatus.ok) {
        final Map<String, dynamic> resData = json.decode(response.body);
        if (!context.mounted) // false se não for parte da screen
        {
          return;
        } else {
          Navigator.of(context).pop(GroceryItem(
              id: resData["name"],
              name: _enteredName,
              quantity: _enteredQuantity,
              category: _selectedCategory!));
        }
      }

      // Navigator.of(context).pop(
      //   GroceryItem(
      //     id: DateTime.now().toString(),
      //     category: _selectedCategory!,
      //     quantity: _enteredQuantity,
      //     name: _enteredName,
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                onSaved: (value) {
                  _enteredName = value!;
                },
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text(
                    "Name",
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return "Must be between 1 and 50 characters.";
                  }
                  return null;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      onSaved: (newValue) {
                        _enteredQuantity = int.parse(newValue!);
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text(
                          "Quantity",
                        ),
                      ),
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return "Must be a valid, positive number.";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                                value: category.value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: category.value.color,
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Text(
                                      category.value.title,
                                    ),
                                  ],
                                ))
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            // onpressed igual a null desabilita o botão
                            _formKey.currentState!.reset();
                          },
                    child: const Text(
                      "Reset",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : _saveItem, // onpressed igual a null desabilita o botão ,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text("Add item"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
