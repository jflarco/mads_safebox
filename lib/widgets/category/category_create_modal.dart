// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mads_safebox/models/category.dart';
import 'package:mads_safebox/services/category_service.dart';

import '../custom_snack_bar.dart';

class CategoryCreateModal extends StatefulWidget {
  final List<CategorySB> categories;
  const CategoryCreateModal({super.key, required this.categories});

  @override
  State<CategoryCreateModal> createState() => _CategoryCreateModalState();
}

class _CategoryCreateModalState extends State<CategoryCreateModal> {
  CategoryService categoryService = CategoryService();
  TextEditingController textController = TextEditingController();
  String infoText = "";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Write a unique category name",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: textController,
            ),
            const SizedBox(height: 8),
            infoText.isNotEmpty
                ? Text(
                    infoText,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  )
                : Container(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    String name = textController.text.trim();
                    if (name.isEmpty) {
                      setState(() {
                        infoText = "The name cannot be empty.";
                      });
                      return;
                    }

                    for (int i = 0; i < widget.categories.length; i++) {
                      if (name == widget.categories[i].name) {
                        setState(() {
                          infoText =
                              "You already have a category with that name.";
                        });
                        return;
                      }
                    }

                    final response = await categoryService.createCategory(name);

                    if (response != null) {
                      Navigator.of(context).pop(response);
                      showCustomSnackBar(context, "Category created");
                      return;
                    }
                    Navigator.of(context).pop();
                    showCustomSnackBar(context,
                        "An error occurred when creating the category");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Create Category'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
