import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customize_template_screen.dart';

class TemplateListScreen extends StatefulWidget {
  final String category;

  const TemplateListScreen({super.key, required this.category});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  bool _sortAlphabetically = false;

  Stream<QuerySnapshot> _getTemplatesStream() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    Query query = FirebaseFirestore.instance
        .collection('legal_templates')
        .where('category', isEqualTo: widget.category);

    if (isGuest) {
      query = query.where('access', isEqualTo: 'Guest');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        foregroundColor: Colors.white,
        title: _showSearch
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search templates...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : Text(widget.category[0].toUpperCase() +
                widget.category.substring(1)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: Icon(_sortAlphabetically ? Icons.sort_by_alpha : Icons.sort),
            onPressed: () {
              setState(() => _sortAlphabetically = !_sortAlphabetically);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTemplatesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No templates in this category."));
          }

          List<QueryDocumentSnapshot> filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

          if (_sortAlphabetically) {
            filteredDocs.sort((a, b) {
              final titleA = (a.data() as Map<String, dynamic>)['title'] ?? '';
              final titleB = (b.data() as Map<String, dynamic>)['title'] ?? '';
              return titleA
                  .toString()
                  .toLowerCase()
                  .compareTo(titleB.toString().toLowerCase());
            });
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final List<dynamic> content = data['content'];

              return Container(
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
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomizeTemplateScreen(
                          fileName: title,
                          content: content,
                          template: data,
                          docId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
