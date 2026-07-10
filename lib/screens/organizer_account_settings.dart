import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_avatar.dart';

class OrganizerAccountSettings extends StatefulWidget {
  const OrganizerAccountSettings({super.key});

  @override
  State<OrganizerAccountSettings> createState() => _OrganizerAccountSettingsState();
}
class _OrganizerAccountSettingsState extends State<OrganizerAccountSettings> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _orgTypeController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<AuthProvider>().userProfile;
    _nameController = TextEditingController(text: userProfile?.name ?? '');
    _emailController = TextEditingController(text: userProfile?.email ?? '');
    
    String phone = userProfile?.phone ?? '';
    if (phone.startsWith('+601')) {
      phone = phone.substring(4).trim();
    }
    _phoneController = TextEditingController(text: phone);
    _orgTypeController = TextEditingController(text: userProfile?.major ?? '');
    _bioController = TextEditingController(text: userProfile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgTypeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
    );
    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
        maxWidth: 200,
        maxHeight: 200,
        compressQuality: 30,
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Account Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _showChangeProfilePictureModal(context),
                child: Stack(
                  children: [
                    _imageFile != null
                        ? CircleAvatar(
                            radius: 100,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            backgroundImage: FileImage(_imageFile!),
                          )
                        : DynamicAvatar(
                            name: context.read<AuthProvider>().userProfile?.name,
                            avatarUrl: context.read<AuthProvider>().userProfile?.avatarUrl,
                            radius: 100,
                            fontSize: 72,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                        ),
                        child: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.onSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: 'Organization Name',
              controller: _nameController,
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              prefixText: '+601',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Organization Bio',
              controller: _bioController,
              icon: Icons.info_outline,
              maxLines: 3,
              maxLength: 150,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
              readOnly: true, // Email usually cannot be changed directly here
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Organization Type',
              controller: _orgTypeController,
              hintText: 'e.g Student Club, Faculty',
              icon: Icons.category_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  final authProvider = context.read<AuthProvider>();
                  final uid = authProvider.firebaseUser?.uid;
                  if (uid != null) {
                    String rawPhone = _phoneController.text.trim();
                    String phone = rawPhone.isNotEmpty ? '+601$rawPhone' : '';
                    
                    String? avatarUrl;
                    if (_imageFile != null) {
                      try {
                        final bytes = await _imageFile!.readAsBytes();
                        final base64String = base64Encode(bytes);
                        avatarUrl = 'data:image/jpeg;base64,$base64String';
                      } catch (e) {
                        debugPrint('Failed to convert avatar: $e');
                      }
                    }

                    final updateData = <String, dynamic>{
                      'name': _nameController.text.trim(),
                      'phone': phone,
                      'major': _orgTypeController.text.trim(),
                      'bio': _bioController.text.trim(),
                    };
                    
                    if (avatarUrl != null) {
                      updateData['avatarUrl'] = avatarUrl;
                    }

                    await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
                    // Refresh profile
                    await authProvider.reloadProfile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    required IconData icon,
    bool readOnly = false,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            prefixText: prefixText,
            prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            filled: true,
            fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangeProfilePictureModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                title: Text('Remove current picture', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
