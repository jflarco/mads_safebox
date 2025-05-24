
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/global/colors.dart';
import 'package:mads_safebox/global/default_category.dart';
import 'package:mads_safebox/services/category_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/views/sharedfilespage.dart';
import 'package:mads_safebox/views/uploadfiles.dart';
import 'package:mads_safebox/widgets/category/category_create_modal.dart';
import 'package:mads_safebox/widgets/category/category_delete_modal.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/category.dart';
import '../models/file.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../widgets/category/category_dropdownbutton.dart';
import '../widgets/category/category_rename_modal.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/sharefilemodal.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FileService fileService = FileService();
  CategoryService categoryService = CategoryService();
  bool isShowingImages = true;
  TextEditingController renameController = TextEditingController();

  Map<String, Uint8List> downloadedFiles = {};

  late Stream<List<FileSB>?> images;
  late Stream<List<FileSB>?> docs;
  late Future<List<CategorySB>> categories;

  CategorySB selectedCategory = defaultCategory;

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> downloadFile(FileSB fileSB, bool notifications) async {
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
      final targetDirPath = "${directory!.path}/$userId/${fileSB.path.split("/").first}";
      if (kDebugMode) {
        print("targetDirPath: $targetDirPath");
      }
      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      if (kDebugMode) {
        print("fileFullPath: $fileFullPath");
      }

      await Directory(targetDirPath).create(recursive: true);
      final filePath = fileFullPath;
      final file = File(filePath);

      if (await file.exists()) {
        notifications ? showCustomSnackBar(context, "O arquivo '${fileSB.name}' já existe.") : null;
        return;
      }

      await requestStoragePermission();

      if(!downloadedFiles.containsKey(fileSB.name)){
        Uint8List? file = await fileService.getFile(fileSB.path);
        downloadedFiles[fileSB.name] = file!;
      }

      await file.writeAsBytes(downloadedFiles[fileSB.name]!);
      if (kDebugMode) {
        print("File downloaded to: ${file.path}");
      }

      if(notifications) {
        // Mostra notificação de download
        await Permission.notification.request().isGranted ? await flutterLocalNotificationsPlugin.show(
          0,
          'Download concluído',
          fileSB.name,
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
          payload: filePath,
        ) : null;
      }

      notifications ? showCustomSnackBar(context, "File downloaded") : null;
    } catch (e) {
      if (kDebugMode) {
        print("Error downloading file: $e");
      }
      notifications ? showCustomSnackBar(context, "Error downloading file") : null;
    }
  }

  @override
  void initState() {
    super.initState();
    initValues();
  }

  @override
  void dispose() {
    renameController.dispose();
    super.dispose();
  }

  Future<void> initValues() async {
    categories = categoryService.getCategories();
    images = fileService.getImageList();
    docs = fileService.getDocList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(false),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 12),
          //Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                buildCategoryDropdown(
                  categoriesFuture: categories,
                  selectedCategory: selectedCategory,
                  onChanged: (CategorySB? value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                selectedCategory.id != 1
                    ? IconButton(
                        onPressed: () async {
                          List<CategorySB> catValues = await categories;
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CategoryRenameModal(
                                  categories: catValues,
                                  selectedCategoryId: selectedCategory.id,
                                );
                              }).then((value) async {
                            if (value != null) {
                              selectedCategory.name = value;
                              (await categories)
                                  .firstWhere((element) =>
                                      element.id == selectedCategory.id)
                                  .name = value;
                              setState(() {});
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: mainColor,
                        ),
                      )
                    : Icon(
                        Icons.edit,
                        color: Colors.grey.shade300,
                      ),
                const SizedBox(width: 8),
                selectedCategory.id != 1
                    ? IconButton(
                        onPressed: () async {
                          List<CategorySB> catValues = await categories;

                          ///remove the selected category so the user cant transfer the files to the category being deleted
                          catValues.remove(selectedCategory);

                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CategoryDeleteModal(
                                    categories: Future.value(catValues),
                                    idCategoryToDelete: selectedCategory.id);
                              }).then((value) async {
                            if (value != null) {
                              (await categories).remove(selectedCategory);
                              selectedCategory = (await categories).first;
                              setState(() {});
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: mainColor,
                        ),
                      )
                    : Icon(
                        Icons.delete,
                        color: Colors.grey.shade300,
                      )
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tabs (Files / Images)
          buildFileTypeSelector(),
          const SizedBox(height: 24),
          Text(
            isShowingImages ? "Your Images" : "Your Files",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // File List
          Expanded(
            child: buildFileList(),
          ),
          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    List<CategorySB> catValue = await categories;

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CategoryCreateModal(categories: catValue);
                      },
                    ).then((value) async {
                      if (value != null) {
                        (await categories).add(value);
                        setState(() {});
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Add Category",
                    style: TextStyle(color: mainTextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => const FilePickerDialog(),
                    // );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadFilesPage(),
                        )).then((value) {
                      setState(() {
                        initValues();
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Add File",
                    style: TextStyle(color: mainTextColor),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SharedFilesPage(),
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "View Shared Files",
                style: TextStyle(color: mainTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding buildFileTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // Files tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isShowingImages = false);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isShowingImages ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.insert_drive_file,
                    color: isShowingImages ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            // Images tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isShowingImages = true);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isShowingImages ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.image,
                    color: isShowingImages ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StreamBuilder<List<FileSB>?> buildFileList() {
    return StreamBuilder<List<FileSB>?>(
      stream: isShowingImages ? images : docs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading files."));
        } else {
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No files found."));
          }

          List<ListTile> tiles = buildFilesListTiles(snapshot.data!);

          return tiles.isEmpty
              ? const Center(child: Text("No files found."))
              : ListView(children: tiles);
        }
      },
    );
  }

  List<ListTile> buildFilesListTiles(List<FileSB> files) {
    List<ListTile> tiles = [];

    for (int i = 0; i < files.length; i++) {
      if (selectedCategory.id != files[i].categoryId) {
        continue;
      }
    
      tiles.add(ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: GestureDetector(
                onTap: () async {
                  if (downloadedFiles.containsKey(files[i].name)) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilePage(
                              fileSB: files[i],
                              file: downloadedFiles[files[i].name]!),
                        ));
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Downloading File"),
                              SizedBox(height: 8),
                              Loading(),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  Uint8List? file = await fileService.getFile(files[i].path);

                  if (kDebugMode) {
                    print(files[i].path);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);

                    if (file == null) {
                      showCustomSnackBar(
                          context, 'Could not download the file');
                      return;
                    }

                    downloadedFiles[files[i].name] = file;

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FilePage(fileSB: files[i], file: file),
                        ));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Icon(Icons
                          .image), //TODO : Colocar aqui a miniatura da imagem
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        files[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: PopupMenuButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.black,
                ),
                itemBuilder: (BuildContext context) {
                  return getFileOptionsButtonList(files[i]);
                },
              ),
            )
          ],
        ),
      ));
    }

    return tiles;
  }

  List<PopupMenuItem> getFileOptionsButtonList(FileSB fileSB) {
    return [
      PopupMenuItem(
        child: const Text("Delete", style: TextStyle(color: Colors.black)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
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
                            "Are you sure you want to delete this file?"),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final bool response =
                                    await fileService.deleteFile(fileSB);
                                if (response) {
                                  Navigator.of(context).pop();
                                  showCustomSnackBar(context, "File deleted");
                                  setState(() {
                                    images = fileService.getImageList();
                                    docs = fileService.getDocList();
                                  });
                                  return;
                                }

                                Navigator.of(context).pop();
                                showCustomSnackBar(context,
                                    "An error occurred when deleting the file");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Delete'),
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
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Rename", style: TextStyle(color: Colors.black)),
        onTap: () {
          renameController.text = fileSB.name
              .substring(0, fileSB.name.length - fileSB.extension.length - 1);

          showDialog(
              context: context,
              builder: (context) {
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
                        const Text("Write the new name"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: renameController,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final bool response = await fileService.renameFile(
                                    fileSB,
                                    "${renameController.text.trim()}.${fileSB.extension}");

                                if (response) {
                                  Navigator.of(context).pop();
                                  showCustomSnackBar(context, "File renamed");
                                  setState(() {
                                    images = fileService.getImageList();
                                    docs = fileService.getDocList();
                                  });
                                  return;
                                }
                                Navigator.of(context).pop();
                                showCustomSnackBar(context,
                                    "An error occurred when renaming the file");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Rename'),
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
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Share", style: TextStyle(color: Colors.black)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return FileShareModal(fileSB: fileSB);
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Download", style: TextStyle(color: Colors.black)),
        onTap: () async {
          await downloadFile(fileSB, true);
        },
      ),
    ];
  }
}
