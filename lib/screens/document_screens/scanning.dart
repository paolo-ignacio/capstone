import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:legallyai/models/legal_analysis.dart';
import 'dart:io';
import 'package:legallyai/screens/document_screens/document_summarize_screen.dart';
import 'package:legallyai/screens/main_screen.dart';
import 'package:legallyai/services/upload_web_service.dart';

import 'package:path/path.dart' as path;
class OCRScannerScreen extends StatefulWidget {
  final String? uid;
  final String? chat_id;
  final File? imageFile;
  final PlatformFile? docFile;
  final String? language;

  OCRScannerScreen({
    Key? key,
    this.imageFile,
    this.docFile,
    this.language,
    this.uid,
    this.chat_id,
  }) : super(key: key);

  @override
  _OCRScannerScreenState createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<double> _iconOpacityAnimation;
  var response;
  String insights = '';
  String summary = '';
  String clauses = '';
  String risks = '';
  String recos = '';
  bool hasNavigated = false; // Prevent double navigation

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _iconOpacityAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start upload after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUpload();
    });
  }
Future<void> _startUpload() async {
  print("[SCREEN] Starting upload...");
  try {
    await sendFileToBackend(
      imageFile: widget.imageFile,
      docFile: widget.docFile,
      language: widget.language ?? "English",
      uid: widget.uid,
      chatId: widget.chat_id,
      onResponse: (result) async {
        print("[SCREEN] Received response: $result");
        if (!mounted || hasNavigated) return;

        try {
          // Parse the response
          Map<String, dynamic> responseData = json.decode(result);
          
          if (responseData['status'] == 'error') {
            hasNavigated = true;
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // Show error dialog with more details
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Color(0xFFE74C3C),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Scanning Failed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2A3C),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          responseData['message'] ?? 'Unknown error occurred',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD4AF37),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  actionsPadding: EdgeInsets.only(bottom: 16),
                  contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  insetPadding: EdgeInsets.symmetric(horizontal: 32),
                );
              },
            );
          } else {
            final analysis = LegalAnalysis.fromJson(responseData['analysis']);

            String extension = '';
            if (widget.imageFile != null) {
              extension = path.extension(widget.imageFile!.path).replaceFirst('.', '').toLowerCase();
            } else if (widget.docFile != null) {
              extension = widget.docFile!.extension?.toLowerCase() ?? '';
            }
            
            await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("document_chats").doc(widget.chat_id).update({
          
              'summary': analysis.summaryHighlights,
              'key_clauses': analysis.keyClauses,
              'actionable_insights': analysis.actionableInsights,
              'risks': analysis.potentialRisks,
              'recommendations': analysis.recommendations,
              'language': widget.language,
              'fileType': responseData['file_info']['file_type'],
              'assistant0': "What would you like to know about this document?",
              'extracted_text': responseData['extracted_text'],
              'file_title': responseData['file_info']['file_name'],
              'extension': extension,
             
            });

            hasNavigated = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentSummarizeScreen(
                  response: responseData,
                  uid: widget.uid,
                  chat_id: widget.chat_id,
                  language: widget.language,
                  analysis: analysis,
                ),
              ),
            );
            

            final storageRef = FirebaseStorage.instance
                .ref()
                .child('user_documents')
                .child(widget.uid!)
                .child(widget.chat_id!)
                .child(responseData['file_info']['file_name']);

            // Create metadata
            final metadata = SettableMetadata(
              contentType: responseData['file_info']['content_type'],
              customMetadata: {
                'uploadedBy': widget.uid!,
                'chatId': widget.chat_id!,
                'fileName': responseData['file_info']['file_name'],
                'timestamp': DateTime.now().toUtc().toString(),
                'fileType': responseData['file_info']['file_type'],
                'language': responseData['metadata']['language'],
                'assistant0': "What would you like to know about this document?",
                'extracted_text': responseData['extracted_text'],
                'file_title': responseData['file_info']['file_name'],
              },
            );

            // Upload the file
            if (widget.imageFile != null) {
              await storageRef.putFile(widget.imageFile!, metadata);
            } else if (widget.docFile != null) {
              final bytes = await File(widget.docFile!.path!).readAsBytes();
              await storageRef.putData(bytes, metadata);
            }

            // Get download URL
            final downloadUrl = await storageRef.getDownloadURL();
            // Parse the analysis data
            
            
            await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("document_chats").doc(widget.chat_id).update({
              'file_url': downloadUrl,
            });
            
          }
        } catch (e) {
          print('Error parsing response: $e');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Processing Error'),
                content: Text('Failed to process the document analysis. Please try again.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  } catch (e) {
    if (!mounted || hasNavigated) return;
    
    hasNavigated = true;
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Scanning Failed'),
          content: Text('An error occurred while scanning: ${e.toString()}'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double frameSize = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3C),
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "OCR Scanner",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Scanner animation
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: frameSize,
                  height: frameSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fading scanner icon
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _iconOpacityAnimation.value,
                            child: const Icon(
                              Icons.document_scanner,
                              color: Color.fromRGBO(212, 175, 55, 1),
                              size: 200,
                            ),
                          );
                        },
                      ),
                      // Scanning line
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _positionAnimation.value * (frameSize / 2.5 - 10)),
                            child: Container(
                              width: frameSize * 0.7,
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromRGBO(212, 175, 55, 1).withOpacity(0.0),
                                    const Color.fromRGBO(212, 175, 55, 1).withOpacity(0.5),
                                    Color.fromRGBO(212, 175, 55, 1).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  summary == ''
                      ? "Please take a moment while we are scanning your document..."
                      : "Processing complete!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              // if (backendResult == null)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 32.0),
              //     child: CircularProgressIndicator(),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
  String getContentType(File? imageFile, PlatformFile? docFile) {
  if (imageFile != null) {
    // Handle image files
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/jpeg'; // default for images
    }
  } else if (docFile != null) {
    // Handle document files
    final extension = docFile.extension?.toLowerCase() ?? '';
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/${extension.isEmpty ? 'octet-stream' : extension}';
    }
  }
  return 'application/octet-stream'; // default fallback
}
}
