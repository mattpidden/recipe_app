import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class _OcrLine {
  final String text;
  final double height;
  final double area;
  final double top;

  _OcrLine({
    required this.text,
    required this.height,
    required this.area,
    required this.top,
  });
}

class AddCookbookManuallyPage extends StatefulWidget {
  const AddCookbookManuallyPage({super.key});

  @override
  State<AddCookbookManuallyPage> createState() =>
      _AddCookbookManuallyPageState();
}

class _AddCookbookManuallyPageState extends State<AddCookbookManuallyPage> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _description = TextEditingController();

  final _picker = ImagePicker();
  XFile? _pickedImage;

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1500,
    );
    if (img == null) return;

    setState(() => _pickedImage = img);

    // Try autofill from cover text
    await _autoFillFromCover(img);
  }

  Future<void> _autoFillFromCover(XFile image) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final input = InputImage.fromFilePath(image.path);
      final result = await recognizer.processImage(input);

      // Flatten lines with a "size" score
      final lines = <_OcrLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;

          final bb = line.boundingBox;
          final height = bb.height;
          final width = bb.width;
          final area = height * width;

          lines.add(
            _OcrLine(text: text, height: height, area: area, top: bb.top),
          );
        }
      }

      if (lines.isEmpty) return;

      // Title: biggest text (by height/area), prefer lines near the top-ish
      lines.sort((a, b) => b.area.compareTo(a.area));
      final biggest = lines.take(8).toList();

      // Pick best title candidate:
      // - big
      // - not super long sentence
      // - not "by ..."
      _OcrLine? titleLine;
      for (final l in biggest) {
        final lower = l.text.toLowerCase();
        final words = l.text
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        if (lower.startsWith('by ')) continue;
        if (words > 10) continue;
        titleLine = l;
        break;
      }
      titleLine ??= biggest.first;

      // Author: look for "by X" first
      _OcrLine? authorLine;
      for (final l in lines) {
        final lower = l.text.toLowerCase();
        if (lower.startsWith('by ') && l.text.length <= 40) {
          authorLine = l;
          break;
        }
      }

      // If no "by", choose a smaller line near bottom, not same as title
      if (authorLine == null) {
        // Sort by vertical position (top -> bottom)
        final byPos = [...lines]..sort((a, b) => a.top.compareTo(b.top));
        final bottomChunk = byPos.skip((byPos.length * 0.6).floor()).toList();

        // among bottom chunk, pick a line that isn't title and isn't too long
        bottomChunk.sort(
          (a, b) => a.height.compareTo(b.height),
        ); // smaller first
        for (final l in bottomChunk.reversed) {
          if (l.text == titleLine!.text) continue;
          final words = l.text
              .split(RegExp(r'\s+'))
              .where((w) => w.isNotEmpty)
              .length;
          if (words >= 2 && words <= 6 && l.text.length <= 35) {
            authorLine = l;
            break;
          }
        }
      }

      // Description: pick the longest "sentence-like" line (more words), excluding title/author
      _OcrLine? descLine;
      final excluded = <String>{
        titleLine.text,
        if (authorLine != null) authorLine.text,
      };

      final candidates = lines.where((l) => !excluded.contains(l.text)).where((
        l,
      ) {
        final words = l.text
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        return words >= 6; // looks sentence-ish
      }).toList();

      candidates.sort((a, b) => b.text.length.compareTo(a.text.length));
      if (candidates.isNotEmpty) descLine = candidates.first;

      // Apply suggestions ONLY if fields are empty (autocomplete vibe)
      if (_title.text.trim().isEmpty) {
        _title.text = titleLine.text;
      }

      if (authorLine != null && _author.text.trim().isEmpty) {
        _author.text = authorLine.text
            .replaceFirst(RegExp(r'^(?i)by\s+'), '')
            .trim();
      }

      if (descLine != null && _description.text.trim().isEmpty) {
        _description.text = descLine.text.trim();
      }

      setState(() {});
    } catch (_) {
      // If OCR fails, just do nothing (no drama)
    } finally {
      await recognizer.close();
    }
  }

  Future<String?> _uploadCoverAndGetUrl(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final bytes = await file.readAsBytes();
    final path =
        'users/${user.uid}/cookbook_covers/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    try {
      String? coverUrl;
      if (_pickedImage != null) {
        coverUrl = await _uploadCoverAndGetUrl(_pickedImage!);
      }

      final notifier = context.read<Notifier>();
      await notifier.addCookbook(
        title: title,
        author: _author.text.trim().isEmpty ? null : _author.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        coverImageUrl: coverUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add cookbook')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryColour,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.white),
                  title: const Text('Take photo'),
                  titleTextStyle: TextStyles.inputTextSecondary,
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Choose from gallery'),
                  titleTextStyle: TextStyles.inputTextSecondary,

                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                if (_pickedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                    title: const Text('Remove photo'),
                    titleTextStyle: TextStyles.inputTextSecondary,

                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _pickedImage = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.primaryTextColour,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Add Cookbook',
                      style: TextStyles.pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cover picker
              GestureDetector(
                onTap: _saving ? null : _showImageSheet,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Add cover photo',
                              style: TextStyles.inputText,
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              _Input(controller: _title, hint: 'Cookbook title'),
              const SizedBox(height: 10),
              _Input(controller: _author, hint: 'Author (optional)'),
              const SizedBox(height: 10),
              _Input(
                controller: _description,
                hint: 'Description (optional)',
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Save button
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _saving ? Colors.grey : AppColors.primaryColour,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Cookbook',
                            style: TextStyles.smallHeadingSecondary,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _Input({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyles.inputText,
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
