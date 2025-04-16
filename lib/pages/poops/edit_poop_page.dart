import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shpalman_app/models/poop_model.dart';
import '../../models/user_model.dart';
import '../../utils/auth_service.dart';
import '../../utils/database.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_uploader.dart';

class EditPoopPage extends StatefulWidget {
  static const String routeName = '/edit-poop';
  final PoopModel poop;

  const EditPoopPage({
    Key? key,
    required this.poop
  }) : super(key: key);

  @override
  _EditPoopPageState createState() => _EditPoopPageState();
}

class _EditPoopPageState extends State<EditPoopPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;
  String? _currentImageUrl;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.poop.description);
    _currentImageUrl = widget.poop.url.isNotEmpty ? widget.poop.url : null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _imageChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl;

    try {
      final cloudinaryService = CloudinaryService();
      final imageUrl = await cloudinaryService.uploadImage(_imageFile!);
      return imageUrl;
    } catch (e) {
      // Handle errors
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return _currentImageUrl;
    }
  }

  Future<void> _updatePoop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      String? imageUrl = _currentImageUrl;

      // Upload image if it was changed
      if (_imageChanged && _imageFile != null) {
        imageUrl = await _uploadImage();
      }

      await databaseService.updatePoop(
        widget.poop.id,
        imageUrl ?? '',
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Poop updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeCurrentImage() {
    setState(() {
      _currentImageUrl = null;
      _imageFile = null;
      _imageChanged = true;
    });
  }

  // Helper method to display image based on platform
  Widget _displaySelectedImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: _getImageWidget(),
          ),
          if (_imageFile != null || _currentImageUrl != null)
            IconButton(
              icon: const Icon(
                Icons.cancel,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                if (_imageFile != null) {
                  setState(() {
                    _imageFile = null;
                    _imageChanged = _currentImageUrl != null;
                  });
                } else if (_currentImageUrl != null) {
                  _removeCurrentImage();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _getImageWidget() {
    if (_imageFile != null) {
      return kIsWeb
          ? Image.network(
        _imageFile!.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      )
          : Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text('Failed to load image', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          );
        },
      );
    } else {
      return const Center(child: Text('No image selected'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Poop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit your poop record',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your poop description or image',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Pooped on top of the table in an Apple store',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              _displaySelectedImage(),
              const SizedBox(height: 16),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _updatePoop,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}