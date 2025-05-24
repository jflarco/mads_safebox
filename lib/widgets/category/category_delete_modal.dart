// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mads_safebox/global/default_category.dart';
import 'package:mads_safebox/services/file_service.dart';
import 'package:mads_safebox/widgets/loading.dart';

import '../../models/category.dart';
import '../../services/category_service.dart';
import '../custom_snack_bar.dart';
import 'category_dropdownbutton.dart';

class CategoryDeleteModal extends StatefulWidget {
  final Future<List<CategorySB>> categories;
  final int idCategoryToDelete;
  const CategoryDeleteModal(
      {super.key, required this.categories, required this.idCategoryToDelete});

  @override
  State<CategoryDeleteModal> createState() => _CategoryDeleteModalState();
}

class _CategoryDeleteModalState extends State<CategoryDeleteModal> {
  CategoryService categoryService = CategoryService();
  FileService fileService = FileService();
  CategorySB currentCategory = defaultCategory;
  TextEditingController textController = TextEditingController();
  String title = "Are you sure you want to delete this category?";
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildDialogBody(),
      ),
    );
  }

  Column buildDialogBody() {
    if (isDeleting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Loading(),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "This category's files will be moved to:",
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        buildCategoryDropdown(
            categoriesFuture: widget.categories,
            selectedCategory: currentCategory,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  currentCategory = value;
                });
              }
            }),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  title = "Moving Files";
                  isDeleting = true;
                });
                final responseFiles = await fileService.changeFilesCategory(
                    widget.idCategoryToDelete, currentCategory.id);
                final response = await categoryService
                    .deleteCategory(widget.idCategoryToDelete);

                if (response && responseFiles) {
                  Navigator.of(context).pop(response);
                  showCustomSnackBar(context, "Category deleted");
                  return;
                }
                Navigator.of(context).pop();
                showCustomSnackBar(
                    context, "An error occurred when deleting the category");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Delete Category'),
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
        )
      ],
    );
  }
}
