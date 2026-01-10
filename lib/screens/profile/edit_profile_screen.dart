import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_edit_provider.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  TextEditingController? _whatsAppController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userDetailsProvider).value;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    if (user?.role == 'business') {
      _whatsAppController = TextEditingController(
        text: user?.whatsAppNumber ?? '',
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _whatsAppController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ref.read(profileEditProvider.notifier).setImage(File(pickedFile.path));
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(profileEditProvider.notifier)
          .saveProfile(
            username: _usernameController.text,
            bio: _bioController.text,
            whatsAppNumber: _whatsAppController?.text,
          );
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditProvider);
    final user = ref.watch(userDetailsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (editState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.surfaceColor,
                      backgroundImage: _getProfileImage(user, editState),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              if (_whatsAppController != null)
                TextFormField(
                  controller: _whatsAppController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),

              if (editState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    editState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(dynamic user, ProfileEditState editState) {
    if (editState.selectedImage != null) {
      return FileImage(editState.selectedImage!);
    }
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      return NetworkImage(user.photoUrl!);
    }
    return const NetworkImage('https://via.placeholder.com/150');
  }
}
