import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:legallyai/screens/template_screens/template_list_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  bool _sortAlphabetically = true;

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
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text("Categories"),
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
        stream: FirebaseFirestore.instance
            .collection('legal_templates')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final categorySet = <String>{};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('category')) {
              categorySet.add(data['category']);
            }
          }

          var categories = categorySet.toList();

          if (_sortAlphabetically) {
            categories
                .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          }

          final filtered = categories.where((cat) {
            return cat.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No categories found."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (_, index) {
              final category = filtered[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.folder, color: Color(0xFFD4AF37)),
                  title: Text(
                    category[0].toUpperCase() + category.substring(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TemplateListScreen(category: category),
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
