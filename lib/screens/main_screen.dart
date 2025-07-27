import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; 
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:legallyai/screens/chatbot_screens/main_chatbot.dart';

import 'package:legallyai/screens/document_screens/scanning.dart';
import 'package:legallyai/screens/document_screens/summary.dart';
import 'package:legallyai/screens/login_screen.dart';
import 'package:legallyai/screens/profille_screen/profile_main.dart';
import 'package:legallyai/screens/template_screens/templates.dart';
import 'package:legallyai/screens/modal_bottom_sheets.dart';
class MainScreen extends StatefulWidget {

  final String? uid;
const MainScreen({super.key,  this.uid});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> texts = ['Chatbot', 'Review', 'Templates'];
  

  final List<String> textFiles = [
    'Business Contract',
    'Employment Contract',
    'Lease Agreement',
  ];

  final List<Color> colorsDocs = [Color(0xFFD4AF37), Color(0xFF7E57C2), Color(0xFF4CAF50)];
  final List<Color?> colorsbf = [Color(0xFF3B3B4F), Color(0xFF3E345E), Color(0xFF2C4F3C)];

  final List<Widget> linksScreen = [ChatbotScreen(), OCRScannerScreen(), TemplatesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient background container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1C1C2E), Color(0xFF2A2A3C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(15),
                  _buildAppBar(context),
                  const Gap(24),
                  const Gap(10),
                  _buildQuickTools(context),
                  
                ],
              ),
            ),
            const Gap(25),
            _sectionTitle("Recent Files"),
            
            _buildRecentFiles(),
            const Gap(30),
            _sectionTitle("Recent Chats"),
            const Gap(20),
            _buildRecentChats(),
            const Gap(30),
            _sectionTitle("Sample Templates"),
           
            _buildSampleTemplates(),
            const Gap(30),
          ],
        ),
      ),
          floatingActionButton: FloatingActionButton(
              onPressed: () async{
                       var chat_id = await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("document_chats").add({
                 'timestamp': FieldValue.serverTimestamp(),
              });
                showImageOrFileBottomSheet(context, widget.uid!, chat_id.id);
        },
        backgroundColor: const Color(0xFFD4AF37),
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/icons/review.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        Row(
          children: [
            Text(
              "Legally",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            Text(
              "AI",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(
              uid: widget.uid,)));
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C1C2E),
                  fontSize: 24
                ),
                
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 50,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    ),
  );
}
Widget _buildRecentFiles() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
      .collection('users')
      .doc(widget.uid)
      .collection('document_chats')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error loading files'));
      }
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      // Filter for docs with both file_title and fileType
      final docs = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final hasTitle = data['file_title'] != null && data['file_title'].toString().isNotEmpty;
        final hasExtension = data['extension'] != null && data['extension'].toString().isNotEmpty;
        final hasType = data['fileType'] != null && data['fileType'].toString().isNotEmpty;
        final language = data['language'] != null && data['language'].toString().isNotEmpty;
        return hasTitle && hasExtension && hasType && language;
      }).toList();

      if (docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/emptyDocs.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
                const Gap(12),
                Text(
                  'No summarized documents yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                
              ],
            ),
          ),
        );
      }

      // Show only the top 4
      final displayDocs = docs.length > 4 ? docs.sublist(0,4) : docs;

      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24,),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayDocs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, index) {
            final doc = displayDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fileTitle = data['file_title'];
            final language = data['language'] ?? 'English';
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
              ? DateFormat('MM-dd-yy').format(timestamp.toDate())
              : 'Unknown Date';
            final extension = data['extension']?.toString().toLowerCase() ?? '';
            String imageAsset;
            if (['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'].contains(extension)) {
              imageAsset = 'assets/images/docuImage.png';
            } else if (['doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension)) {
              imageAsset = 'assets/images/docuDocs.png';
            } else if (extension == 'pdf') {
              imageAsset = 'assets/images/docs.png';
            } else {
              imageAsset = 'assets/images/docs.png'; // fallback
            }
            return InkWell(
              onTap: () => 
              setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryScreen(
                      uid: widget.uid,
                      chat_id: doc.id,
                      language: language,
                    ),
                  ));
              }
              ),
              
              
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        imageAsset,
                        height: 100,
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileTitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            maxLines: 1,
                          ),
                          Text(
                            "Updated at: $formattedDate",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
bool _hasMessages(Map<String, dynamic> chatData) {
  // Check if the chat has any messages
  return chatData.keys.any((key) => 
    (key.startsWith('user') || key.startsWith('assistant')) && 
    chatData[key] != null && 
    chatData[key].toString().trim().isNotEmpty
  );
}
Widget _buildRecentChats() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error loading chats',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        );
      }

      if (!snapshot.hasData) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      final nonEmptyChats = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _hasMessages(data);
      }).toList();

      if (nonEmptyChats.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/emptyChats.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
                const Gap(12),
                Text(
                  'No recent chats',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: nonEmptyChats.length > 5 ? 5 : nonEmptyChats.length,
        itemBuilder: (context, index) {
          final chat = nonEmptyChats[index];
          final chatData = chat.data() as Map<String, dynamic>;
          final chatId = chat.id; // <-- get the chat id
          final timestamp = chatData['timestamp'] as Timestamp?;
          final formattedDate = timestamp != null
              ? DateFormat('MMM d • h:mm a').format(timestamp.toDate())
              : 'No date';

          String previewText = _getPreviewText(chatData);
          if (previewText.isEmpty) {
            previewText = 'New Chat';
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: 12,
              left: 24,
              right: 24,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatbotScreen(
                      uid: widget.uid,
                      chat_id: chatId, // pass the chat id here
                    ),
                  ),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    // Leading icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/chatbot.png',
                          width: 24,
                          height: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Trailing icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
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

  userKeys.sort((a, b) => int.parse(b.substring(4))
      .compareTo(int.parse(a.substring(4))));
  assistantKeys.sort((a, b) => int.parse(b.substring(9))
      .compareTo(int.parse(a.substring(9))));

  String previewMessage = '';
  if (userKeys.length > 1 || assistantKeys.length > 1) {
    if (userKeys.length >= 2) {
      previewMessage = chatData[userKeys[1]].toString();
    } else if (assistantKeys.length >= 2) {
      previewMessage = chatData[assistantKeys[1]].toString();
    } else if (userKeys.isNotEmpty) {
      previewMessage = chatData[userKeys[0]].toString();
    } else if (assistantKeys.isNotEmpty) {
      previewMessage = chatData[assistantKeys[0]].toString();
    }
  } else if (userKeys.isNotEmpty || assistantKeys.isNotEmpty) {
    if (userKeys.isNotEmpty) {
      previewMessage = chatData[userKeys[0]].toString();
    } else {
      previewMessage = chatData[assistantKeys[0]].toString();
    }
  }

 

  return previewMessage.length > 50 
      ? '${previewMessage.substring(0, 50)}...' 
      : previewMessage;
}

  Widget _buildSampleTemplates() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: textFiles.length,
        itemBuilder: (_, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorsbf[index],
                child: Icon(Icons.file_copy, color: colorsDocs[index]),
              ),
              title: Text(
                textFiles[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black38, size: 18),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    child: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading user data'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final firstName = userData?['fname'] ?? '';
        final lastName = userData?['lname'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final profileImage = userData?['profileImage'];

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage) as ImageProvider
                        : const AssetImage('assets/images/tempPic.png'),
                    backgroundColor: Colors.grey[200],
                    child: profileImage == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 40)
                        : null,
                  ),
                  const Gap(10),
                  Text(
                    fullName.isNotEmpty ? fullName : 'User',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                 
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: Text('Home',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.reviews, color: Colors.white),
              title: Text('Chatbot',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner, color: Colors.white),
              title: Text('Review',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_copy_rounded, color: Colors.white),
              title: Text('Library',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.white),
              title: Text('Help',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.white),
              title: Text('Logout',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => LoginScreen()));
              },
            ),
          ],
        );
      },
    ),
  );
}
  Widget _buildQuickTools(BuildContext context) {
  final List<String> assetImages = [
    'assets/icons/chatbot.png',
    'assets/icons/review.png',
    'assets/icons/templates.png',
  ];

  final List<String> texts = ['Chatbot', 'Review', 'Templates'];
  final List<Color> iconBgColors = [
    Color(0xFFD4AF37), // gold
    Color(0xFFD4AF37), // gold (or another accent)
    Color(0xFFD4AF37), // gold (or another accent)
  ];

  return Container(
    height: 156,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF282640), // dark card color
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return _CircleNavButton(
          imagePath: assetImages[index],
          label: texts[index],
          iconBgColor: iconBgColors[index],
          onTap: () async {
            if(index == 0){
              var chat_id = await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("chats").add({
                 'timestamp': FieldValue.serverTimestamp(),
              });
              
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatbotScreen(uid: widget.uid, chat_id: chat_id.id)),
              );
            } else if(index == 1){
              var chat_id = await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("document_chats").add({
                 'timestamp': FieldValue.serverTimestamp(),
              });
              showImageOrFileBottomSheet(context, widget.uid!, chat_id.id);
            } else if(index == 2){
              // var chat_id = await FirebaseFirestore.instance.collection("users").doc(widget.uid).collection("chats").add({
              //    'timestamp': FieldValue.serverTimestamp(),
              // });
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => TemplatesScreen(uid: widget.uid, chat_id: chat_id.id,)),
              // );
            }
          },
        );
      }),
    ),
  );

}


}

class _CircleNavButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _CircleNavButton({
    required this.imagePath,
    required this.label,
    required this.iconBgColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFF413C5A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                color: iconBgColor, // This will tint the image with the specified color
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}