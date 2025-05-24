import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sharedplusfile.dart';

class ShareFilesService {

  Future<void> shareFile(int fileId, String filePath, DateTime expireDate, String role, String url, String password) async {
    if(expireDate.isBefore(DateTime.now())) {
      if (kDebugMode) {
        print('Error: Expiration date must be in the future.');
      }
      return;
    }
    if(role != 'View' && role != 'Edit') {
      if (kDebugMode) {
        print('Error: Role must be either "View" or "Edit".');
      }
      return;
    }
    var expireDateToSupabase = DateFormat('yyyy-MM-dd').format(expireDate);

    try {
      await Supabase.instance.client
          .from('shared')
          .insert({
            'file_id': fileId,
            'path': filePath,
            'uid': Supabase.instance.client.auth.currentUser!.id,
            'expire_date': expireDateToSupabase,
            'role': role,
            'url': url,
            'password': password,
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing file: $e');
      }
    }
  }

  Future<SharedSB?> getSharedFileFromLink(int fileId, DateTime date, String role, String password) async {
    if(date.isBefore(DateTime.now())) {
      if (kDebugMode) {
        print('Error: Autorization expired.');
      }
      throw Exception('Autorization expired');
    }
    role = role.substring(0,1).toUpperCase() + role.substring(1).toLowerCase();
    try {
      final response = await Supabase.instance.client
          .from('shared')
          .select()
          .eq('file_id', fileId)
          .eq('expire_date', date)
          .eq('role', role)
          .eq('password', password);
      final List<SharedSB> sharedList = (response)
          .map((item) => SharedSB.fromJson(item))
          .toList();
      if (kDebugMode) {
        print(sharedList);
      }
      if(sharedList.isEmpty){
        return null;
      }
      SharedSB sharedSB = sharedList.first;

      if(!sharedSB.sharedWith.contains(Supabase.instance.client.auth.currentUser!.id)){
        sharedSB.sharedWith.add(Supabase.instance.client.auth.currentUser!.id);

        await Supabase.instance.client
            .from('shared')
            .update({'sharedWith': sharedSB.sharedWith})
            .eq('id', sharedSB.id);
      }
      return sharedSB;


    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shared files: $e');
      }
      return null;
    }
  }

  Future<List<SharedFileSB>> getSharedFiles() async {

    try {
      final response = await Supabase.instance.client
          .from('shared')
          .select()
          .contains('sharedWith', [Supabase.instance.client.auth.currentUser!.id])
          .gte('expire_date', DateFormat('yyyy-MM-dd').format(DateTime.now()));
      final List<SharedSB> sharedList = (response)
          .map((item) => SharedSB.fromJson(item))
          .toList();

      List<SharedFileSB> sharedFiles = sharedList.map(
        (shared) {
          return SharedFileSB(
            sharedSB: shared,
          );
        },
      ).toList();

      return sharedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching shared files: $e');
      }
      throw Exception('Error fetching shared files');
    }
  }

}