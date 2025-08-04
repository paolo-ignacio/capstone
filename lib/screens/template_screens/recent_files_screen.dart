import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customize_template_screen.dart';
import 'package:gap/gap.dart';

class RecentFileScreen extends StatefulWidget {
  const RecentFileScreen({super.key});

  @override
  State<RecentFileScreen> createState() => _RecentFileScreenState();
}

class _RecentFileScreenState extends State<RecentFileScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  bool _sortAlphabetically = false;
  bool _sortNewestFirst = true;

  DateTime? _startDate;
  DateTime? _endDate;

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 2) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inHours >= 1) return '${difference.inHours} hours ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes} mins ago';
    return 'Just now';
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _sortAlphabetically = false;
      _sortNewestFirst = true;
    });
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
                  hintText: 'Search recent files...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text("All Recent Files"),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) async {
              switch (value) {
                case 'alphabetical':
                  setState(() => _sortAlphabetically = !_sortAlphabetically);
                  break;
                case 'sort_order':
                  setState(() => _sortNewestFirst = !_sortNewestFirst);
                  break;
                case 'clear':
                  _clearFilters();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'alphabetical',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(_sortAlphabetically
                        ? 'Unsort Alphabetically'
                        : 'Sort Alphabetically'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_order',
                child: Row(
                  children: [
                    Icon(
                        _sortNewestFirst
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(
                        _sortNewestFirst ? 'Sort by Oldest' : 'Sort by Newest'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_range',
                child: Row(
                  children: const [
                    Icon(Icons.date_range, color: Color(0xFFD4AF37)),
                    SizedBox(width: 8),
                    Text('Filter by Date Range'),
                  ],
                ),
              ),
              if (_startDate != null || _endDate != null)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Clear Filters'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('recent_templates')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recent files found."));
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

          // Filter by search query
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

          // Filter by date range
          if (_startDate != null && _endDate != null) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final date = ts?.toDate();
              return date != null &&
                  date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                  date.isBefore(_endDate!.add(const Duration(days: 1)));
            }).toList();
          }

          // Sort
          if (_sortAlphabetically) {
            docs.sort((a, b) {
              final titleA = (a.data() as Map<String, dynamic>)['title'] ?? '';
              final titleB = (b.data() as Map<String, dynamic>)['title'] ?? '';
              return titleA
                  .toString()
                  .toLowerCase()
                  .compareTo(titleB.toString().toLowerCase());
            });
          } else {
            docs.sort((a, b) {
              final dateA =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final dateB =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              return _sortNewestFirst
                  ? (dateB?.toDate() ?? DateTime(0))
                      .compareTo(dateA?.toDate() ?? DateTime(0))
                  : (dateA?.toDate() ?? DateTime(0))
                      .compareTo(dateB?.toDate() ?? DateTime(0));
            });
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled';
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? timeAgo(createdAt.toDate())
                  : 'Unknown date';

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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(122, 0, 0, 0),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomizeTemplateScreen(
                          fileName: title,
                          content: data['content'],
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
