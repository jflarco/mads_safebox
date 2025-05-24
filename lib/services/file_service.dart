import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mads_safebox/models/sharedplusfile.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/file.dart';

class FileService {
  // This class is responsible for file operations
  // such as reading, writing, and deleting files.
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final AuthService authService = AuthService();

  Future<void> uploadFile(
      List<File> file, int? selectedCategoryId, DateTime? expiringDate) async {
    try {
      await supabaseClient.storage
          .createBucket(authService.getCurrentUser().id);
    } catch (e) {
      // Handle the case where the bucket already exists
      if (e.toString().contains('The resource already exists')) {
        if (kDebugMode) {
          print('Bucket already exists, proceeding with upload.');
        }
      } else {
        if (kDebugMode) {
          print('Error creating bucket: $e');
        }
      }
    }
    for (var file in file) {
      try {
        String uploadPath = '${DateTime.now().millisecondsSinceEpoch}/${file.path.split('/').last}';
        if (kDebugMode) {
          print("Upload path: $uploadPath");
        }
        final response = await supabaseClient.storage
            .from(authService.getCurrentUser().id)
            .upload(uploadPath, file);
        if (kDebugMode) {
          print("File uploaded: $response");
        }

        await supabaseClient.from('files').insert({
          'uid': authService.getCurrentUser().id,
          'name': file.path.split('/').last,
          'extension': file.path.split('.').last,
          'size': file.lengthSync(),
          'path': uploadPath,
          'category_id': selectedCategoryId,
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading file: $e');
        }
      }
    }
  }

  Future<bool> deleteFile(FileSB fileSB) async {
    try {
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .remove([fileSB.path]);
      await supabaseClient.from('files').delete().eq("id", fileSB.id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("\nError when deleting file:\n$e\n");
      }
      return false;
    }
  }

  Future<bool> renameFile(FileSB fileSB, String name) async {
    try {
      String newPath =
          fileSB.path.substring(0, fileSB.path.length - fileSB.name.length) +
              name;
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .copy(fileSB.path, newPath);
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .remove([fileSB.path]);
      await supabaseClient
          .from('files')
          .update({"name": name, "path": newPath}).eq("id", fileSB.id);
      await supabaseClient
          .from('shared')
          .update({"path": newPath}).eq("file_id", fileSB.id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("\nError when renaming file:\n$e\n");
      }
      return false;
    }
  }

  Future<Uint8List?> getFile(String path) async {
    try {
      final Uint8List response = await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .download(path);//todo removi o transform porque dava erro com os pdfs

      if (kDebugMode) {
        print("File downloaded: ${response.lengthInBytes} bytes");
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }

  Future<Uint8List?> getSharedFile(String path, String uid) async {
    try {
      final Uint8List response =
          await supabaseClient.storage.from(uid).download(path);

      if (kDebugMode) {
        print("File downloaded: ${response.lengthInBytes} bytes");
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
  }

  Future<FileSB> getFileSB(int id) {
    return supabaseClient
        .from('files')
        .select()
        .eq('id', id)
        .single()
        .then((data) => FileSB.fromJson(data));
  }

  Stream<List<FileSB>?> getImageList() {
    final userId = authService.getCurrentUser().id;

    return supabaseClient
        .from('files')
        .stream(primaryKey: ['id'])
        .eq("uid", userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((file) => ["jpeg", "jpg", "png"]
                .contains(file['extension']?.toLowerCase()))
            .map<FileSB>((file) => FileSB.fromJson(file))
            .toList());
  }

  Stream<List<FileSB>?> getDocList() {
    final userId = authService.getCurrentUser().id;

    return supabaseClient
        .from('files')
        .stream(primaryKey: ['id'])
        .eq("uid", userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((file) => ["pdf"].contains(file['extension']?.toLowerCase()))
            .map<FileSB>((file) => FileSB.fromJson(file))
            .toList());
  }

  Future<bool> changeFilesCategory(int idOrigin, int idDestination) async {
    try {
      await supabaseClient
          .from('files')
          .update({'category_id': idDestination})
          .eq('uid', authService.getCurrentUser().id)
          .eq('category_id', idOrigin);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }
  }

  Future<List<SharedFileSB>> getSharedFiles(List<SharedFileSB> sharedFiles) async {
    try {
      for (var sharedFile in sharedFiles) {
        final response = await supabaseClient
            .from('files')
            .select()
            .eq('id', sharedFile.sharedSB.fileId)
            .single();

        sharedFile.fileSB = FileSB.fromJson(response);
      }

      return sharedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shared files: $e');
      }
      return [];
    }
  }
}
