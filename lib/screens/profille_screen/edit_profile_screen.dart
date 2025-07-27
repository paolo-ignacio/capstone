import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart'; 

class EditProfileScreen extends StatefulWidget {
  final String? uid;

  const EditProfileScreen({
    super.key,
    this.uid,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  
  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController emailCtrl;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty values - they'll be populated by StreamBuilder
    firstNameCtrl = TextEditingController();
    lastNameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedImage = File(result.files.first.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> uploadImage(String uid) async {
    if (selectedImage == null) return null;
    
    try {
      final ref = _storage.ref().child('user_pics/$uid');
      final uploadTask = ref.putFile(
        selectedImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2A3C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          
          // Update controllers only if they're empty or data changed
          if (firstNameCtrl.text.isEmpty) {
            firstNameCtrl.text = userData?['fname'] ?? '';
          }
          if (lastNameCtrl.text.isEmpty) {
            lastNameCtrl.text = userData?['lname'] ?? '';
          }
          if (emailCtrl.text.isEmpty) {
            emailCtrl.text = userData?['email'] ?? '';
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!) as ImageProvider
                                : userData?['profileImage'] != null
                                    ? NetworkImage(userData!['profileImage'])
                                    : const AssetImage('assets/images/tempPic.png'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 17,
                              child: IconButton(
                                onPressed: pickImage,
                                icon: const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        style: const TextStyle(color: Colors.black),
                        controller: firstNameCtrl,
                        decoration: _inputDecoration("First Name"),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Name can't be empty" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        style: const TextStyle(color: Colors.black),
                        controller: lastNameCtrl,
                        decoration: _inputDecoration("Last Name"),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Name can't be empty" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        readOnly: true,
                        style: const TextStyle(color: Colors.black),
                        controller: emailCtrl,
                        decoration: _inputDecoration("Email"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || value.isEmpty ? "Email can't be empty" : null,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                // Show single loading alert for all changes
                                QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.loading,
                                  title: 'Saving Changes',
                                  text: 'Please wait while we update your profile',
                                  barrierDismissible: false,
                                );

                                String? imageUrl;
                                // Upload image if selected
                                if (selectedImage != null) {
                                  imageUrl = await uploadImage(widget.uid!);
                                  
                                  if (imageUrl == null) {
                                    // Dismiss loading alert if image upload failed
                                    Navigator.pop(context);
                                    
                                    await QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.error,
                                      title: 'Upload Failed',
                                      text: 'Failed to upload image. Please try again.',
                                      confirmBtnText: 'OK',
                                      confirmBtnColor: const Color(0xFFD4AF37),
                                    );
                                    return;
                                  }
                                }

                                // Update user data
                                final updateData = {
                                  'fname': firstNameCtrl.text,
                                  'lname': lastNameCtrl.text,
                                };

                                // Add image URL to update data if available
                                if (imageUrl != null) {
                                  updateData['profileImage'] = imageUrl;
                                }

                                await _firestore
                                    .collection('users')
                                    .doc(widget.uid)
                                    .update(updateData);

                                // Dismiss the loading alert
                                Navigator.pop(context);

                                // Show success alert
                                await QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.success,
                                  title: 'Success',
                                  text: 'Profile updated successfully',
                                  confirmBtnText: 'OK',
                                  confirmBtnColor: const Color(0xFFD4AF37),
                                );

                                // Navigate back
                                Navigator.pop(context);
                              } catch (e) {
                                // Dismiss loading alert if showing
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }

                                // Show error alert
                                await QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.error,
                                  title: 'Error',
                                  text: 'Failed to update profile: $e',
                                  confirmBtnText: 'OK',
                                  confirmBtnColor: const Color(0xFFD4AF37),
                                );
                              }
                            }
                          },
                          child: const Text("Save Changes"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
    );
  }
}