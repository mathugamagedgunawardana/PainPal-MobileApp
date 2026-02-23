import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/api_client.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../widgets/custom_widgets.dart';

class MriUploadScreen extends StatefulWidget {
  const MriUploadScreen({super.key});

  @override
  State<MriUploadScreen> createState() => _MriUploadScreenState();
}

class _MriUploadScreenState extends State<MriUploadScreen> {
  final _storage = SettingsStorage();
  final _database = PainpalDatabase.instance;
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _submitting = false;
  MriApiResponse? _response;

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 92);
    if (image == null) {
      return;
    }

    final docs = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}'
        '${path.extension(image.path)}';
    final saved = await File(image.path).copy(path.join(docs.path, fileName));

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImage = saved;
      _response = null;
    });
  }

  Future<void> _submit() async {
    final image = _selectedImage;
    if (image == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _response = null;
    });

    try {
      final baseUrl = await _storage.readBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('API base URL is missing. Set it in Settings.');
      }
      final patientId = await _storage.readPatientId();
      final api = ApiClient(baseUrl: baseUrl);
      final result = await api.submitMriScan(
        image: image,
        patientId: patientId,
      );

      final scan = MriScan(
        imagePath: image.path,
        prediction: result.prediction,
        confidence: result.confidence,
        timestamp: DateTime.now(),
        patientId: patientId,
      );
      await _database.insertMriScan(scan);

      if (!mounted) {
        return;
      }
      setState(() {
        _response = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImageSelected = _selectedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload MRI Scan'),
        elevation: 0,
        backgroundColor: const Color(0xFF171B22),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // HEADER
            SectionHeader(
              title: 'Upload Brain MRI Scan',
              subtitle: 'Help us analyze your brain imaging',
              illustrationIcon: Icons.image_search,
            ),
            const SizedBox(height: 24),

            // IMAGE PREVIEW
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isImageSelected
                      ? const Color(0xFFB6F36B)
                      : Colors.grey.shade700,
                  width: 2,
                ),
              ),
              height: 280,
              child: isImageSelected
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor:
                                Colors.black87.withValues(alpha: 0.7),
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _response = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported,
                            size: 64, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'No image selected',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a PNG or JPG MRI scan image',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // BUTTON ROW
            Row(
              children: [
                Expanded(
                  child: _CameraButton(
                    onPressed: _submitting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    label: 'Take Photo',
                    icon: Icons.photo_camera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GalleryButton(
                    onPressed: _submitting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    label: 'From Gallery',
                    icon: Icons.photo_library,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // INFO BOX
            if (isImageSelected)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB6F36B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB6F36B), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Color(0xFFB6F36B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ready to analyze',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your MRI scan will be analyzed using AI to detect potential abnormalities.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // SUBMIT BUTTON
            MigraineButton(
              onPressed: isImageSelected && !_submitting
                  ? () => _submit()
                  : null,
              label: 'Analyze MRI Scan',
              icon: Icons.analytics,
              isLoading: _submitting,
            ),
            const SizedBox(height: 16),

            // DISCLAIMER
            Container(
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade600, width: 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is an educational tool. Results are not medical diagnoses. Always consult with a healthcare professional.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RESULT DISPLAY
            if (_response != null) ...[
              const SizedBox(height: 24),
              ResultCard(
                title: 'Classification Result',
                content: _response!.prediction,
                icon: Icons.verified_user,
                backgroundColor: _response!.prediction == 'Tumor'
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              ResultCard(
                title: 'Confidence Score',
                content:
                    '${(_response!.confidence * 100).toStringAsFixed(1)}% confident',
                icon: Icons.equalizer,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const _CameraButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFB6F36B), Color(0xFF8FCC47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: Colors.black, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const _GalleryButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFFB6F36B)),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFFB6F36B), fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFB6F36B), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

