import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

Future<bool> isEmulator() async {
  if (!Platform.isAndroid) return false;
  
  try {
    final androidId = await File('/sys/class/android_usb/android0/iSerial').readAsString();
    return androidId.contains('emulator') || androidId.contains('generic');
  } catch (e) {
    return false;
  }
}

Future<void> sendFileToBackend({
  required File? imageFile,
  required PlatformFile? docFile,
  required String language,
  required String? uid,
  required String? chatId,
  required void Function(String response) onResponse,
  List<File>? additionalImages,
}) async {
  WebSocket? ws;
  
  try {
    // Validate files
    if (imageFile == null && docFile == null) {
      throw Exception("No file selected");
    }

    final bool runningOnEmulator = await isEmulator();
    final String serverIp = runningOnEmulator ? '10.0.2.2' : '192.168.42.186';
    
    print("[CLIENT] Connecting to WebSocket...");
    final url = Uri.parse("ws://10.0.2.2:8000/ws/upload");
    ws = await WebSocket.connect(url.toString());
    print("[CLIENT] Connected to WebSocket");

    // Create a list of all files to process
    List<File> allFiles = [];
    if (imageFile != null) allFiles.add(imageFile);
    if (additionalImages != null) allFiles.addAll(additionalImages);
    if (docFile != null && docFile.path != null) allFiles.add(File(docFile.path!));

    // Process each file
    for (int fileIndex = 0; fileIndex < allFiles.length; fileIndex++) {
      final currentFile = allFiles[fileIndex];
      final isImage = docFile == null || fileIndex > 0;
      
      // 1. Send metadata for current file
      final String filename = currentFile.path.split('/').last;
      final String extension = filename.split('.').last;
      
      final Map<String, dynamic> metadata = {
        'language': language,
        'uid': uid,
        'chat_id': chatId,
        'filename': filename,
        'filetype': isImage ? 'image' : 'document',
        'extension': extension,
        'total_files': allFiles.length,
        'file_index': fileIndex + 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      
      print("[CLIENT] Sending metadata for file ${fileIndex + 1}/${allFiles.length}: $metadata");
      ws.add(jsonEncode(metadata));
      await Future.delayed(Duration(milliseconds: 100));

      // 2. Read and send file bytes
      List<int> bytes = await currentFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception("File is empty: $filename");
      }

      print("[CLIENT] Starting transfer for file ${fileIndex + 1}/${allFiles.length}: ${bytes.length} bytes");
      const int chunkSize = 32 * 1024;
      int sentBytes = 0;
      
      for (int i = 0; i < bytes.length; i += chunkSize) {
        if (ws == null) break;
        
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        
        ws.add(chunk);
        
        sentBytes += chunk.length;
        print("[CLIENT] File ${fileIndex + 1} Progress: ${(sentBytes * 100 / bytes.length).toStringAsFixed(2)}%");
        
        await Future.delayed(Duration(milliseconds: 10));
      }
      
      print("[CLIENT] File ${fileIndex + 1} transfer complete");
      
      // Send end marker for this file
      ws.add("__END__");
      
      // Wait for server acknowledgment before sending next file
      if (fileIndex < allFiles.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    // 4. Listen for final response
    bool receivedResponse = false;
    ws.listen(
      (data) {
        print("[CLIENT] Received from server: $data");
        if (data is String) {
          try {
            final response = json.decode(data);
            receivedResponse = true;
            onResponse(data);
            ws?.close();
          } catch (e) {
            print("[CLIENT] Error parsing response: $e");
          }
        }
      },
      onError: (error) {
        print("[CLIENT] WebSocket error: $error");
        if (!receivedResponse) {
          onResponse(json.encode({
            "status": "error",
            "message": "Error: $error"
          }));
        }
      },
      onDone: () {
        print("[CLIENT] WebSocket connection closed");
        if (!receivedResponse) {
          onResponse(json.encode({
            "status": "error",
            "message": "Error: Connection closed without response"
          }));
        }
      },
    );

    // Add timeout
    await Future.delayed(Duration(seconds: 300)); // Increased timeout for multiple files
    if (!receivedResponse && ws != null) {
      print("[CLIENT] Upload timeout");
      onResponse(json.encode({
        "status": "error",
        "message": "Error: Upload timeout"
      }));
      ws.close();
    }

  } catch (e) {
    print("[CLIENT] Error: $e");
    onResponse(json.encode({
      "status": "error",
      "message": "Error: $e"
    }));
    ws?.close();
  }
}