import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatThreadsDrawer extends StatelessWidget {
  final String uid;
  final String currentChatId;
  final Function(String) onChatSelected;

  const ChatThreadsDrawer({
    Key? key,
    required this.uid,
    required this.currentChatId,
    required this.onChatSelected,
  }) : super(key: key);
  
  String _getFileTitle(Map<String, dynamic> chatData) {
  // First try to get the file title
  String? fileTitle = chatData['file_title']?.toString();
  
  // If no file title is found, fallback to preview text
  if (fileTitle == null || fileTitle.trim().isEmpty) {
    fileTitle = _getPreviewText(chatData);
  }
  
  return fileTitle;
}

  bool _hasMessages(Map<String, dynamic> chatData) {
    // Check if the chat has any messages
    return chatData.keys.any((key) => 
      (key.startsWith('user') || key.startsWith('assistant')) && 
      chatData[key] != null && 
      chatData[key].toString().trim().isNotEmpty
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF2A2A3C),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select a conversation to view',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('document_chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  // Filter out empty chats except for the newest one
                  final allChats = snapshot.data!.docs;
                  final nonEmptyChats = allChats.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _hasMessages(data) || doc.id == allChats.first.id;
                  }).toList();

                  if (nonEmptyChats.isEmpty) {
                    return Center(child: Text('No conversations yet'));
                  }

                return ListView.builder(
                  itemCount: nonEmptyChats.length,
                  itemBuilder: (context, index) {
                    final chat = nonEmptyChats[index];
                    final chatData = chat.data() as Map<String, dynamic>;
                    final isSelected = chat.id == currentChatId;
                    final timestamp = chatData['timestamp'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? DateFormat('MMM d, y h:mm a').format(timestamp.toDate())
                        : 'No date';

                    // Get file title or preview text
                    String title = _getFileTitle(chatData);
                    String previewText = _getPreviewText(chatData);

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          child: Icon(
                            Icons.description_outlined,  // Changed to document icon
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          title,  // Using file title here
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewText,  // Show preview text as subtitle
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onTap: () {
                          Navigator.pop(context);
                          onChatSelected(chat.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

String _getPreviewText(Map<String, dynamic> chatData) {
  List<String> userKeys = [];
  List<String> assistantKeys = [];
  
  chatData.forEach((key, value) {
    if (key.startsWith('user')) {
      userKeys.add(key);
    } else if (key.startsWith('assistant')) {
      assistantKeys.add(key);
    }
  });

  if (userKeys.isEmpty && assistantKeys.isEmpty) {
    return '';
  }

  // Sort keys by their numerical index in descending order
  userKeys.sort((a, b) => int.parse(b.substring(4))
      .compareTo(int.parse(a.substring(4))));
  assistantKeys.sort((a, b) => int.parse(b.substring(9))
      .compareTo(int.parse(a.substring(9))));

  // Get the second latest message instead of the latest
  String previewMessage = '';
  if (userKeys.length > 1 || assistantKeys.length > 1) {
    if (userKeys.length >= 2) {
      // Get second latest user message
      previewMessage = chatData[userKeys[1]].toString();
    } else if (assistantKeys.length >= 2) {
      // Get second latest assistant message
      previewMessage = chatData[assistantKeys[1]].toString();
    } else if (userKeys.isNotEmpty) {
      // Fallback to latest user message if only one exists
      previewMessage = chatData[userKeys[0]].toString();
    } else if (assistantKeys.isNotEmpty) {
      // Fallback to latest assistant message if only one exists
      previewMessage = chatData[assistantKeys[0]].toString();
    }
  } else if (userKeys.isNotEmpty || assistantKeys.isNotEmpty) {
    // If there's only one message total, use it
    if (userKeys.isNotEmpty) {
      previewMessage = chatData[userKeys[0]].toString();
    } else {
      previewMessage = chatData[assistantKeys[0]].toString();
    }
  }

  // Clean the message
  previewMessage = previewMessage
      .replaceAll(RegExp(r'Current Date and Time.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r"Current User\'s Login:.*?\n", multiLine: true), '')
      .replaceAll(RegExp(r'Instructions for Response:.*?Response:', dotAll: true), '')
      .replaceAll(RegExp(r'Previous conversation:.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r'Context from knowledge base:.*?\n', multiLine: true), '')
      .replaceAll(RegExp(r'Current query:.*?\n', multiLine: true), '')
      .trim();

  // Truncate the preview text if it's too long
  return previewMessage.length > 50 
      ? '${previewMessage.substring(0, 50)}...' 
      : previewMessage;
}

}
