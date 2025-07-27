import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:legallyai/screens/profille_screen/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  const ProfileScreen({
    super.key,
    this.uid,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getUserStream() {
    return _firestore.collection('users').doc(widget.uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2A3C),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: StreamBuilder<DocumentSnapshot>(
            stream: getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Something went wrong: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final firstName = userData?['fname'] ?? 'Not provided';
              final lastName = userData?['lname'] ?? '';
              final email = userData?['email'] ?? 'Not provided';
              final profileImage = userData?['profileImage'];
              final fullName = '$firstName $lastName'.trim();

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: profileImage != null
                                ? NetworkImage(profileImage) as ImageProvider
                                : const AssetImage('assets/images/tempPic.png'),
                            backgroundColor: Colors.grey[200],
                            child: profileImage == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 17,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(
                                        uid: widget.uid,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 2.0, bottom: 2.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                   
                    const SizedBox(height: 30),

                    // Account info section
                    Text("Account Info",
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            profileInfoRow(Icons.person, "Full Name", fullName),
                            const Divider(color: Colors.black12),
                            profileInfoRow(Icons.email, "Email", email),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Settings section
                    Text("Settings",
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ProfileOptionRow(Icons.help, "Help"),
                            Divider(color: Colors.black12),
                            ProfileOptionRow(Icons.settings, "Settings"),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.logout, color: Colors.black),
                        label: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget profileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.black45, fontSize: 13)),
              Text(value,
                  style: const TextStyle(color: Colors.black87, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const ProfileOptionRow(this.icon, this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(color: Colors.black87, fontSize: 15)),
      ],
    );
  }
}