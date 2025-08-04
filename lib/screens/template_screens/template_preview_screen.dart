// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_quill/quill_delta.dart';
// import 'customize_template_screen.dart'; // Import your customization screen

// class TemplatePreviewScreen extends StatelessWidget {
//   final String fileName;
//   final List<dynamic> content;

//   const TemplatePreviewScreen({
//     super.key,
//     required this.fileName,
//     required this.content,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final delta = Delta.fromJson(content);
//     final doc = quill.Document.fromDelta(delta);
//     final controller = quill.QuillController(
//       document: doc,
//       selection: const TextSelection.collapsed(offset: 0),
//     );
//     final quillController = quill.QuillController.basic();
//     final focusNode = FocusNode();
//     final scrollController = ScrollController();
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(fileName),
//         backgroundColor: const Color(0xFF2A2A3C),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               color: Colors.white,
//               padding: const EdgeInsets.all(16),
//               child: quill.QuillEditor(
//                 controller: controller,
//                 focusNode: focusNode,
//                 scrollController: scrollController,
//                 config: const quill.QuillEditorConfig(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.edit_document),
//                 label: const Text("Customize Template"),
//                 onPressed: () {
//                   // Navigator.push(
//                   //   context,
//                   //   MaterialPageRoute(
//                   //     builder: (_) => CustomizeTemplateScreen(
//                   //       fileName: fileName,
//                   //       content: content,
//                   //     ),
//                   //   ),
//                   // );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFD4AF37),
//                   foregroundColor: const Color(0xFF1C1C2E),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   textStyle: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
