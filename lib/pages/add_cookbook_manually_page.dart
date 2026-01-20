import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
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
  String? isbn;

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

  Future<void> _scanBarcode(ImageSource source) async {
    if (_saving) return;

    setState(() => _saving = true);

    XFile? img;
    BarcodeScanner? scanner;

    try {
      img = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (img == null) return;

      logPrint(String m) {
        // ignore: avoid_print
        print('[BARCODE] $m');
      }

      logPrint('Picked image: ${img.path}');

      scanner = BarcodeScanner(
        formats: [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upca,
          BarcodeFormat.upce,
        ],
      );
      final input = InputImage.fromFilePath(img.path);
      final barcodes = await scanner.processImage(input);

      logPrint('Detected ${barcodes.length} barcodes');
      for (final b in barcodes) {
        logPrint(
          ' - format=${b.format} raw="${b.rawValue}" display="${b.displayValue}"',
        );
      }

      String? raw = barcodes
          .map((b) => b.rawValue ?? b.displayValue)
          .whereType<String>()
          .map((s) => s.replaceAll(RegExp(r'[^0-9Xx]'), ''))
          .firstWhere(
            (s) => s.length == 13 || s.length == 10,
            orElse: () => '',
          );

      if (raw.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No barcode found — try again with the barcode filling the frame',
            ),
          ),
        );
        return;
      }

      // Convert ISBN-10 -> ISBN-13 (Google Books works with both, but 13 is safer)
      String isbn13 = raw;
      if (raw.length == 10) {
        // naive convert: prefix 978 + first 9 digits, recompute check digit
        final core = '978${raw.substring(0, 9)}';
        int sum = 0;
        for (int i = 0; i < core.length; i++) {
          final d = int.parse(core[i]);
          sum += (i % 2 == 0) ? d : d * 3;
        }
        final check = (10 - (sum % 10)) % 10;
        isbn13 = '$core$check';
      }

      logPrint('Using ISBN: $isbn13');

      // --- Google Books lookup ---
      // GET https://www.googleapis.com/books/v1/volumes?q=isbn:<isbn>
      final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': 'isbn:$isbn13',
        'projection': 'full',
        'maxResults': '1',
      });

      logPrint('Request: $uri');

      final res = await HttpClient().getUrl(uri).then((r) => r.close());
      final body = await res.transform(const Utf8Decoder()).join();

      logPrint('Google Books status: ${res.statusCode}');
      // ignore: avoid_print
      print('[BARCODE] Google Books body: $body');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not look up this ISBN')),
        );
        return;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? [];
      if (items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No book found for that barcode')),
        );
        return;
      }

      final volumeInfo =
          (items.first as Map<String, dynamic>)['volumeInfo']
              as Map<String, dynamic>? ??
          {};
      final title = (volumeInfo['title'] as String?)?.trim();
      final authors =
          (volumeInfo['authors'] as List?)?.whereType<String>().toList() ?? [];
      final desc = (volumeInfo['subtitle'] as String?)?.trim();

      // cover image
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      String? cover =
          (imageLinks?['extraLarge'] ??
                  imageLinks?['large'] ??
                  imageLinks?['thumbnail'] ??
                  imageLinks?['smallThumbnail'])
              as String?;

      logPrint('Parsed title="$title" authors=$authors cover="$cover"');
      logPrint('Parsed description length=${desc?.length ?? 0}');

      isbn = isbn13;
      if (title != null && _title.text.trim().isEmpty) _title.text = title;
      if (authors.isNotEmpty && _author.text.trim().isEmpty)
        _author.text = authors.join(', ');

      if (desc != null && _description.text.trim().isEmpty) {
        // "max 2 sentences"
        final cleaned = desc
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final parts = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
        _description.text = parts.take(2).join(' ').trim();
      }

      // If we got a cover URL, download it and set as picked image
      if (cover != null) {
        final coverUri = Uri.parse(cover);
        final coverRes = await HttpClient()
            .getUrl(coverUri)
            .then((r) => r.close());
        final bytes = await consolidateHttpClientResponseBytes(coverRes);

        final tmpDir = await Directory.systemTemp.createTemp('cookbook_cover_');
        final f = File('${tmpDir.path}/cover.jpg');
        await f.writeAsBytes(bytes);

        _pickedImage = XFile(f.path);
        logPrint('Downloaded cover to: ${f.path}');
      }

      if (mounted) setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print('[BARCODE] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to scan barcode')));
    } finally {
      await scanner?.close();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1500,
    );
    if (img == null) return;

    setState(() => _pickedImage = img);
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
        isbn: isbn,
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
          bottom: false,
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
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            child: Column(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isbn == null)
                          GestureDetector(
                            onTap: _saving
                                ? null
                                : () => _scanBarcode(ImageSource.camera),
                            child: Container(
                              height: 50,
                              padding: EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _saving
                                    ? Colors.grey
                                    : AppColors.accentColour1,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Scan barcode to auto-add',
                                  style: TextStyles.smallHeadingSecondary,
                                ),
                              ),
                            ),
                          ),

                        if (isbn != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentColour1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                notifier.partnerCodes.contains(isbn!)
                                    ? "This cookbook is part of the Made's Chef Collab, so all recipes will be automatically uploaded with this cookbook!"
                                    : "The author of this cookbook has not signed up to join Made's Chef Collab. Please reach out to your favourite cookbook authors and ask them to join the group.",
                                style: TextStyles.smallHeadingSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
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
                                      Icon(
                                        Icons.add_a_photo,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Upload a cover photo',
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

                        const SizedBox(height: 8),

                        _Input(controller: _title, hint: 'Cookbook title'),
                        const SizedBox(height: 8),
                        _Input(controller: _author, hint: 'Author (optional)'),
                        const SizedBox(height: 8),
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
                              color: _saving
                                  ? Colors.grey
                                  : AppColors.primaryColour,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save Cookbook${notifier.partnerCodes.contains(isbn ?? "") ? " and Recipes" : ""}',
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
              ],
            ),
          ),
        );
      },
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
