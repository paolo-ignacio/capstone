import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class CustomizeTemplateScreen extends StatefulWidget {
  final String fileName;
  final List<dynamic> content;
  final Map<String, dynamic> template;
  final String? docId;

  const CustomizeTemplateScreen({
    super.key,
    required this.fileName,
    required this.content,
    required this.template,
    this.docId,
  });

  @override
  State<CustomizeTemplateScreen> createState() =>
      _CustomizeTemplateScreenState();
}

class _CustomizeTemplateScreenState extends State<CustomizeTemplateScreen> {
  late quill.QuillController _quillController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    print(widget.docId);
    final delta = Delta.fromJson(widget.content);
    final doc = quill.Document.fromDelta(delta);
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void showDownloadSuccessModal(BuildContext context, String filePath) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Download Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your file has been saved to the Downloads folder.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      OpenFile.open(filePath);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final delta = _quillController.document.toDelta();
    final List<dynamic> contentJson = delta.toJson();

    setState(() => _isSaving = true);

    final recentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recent_templates');

    if (widget.docId != null) {
      // ✅ Update existing template
      await recentRef.doc(widget.docId).update({
        'title': widget.template['title'],
        'content': _quillController.document.toDelta().toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template updated successfully!')),
        );
      }

      setState(() => _isSaving = false);
      return;
    } else {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recent_templates')
            .doc();

        await docRef.set({
          'category': widget.template['category'],
          'content': contentJson,
          'createdAt': FieldValue.serverTimestamp(),
          'editedFrom': widget.template['category'],
          'title': widget.fileName,
          'uploadedBy': user.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template saved successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save template: $e')),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'preview':
        setState(() => _isEditing = false);
        break;
      case 'edit':
        setState(() => _isEditing = true);
        break;
      case 'save':
        _saveChanges();
        break;
      case 'pdf':
        _exportAsPdf();
        break;
      case 'docx':
        await exportDocx(_quillController.document.toDelta().toJson());
        break;
    }
  }

  String deltaToHtml(List<dynamic> deltaJson) {
    final deltaJson = _quillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
      deltaJson.cast<Map<String, dynamic>>(),
    );
    final html = converter.convert();

    return html;
  }

  Future<void> exportDocx(List<dynamic> deltaJson) async {
    final html = deltaToHtml(deltaJson);

    showLoadingDialog(context, 'Exporting DOCX file...');

    try {
      final response = await http.post(
        Uri.parse(
            'https://legallyai-flask-api.onrender.com/convert/html-to-docx'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'html': html}),
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final filePath = '${downloadsDir.path}/${widget.fileName}';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        showDownloadSuccessModal(context, filePath);
      } else {
        throw Exception('Export failed with status ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String fallbackDeltaToHtml(List<dynamic> delta) {
    final buffer = StringBuffer();

    for (final op in delta) {
      final insert = op['insert'];
      final attrs = op['attributes'] ?? {};

      if (insert is String) {
        var text = insert.replaceAll('\n', '<br>');
        if (attrs.containsKey('bold')) text = '<strong>$text</strong>';
        if (attrs.containsKey('italic')) text = '<em>$text</em>';
        if (attrs.containsKey('underline')) text = '<u>$text</u>';
        if (attrs.containsKey('align')) {
          final align = attrs['align'];
          text = '<p style="text-align:$align;">$text</p>';
        } else {
          text = '<p>$text</p>';
        }
        buffer.write(text);
      }
    }

    return buffer.toString();
  }

  Future<void> _exportAsPdf() async {
    final delta = _quillController.document.toDelta().toJson();
    final html = fallbackDeltaToHtml(delta);
    final url = 'https://legallyai-flask-api.onrender.com/convert/html-to-pdf';

    showLoadingDialog(context, 'Exporting PDF...');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: '{"html": ${jsonEncode(html)}}',
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final file = File(
            '${downloadsDir.path}/${widget.fileName.replaceAll('.docx', '')}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        showDownloadSuccessModal(context, file.path);
      } else {
        throw Exception('Failed to export PDF: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedTitle =
        widget.fileName.replaceAll('.docx', '').replaceAll('.pdf', '');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          cleanedTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1C2E),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_isEditing)
                const PopupMenuItem(
                    value: 'preview',
                    child:
                        Text('Preview', style: TextStyle(color: Colors.black))),
              if (_isEditing)
                const PopupMenuItem(
                    value: 'save',
                    child: Text('Save Changes',
                        style: TextStyle(color: Colors.black))),
              if (!_isEditing)
                const PopupMenuItem(
                    value: 'edit',
                    child: Text('Customize Template',
                        style: TextStyle(color: Colors.black))),
              const PopupMenuItem(
                  value: 'pdf',
                  child: Text('Download as PDF',
                      style: TextStyle(color: Colors.black))),
              const PopupMenuItem(
                  value: 'docx',
                  child: Text('Download as DOCX',
                      style: TextStyle(color: Colors.black))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    config: quill.QuillEditorConfig(
                      //readOnly: !_isEditing,
                      scrollable: true,
                      autoFocus: false,
                      expands: true,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (!_isEditing)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.black87),
                        label: const Text(
                          "Customize Template",
                          style: TextStyle(color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_isEditing)
            DraggableScrollableSheet(
              initialChildSize: 0.08,
              minChildSize: 0.08,
              maxChildSize: 0.4,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(125, 143, 143, 143),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: quill.QuillSimpleToolbar(
                      controller: _quillController,
                      config: quill.QuillSimpleToolbarConfig(
                        showAlignmentButtons: true,
                        toolbarSize: 28,
                        multiRowsDisplay: true,
                        toolbarIconAlignment: WrapAlignment.start,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_isSaving)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
