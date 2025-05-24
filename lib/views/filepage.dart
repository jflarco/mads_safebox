
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../global/colors.dart';
import '../services/file_service.dart';
import '../widgets/custom_appbar.dart';
import '../models/file.dart';
import '../widgets/sharefilemodal.dart';

class FilePage extends StatefulWidget {
  final FileSB fileSB;
  final SharedSB? sharedSB;

  ///tou a passar o fileSB porque pode ser preciso para fazer a partilha (remover se nao for)
  final Uint8List file;
  const FilePage({super.key, required this.fileSB, required this.file, this.sharedSB} );

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  FileService fileService = FileService();

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> downloadFile() async {
    try {
      AuthService authService = AuthService();

      Directory? directory;
      // directory = await getApplicationDocumentsDirectory();
      // print("directory: $directory");
      directory = await getDownloadsDirectory();
      if (kDebugMode) {
        print("download directory: $directory");
      }
      // directory = await getExternalStorageDirectory();
      // print("external directory: $directory");

      final userId = authService.getCurrentUser().id;
      final targetDirPath = "${directory!.path}/$userId/${widget.fileSB.path.split("/").first}";
      if (kDebugMode) {
        print("targetDirPath: $targetDirPath");
      }
      final fileFullPath = "$targetDirPath/${widget.fileSB.path.split("/").last}";
      if (kDebugMode) {
        print("fileFullPath: $fileFullPath");
      }

      await Directory(targetDirPath).create(recursive: true);
      final filePath = fileFullPath;
      final file = File(filePath);

      if (await file.exists()) {
        showCustomSnackBar(context, "O arquivo '${widget.fileSB.name}' já existe.");
        return;
      }

      await requestStoragePermission();

      await file.writeAsBytes(widget.file);
      await MediaScanner.loadMedia(path: file.path);
      if (kDebugMode) {
        print("File downloaded to: ${file.path}");
      }

      if(await Permission.notification.request().isGranted) {
        // Mostra notificação de download
        await flutterLocalNotificationsPlugin.show(
          0,
          'Download concluído',
          widget.fileSB.name,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'download_channel',
              'Downloads',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: filePath, // Para abrir o arquivo depois
        );
      }

      showCustomSnackBar(context, "File downloaded");
    } catch (e) {
      if (kDebugMode) {
        print("Error downloading file: $e");
      }
      showCustomSnackBar(context, "Error downloading file");
    }
  }


  Widget buildFileView() {
    if (widget.fileSB.extension != "pdf") {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(
                widget.file,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 8),
              Text(widget.fileSB.name),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: Center(
        child: SfPdfViewer.memory(widget.file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(true),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: IconButton(
                      onPressed: () async {
                        await downloadFile();
                      },
                      icon: const Icon(Icons.download, color: mainColor)
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Your File",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: (){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return FileShareModal(fileSB: widget.fileSB);
                        }
                      );
                    },
                    icon: const Icon(Icons.share, color: mainColor)
                  ),
                )
              ],
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            buildFileView(),
          ],
        ),
      ),
    );
  }
}
