import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:gap/gap.dart';
import 'package:legallyai/screens/template_screens/category_list_screen.dart';
import 'package:legallyai/screens/template_screens/customize_template_screen.dart';
import 'package:legallyai/screens/template_screens/recent_files_screen.dart';
import 'package:legallyai/screens/template_screens/template_list_screen.dart';
import 'package:legallyai/screens/template_screens/template_preview_screen.dart';

class TemplatesScreen extends StatefulWidget {
  TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<Map<String, dynamic>> recentTemplates = [];
  bool isLoading = true;
  final List<String> categories = ['nda', 'employment', 'contract', 'others'];
  bool _initialized = false;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchRecentTemplates();
    print("uid: ${FirebaseAuth.instance.currentUser?.uid}");
  }

  final List<Color> colorsDocs = [
    Color(0xFF1565C0),
    Color(0xFF7B1FA2),
    Color(0xFF2E7D32)
  ];

  Future<void> fetchRecentTemplates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_templates')
          .orderBy('createdAt', descending: true)
          .get();

      final data = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        recentTemplates = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching recent templates: $e');
      setState(() => isLoading = false);
    }
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 2) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inHours >= 1) return '${difference.inHours} hours ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes} mins ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Template Library",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (FirebaseAuth.instance.currentUser?.isAnonymous ?? true)
                    ? SizedBox.shrink()
                    : buildRecentTemplates(),
                const Gap(10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Templates",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF1C1C2E))),
                    const SizedBox(height: 4),
                    Container(height: 2, width: 40, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('legal_templates')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final user = FirebaseAuth.instance.currentUser;
                        final isGuest = user?.isAnonymous ?? true;

                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final allTemplates = snapshot.data!.docs;

                        final accessibleTemplates = allTemplates.where((doc) {
                          final access = doc['access']?.toString() ?? 'Guest';
                          return !isGuest || access == 'Guest';
                        }).toList();

                        final categories = accessibleTemplates
                            .map((doc) =>
                                doc['category']?.toString() ?? 'Uncategorized')
                            .toSet()
                            .toList()
                          ..sort();

                        if (!_initialized &&
                            selectedCategory == null &&
                            categories.isNotEmpty) {
                          selectedCategory = categories.first;
                          _initialized = true;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildCategoryChips(categories),
                            const SizedBox(height: 16),
                            buildTemplateGrid(accessibleTemplates),
                          ],
                        );
                      },
                    )
                  ],
                ),
                const Gap(12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRecentTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Files",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF1C1C2E))),
        const SizedBox(height: 4),
        Container(height: 2, width: 40, color: Color(0xFFD4AF37)),
        const Gap(12),
        SizedBox(
          height: 130,
          child: recentTemplates.isEmpty
              ? Center(
                  child: Text(
                    "No recent templates found.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('recent_templates')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    print(FirebaseAuth.instance.currentUser?.uid);

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No recent templates found.",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      );
                    }

                    final recentTemplates = snapshot.data!.docs;

                    return SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentTemplates.length > 5
                              ? 6 // 5 + 1 for "See All"
                              : recentTemplates.length,
                          itemBuilder: (_, index) {
                            if (index == 5 && recentTemplates.length > 5) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => RecentFileScreen()),
                                  );
                                },
                                child: Container(
                                  width: 117,
                                  height: 107,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 82, 82, 125),
                                        const Color(0xFF3A3A59)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.file_copy_rounded,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "See All",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final doc = recentTemplates[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final cleanedTitle = data['title']
                                .replaceAll(RegExp(r'\.(docx|pdf)$'), '');
                            final title = cleanedTitle ?? 'Untitled';
                            final createdAt = data['createdAt'] as Timestamp?;
                            final dateStr = createdAt != null
                                ? timeAgo(createdAt.toDate())
                                : 'Unknown date';

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomizeTemplateScreen(
                                      fileName: title,
                                      content: data['content'] ?? [],
                                      template: data,
                                      docId: doc.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 117,
                                height: 107,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Gap(8),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0),
                                          child: quill.QuillEditor.basic(
                                            controller: quill.QuillController(
                                              document: quill.Document.fromJson(
                                                  data['content'] ?? []),
                                              selection:
                                                  const TextSelection.collapsed(
                                                      offset: 0),
                                            ),
                                            config: quill.QuillEditorConfig(
                                              //readOnly: true,
                                              expands: true,
                                              padding: EdgeInsets.zero,
                                              showCursor: false,
                                              scrollable: true,
                                              placeholder: '',
                                              customStyles: quill.DefaultStyles(
                                                paragraph:
                                                    quill.DefaultTextBlockStyle(
                                                  const TextStyle(
                                                      fontSize: 3,
                                                      color: Colors.black87),
                                                  const quill.HorizontalSpacing(
                                                      0, 0),
                                                  const quill.VerticalSpacing(
                                                      0, 0),
                                                  const quill.VerticalSpacing(
                                                      0, 0),
                                                  null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C1C2E),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ));
                  },
                ),
        ),
        const Gap(10),
        const Divider(thickness: 1.5, color: Color.fromRGBO(28, 28, 46, 0.1)),
      ],
    );
  }

  String extractPreviewText(List<dynamic> deltaContent, {int maxChars = 150}) {
    final buffer = StringBuffer();

    for (var op in deltaContent) {
      if (op is Map<String, dynamic> && op.containsKey('insert')) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert.replaceAll('\n', ' ')); // flatten newlines
          if (buffer.length >= maxChars) break;
        }
      }
    }

    // Trim and limit to maxChars
    final preview = buffer.toString().trim();
    return preview.length > maxChars
        ? preview.substring(0, maxChars).trimRight() + '...'
        : preview;
  }

  Widget buildTemplateGrid(List<QueryDocumentSnapshot> templates) {
    final user = FirebaseAuth.instance.currentUser;

    final bool isGuest = user?.isAnonymous ?? true;

    final accessibleTemplates = templates.where((doc) {
      final access = doc['access']?.toString() ?? 'Guest';
      if (isGuest) {
        return access == 'Guest';
      } else {
        return true; // Allow all templates for signed-in users
      }
    }).toList();

    final filteredTemplates =
        selectedCategory != null && selectedCategory != 'Others'
            ? accessibleTemplates
                .where((doc) => doc['category'] == selectedCategory)
                .toList()
            : accessibleTemplates;

    final displayTemplates = filteredTemplates.length > 9
        ? filteredTemplates.take(9).toList()
        : filteredTemplates;

    final totalItems =
        displayTemplates.length + 1; // Always add one for View All

    if (filteredTemplates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("No templates found.")),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalItems,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4.3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index == displayTemplates.length) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateListScreen(
                    category: selectedCategory!,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 82, 82, 125),
                    const Color(0xFF3A3A59)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.grid_view,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "View All",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final doc = displayTemplates[index];
        final data = doc.data() as Map<String, dynamic>;
        final rawTitle = data['title'] ?? 'Untitled';
        final cleanedTitle = rawTitle.replaceAll(RegExp(r'\.(docx|pdf)$'), '');
        final List<dynamic> content = data['content'] ?? [];
        final category = data['category'] ?? 'Uncategorized';

        final quillController = quill.QuillController(
          document: quill.Document.fromDelta(Delta.fromJson(content)),
          selection: const TextSelection.collapsed(offset: 0),
        );

        return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomizeTemplateScreen(
                    fileName: rawTitle,
                    content: content,
                    template: data,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: quill.QuillEditor.basic(
                        controller: quillController,
                        config: quill.QuillEditorConfig(
                          expands: true,
                          padding: EdgeInsets.zero,
                          showCursor: false,
                          scrollable: true,
                          placeholder: '',
                          //readOnly: true,
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              const TextStyle(
                                  fontSize: 4, color: Colors.black87),
                              const quill.HorizontalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: cleanedTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanedTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category[0].toUpperCase() + category.substring(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }

  List<String> extractAvailableCategories(
      List<QueryDocumentSnapshot> templates) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;

    // Only include templates that match access
    final accessibleTemplates = templates.where((doc) {
      final access = doc['access']?.toString() ?? 'Guest';
      return !isGuest || access == 'Guest';
    });

    // Extract categories from accessible templates
    final Set<String> availableCategories = accessibleTemplates
        .map((doc) => doc['category']?.toString() ?? 'Uncategorized')
        .toSet();

    return availableCategories.toList();
  }

  Widget buildCategoryChips(List<String> categories) {
    final topCategories = categories.take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...topCategories.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat[0].toUpperCase() + cat.substring(1)),
                  selected: selectedCategory == cat,
                  onSelected: (_) {
                    setState(() => selectedCategory = cat);
                  },
                  selectedColor: const Color(0xFFD4AF37),
                  labelStyle: TextStyle(
                    color:
                        selectedCategory == cat ? Colors.white : Colors.white,
                  ),
                  backgroundColor: const Color(0xFF5B5B6B),
                ),
              )),
          if (topCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: const Text(
                  "Others",
                  style: TextStyle(color: Colors.white),
                ),
                selected: selectedCategory == "Others",
                onSelected: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryListScreen(),
                    ),
                  );
                },
                selectedColor: const Color(0xFFD4AF37),
                labelStyle: const TextStyle(color: Colors.black),
                backgroundColor: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}
