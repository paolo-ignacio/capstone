import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:legallyai/models/legal_analysis.dart';
import 'package:legallyai/screens/document_screens/chatbot_screen.dart';

class SummaryScreen extends StatefulWidget {
  final String? uid;
  final String? chat_id;
  final String? language;

  SummaryScreen({
    super.key, 
    this.uid, 
    this.chat_id, 
    this.language
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final List<String> titles = [
    'Summary Highlights',
    'Key Clauses',
    'Actionable Insights',
    'Risks',
    'Recommendations'
  ];

  List<dynamic>? content;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  Future<void> fetchContent() async {
    try {
      if (widget.uid == null || widget.chat_id == null) {
        throw Exception('User ID or Chat ID is missing');
      }

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('document_chats')
          .doc(widget.chat_id)
          .get();

      if (!doc.exists) {
        throw Exception('Document does not exist');
      }

      final data = doc.data() as Map<String, dynamic>;
      
      setState(() {
        content = [
          data['summary'],
          data['key_clauses'],
          data['actionable_insights'],
          data['risks'],
          data['recommendations'],
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print('Error fetching content: $e');
    }
  }

  Widget _buildContent(dynamic content) {
    if (content is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(fontSize: 15, color: Colors.black54)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      );
    } else {
      return Text(
        content.toString(),
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black54,
          height: 1.6,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Document Summary",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: titles.length,
                itemBuilder: (_, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(12),
                        _buildContent(content![index]),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatbotScreen(
                    uid: widget.uid,
                    chat_id: widget.chat_id,
                    language: widget.language,
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error setting up chat: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error setting up chat: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: const Color(0xFFD4AF37),
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/icons/chatbot.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}