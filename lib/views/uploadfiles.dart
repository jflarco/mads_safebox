import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:mads_safebox/widgets/fileuploadsettingsmodal.dart';


import '../services/file_service.dart';
import '../widgets/custom_snack_bar.dart';



class UploadFilesPage extends StatefulWidget {
  const UploadFilesPage({super.key});

  @override
  State<UploadFilesPage> createState() => _UploadFilesPageState();
}

class _UploadFilesPageState extends State<UploadFilesPage> {
  List<File> selectedFiles = [];
  FileService fileService = FileService();

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  void clearFiles() {
    setState(() {
      selectedFiles = [];
    });
  }

  Widget buildPreview(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ext == 'pdf'
              ? const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red)
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 150,
          child: Text(
            file.path.split('/').last,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
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
            const Text("Upload", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Expanded(
              child: selectedFiles.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Nenhum ficheiro selecionado"),
                  ],
                ),
              )
                  : GridView.builder(
                itemCount: selectedFiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  return buildPreview(selectedFiles[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: pickFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Upload From Library"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedFiles.isEmpty) {
                      showCustomSnackBar(context, 'Please select files first');
                      return;
                    }
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {

                          return FileUploadSettingsModal(selectedFiles: selectedFiles);
                        }
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
