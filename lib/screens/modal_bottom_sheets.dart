import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legallyai/screens/document_screens/scanning.dart';

Future<void> showImageOrFileBottomSheet(BuildContext context, String? uid, String? chat_id) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.5),
    isScrollControlled: true,
    builder: (context) {
      File? selectedImageFile;
      PlatformFile? selectedDocFile;
      String? fileType; // "image" or "document"

      return StatefulBuilder(
        builder: (context, setState) {
          String getFileSize(int size) {
            final kb = size / 1024;
            final mb = kb / 1024;
            return mb >= 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
          }

          Color getColor(String? ext) {
            if (ext == null) return Color(0xFFBDBDBD);
            switch (ext.toLowerCase()) {
              case "pdf":
                return Color(0xFFF44336);
              case "doc":
              case "docx":
                return Color(0xFF1976D2);
              case "jpg":
              case "jpeg":
              case "png":
                return Color(0xFF43A047);
              default:
                return Color(0xFFBDBDBD);
            }
          }

          String getDisplayExtension(String? ext) {
            if (ext == null) return "";
            return ext.toUpperCase();
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white, // Ensure white background as per your request
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              left: 30,
              right: 30,
              top: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              // Ensures modal is scrollable for small screens/keyboard
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xFFA1A1A1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Upload your files",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Please choose whether to upload existing document or take a new picture.",
                    style: TextStyle(
                      color: Color(0xFFAEA4A4),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModalSheetButton(
                    text: "Select existing document",
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() {
                          selectedDocFile = result.files.first;
                          selectedImageFile = null;
                          fileType = "document";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ModalSheetButton(
                    text: "Capture document",
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedImage = await picker.pickImage(source: ImageSource.camera);
                      if (pickedImage != null) {
                        setState(() {
                          selectedImageFile = File(pickedImage.path);
                          selectedDocFile = null;
                          fileType = "image";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (fileType == "document" && selectedDocFile != null)
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Color(0xFFA9A9A9),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // File icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: getColor(selectedDocFile!.extension),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                getDisplayExtension(selectedDocFile!.extension),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          // File name and size
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedDocFile!.name,
                                  style: TextStyle(
                                    color: Color(0xFF292D32),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  getFileSize(selectedDocFile!.size),
                                  style: TextStyle(
                                    color: Color(0xFFAEA4A4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Remove button
                          IconButton(
                            icon: Icon(Icons.close, color: Color(0xFFAEA4A4), size: 20),
                            onPressed: () {
                              setState(() {
                                selectedDocFile = null;
                                fileType = null;
                              });
                            },
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  if (fileType == "image" && selectedImageFile != null)
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Color(0xFFA9A9A9),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              selectedImageFile!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedImageFile!.path.split('/').last,
                              style: TextStyle(
                                color: Color(0xFF292D32),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Color(0xFFAEA4A4), size: 20),
                            onPressed: () {
                              setState(() {
                                selectedImageFile = null;
                                fileType = null;
                              });
                            },
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  // Upload button if file/image is selected
                  if ((fileType == "document" && selectedDocFile != null) ||
                      (fileType == "image" && selectedImageFile != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 36, bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            

                            languageDialog(context, selectedImageFile, selectedDocFile, uid, chat_id);

                            
                            // Navigator.pop(context); 
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD4AF37),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Upload document",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<dynamic> languageDialog(BuildContext context, File? imageFile,
  PlatformFile? docFile, String? uid, String? chatId) {
  return showDialog(
  context: context,
  barrierDismissible: true,
  barrierColor: Colors.black.withOpacity(0.3),
  builder: (context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: EdgeInsets.symmetric(horizontal: 32),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google Translate icon (use Icon or Image.asset if you have a PNG)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.g_translate, size: 36, color: Color(0xFF3690F1)),
            ),
            SizedBox(height: 16),
            Text(
              "Choose Language",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              "Select a language for the summarized document.",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFAEA4A4),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        // Filipino logic
                        Navigator.of(context).pop("Filipino");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OCRScannerScreen(
                              imageFile: imageFile,
                              docFile: docFile,
                              language: "Filipino",
                              uid: uid,
                              chat_id: chatId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE69900),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Filipino",
                        style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        // English logic
                        Navigator.of(context).pop("English");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OCRScannerScreen(
                              imageFile: imageFile,
                              docFile: docFile,
                              language: "English",
                              uid: uid,
                              chat_id: chatId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3690F1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "English",
                        style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
}

class ModalSheetButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const ModalSheetButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      dashPattern: const [6, 3],
      color: const Color(0xFFD4AF37),
      strokeWidth: 1.5,
      child: Material(
        color: const Color(0xFFFFF4D1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.add, color: Color(0xFFD4AF37)),
                const Spacer(),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}