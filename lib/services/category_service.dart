import 'package:flutter/foundation.dart';
import 'package:mads_safebox/global/default_category.dart';
import 'package:mads_safebox/models/category.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  // This class is responsible for category operations
  // such as reading, writing, and deleting categories.
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final AuthService authService = AuthService();


  Future<CategorySB?> createCategory(String name) async {

    try {
      final response = await supabaseClient
          .from('categories')
          .insert({
            'uid': authService.getCurrentUser().id,
            'name': name.trim(),
          })
          .select();
      return CategorySB.fromJson(response.first);
    } catch (e) {
      if (kDebugMode) {
        print("Error creating category:\n$e\n");
      }
      return null;
    }
  }

  Future<List<CategorySB>> getCategories() async {
    final userId = authService.getCurrentUser().id;
    List<CategorySB> categories = [defaultCategory];
    try {
      final response = await supabaseClient
          .from('categories').select()
          .eq("uid", userId);

      categories.addAll(
        (response as List)
            .map((item) => CategorySB.fromJson(item))
            .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao obter categorias");
      }
    }
    return categories;
  }

  Future<bool> deleteCategory(int idToDelete) async {
    try {
      await supabaseClient.from('categories').delete().eq("id", idToDelete);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("\nError when deleting category:\n$e\n");
      }
      return false;
    }
  }

  Future<bool> renameCategory(int id, String name) async {
    try {
      await supabaseClient
          .from('categories')
          .update({"name": name}).eq("id", id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("\nError when renaming category:\n$e\n");
      }
      return false;
    }
  }
}
