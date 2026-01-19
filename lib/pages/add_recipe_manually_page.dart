import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class AddRecipeManuallyPage extends StatefulWidget {
  const AddRecipeManuallyPage({super.key});

  @override
  State<AddRecipeManuallyPage> createState() => _AddRecipeManuallyPageState();
}

class _AddRecipeManuallyPageState extends State<AddRecipeManuallyPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  final _timeMinutes = TextEditingController();
  final _servings = TextEditingController();

  final _tagsInput = TextEditingController();
  final List<String> _tags = [];

  final List<TextEditingController> _ingredientCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepCtrls = [TextEditingController()];

  final _notes = TextEditingController();

  String _sourceType = 'manual'; // cookbook | url | tiktok | instagram | manual
  final _sourceUrl = TextEditingController();
  final _sourceAuthor = TextEditingController();
  final _sourceTitle = TextEditingController();

  final _cookbookId = TextEditingController();
  final _pageNumber = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _images = [];

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _timeMinutes.dispose();
    _servings.dispose();

    _tagsInput.dispose();
    for (final c in _ingredientCtrls) {
      c.dispose();
    }
    for (final c in _stepCtrls) {
      c.dispose();
    }

    _notes.dispose();

    _sourceUrl.dispose();
    _sourceAuthor.dispose();
    _sourceTitle.dispose();

    _cookbookId.dispose();
    _pageNumber.dispose();

    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_saving) return;

    if (source == ImageSource.gallery) {
      final imgs = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1500,
      );
      if (imgs.isEmpty) return;
      setState(() => _images.addAll(imgs));
      return;
    }

    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1500,
    );
    if (img == null) return;
    setState(() => _images.add(img));
  }

  void _showImagesSheet() {
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
                    await _pickImages(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Choose from gallery'),
                  titleTextStyle: TextStyles.inputTextSecondary,
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImages(ImageSource.gallery);
                  },
                ),
                if (_images.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                    title: const Text('Remove all photos'),
                    titleTextStyle: TextStyles.inputTextSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _images.clear());
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addIngredient() {
    setState(() => _ingredientCtrls.add(TextEditingController()));
  }

  void _removeIngredient(int i) {
    final c = _ingredientCtrls.removeAt(i);
    c.dispose();
    setState(() {});
  }

  void _addStep() {
    setState(() => _stepCtrls.add(TextEditingController()));
  }

  void _removeStep(int i) {
    final c = _stepCtrls.removeAt(i);
    c.dispose();
    setState(() {});
  }

  void _addTagFromInput() {
    final t = _tagsInput.text.trim();
    if (t.isEmpty) return;
    if (_tags.any((x) => x.toLowerCase() == t.toLowerCase())) return;
    setState(() {
      _tags.add(t);
      _tagsInput.clear();
    });
  }

  void _removeTag(String t) {
    setState(() => _tags.remove(t));
  }

  Future<void> _save() async {
    // UI-only for now
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: Column(
          children: [
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
                    'Add Recipe',
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
                    // Images
                    GestureDetector(
                      onTap: _saving ? null : _showImagesSheet,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _images.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add recipe photos',
                                    style: TextStyles.inputText,
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.file(
                                            File(_images[i].path),
                                            fit: BoxFit.cover,
                                            width: 220,
                                            height: 140,
                                          ),
                                        ),
                                        Positioned(
                                          right: 6,
                                          top: 6,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _images.removeAt(i),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.55,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _Input(controller: _title, hint: 'Recipe title'),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _description,
                      hint: 'Description (optional)',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _Input(
                            controller: _timeMinutes,
                            hint: 'Time (mins)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Input(
                            controller: _servings,
                            hint: 'Servings',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tags
                    const Text('Tags', style: TextStyles.smallHeading),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _Input(
                            controller: _tagsInput,
                            hint: 'e.g. quick, vegan',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addTagFromInput,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColour,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t, style: TextStyles.inputText),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeTag(t),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Ingredients
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ingredients',
                            style: TextStyles.smallHeading,
                          ),
                        ),
                        GestureDetector(
                          onTap: _addIngredient,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColour1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Add',
                              style: TextStyles.smallHeadingSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(_ingredientCtrls.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Input(
                                  controller: _ingredientCtrls[i],
                                  hint: 'e.g. 2 tbsp olive oil',
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_ingredientCtrls.length > 1)
                                GestureDetector(
                                  onTap: () => _removeIngredient(i),
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Steps
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Steps', style: TextStyles.smallHeading),
                        ),
                        GestureDetector(
                          onTap: _addStep,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColour1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Add',
                              style: TextStyles.smallHeadingSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(_stepCtrls.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.accentColour1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyles.smallHeadingSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _Input(
                                  controller: _stepCtrls[i],
                                  hint: 'Step ${i + 1}',
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_stepCtrls.length > 1)
                                GestureDetector(
                                  onTap: () => _removeStep(i),
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    const Text('Notes', style: TextStyles.smallHeading),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _notes,
                      hint: 'Personal notes (optional)',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Source
                    const Text('Source', style: TextStyles.smallHeading),
                    const SizedBox(height: 8),
                    _Dropdown(
                      value: _sourceType,
                      items: const [
                        'manual',
                        'cookbook',
                        'url',
                        'tiktok',
                        'instagram',
                      ],
                      onChanged: (v) => setState(() => _sourceType = v),
                    ),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _sourceUrl,
                      hint: 'Source URL (optional)',
                    ),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _sourceAuthor,
                      hint: 'Source author (optional)',
                    ),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _sourceTitle,
                      hint: 'Source title (optional)',
                    ),

                    const SizedBox(height: 16),

                    // Cookbook link
                    const Text('Cookbook link', style: TextStyles.smallHeading),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _cookbookId,
                      hint: 'Cookbook ID (optional)',
                    ),
                    const SizedBox(height: 8),
                    _Input(
                      controller: _pageNumber,
                      hint: 'Page number (optional)',
                      keyboardType: TextInputType.number,
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
                                  'Save Recipe',
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
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
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
        keyboardType: keyboardType,
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

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          iconEnabledColor: AppColors.primaryTextColour,
          dropdownColor: Colors.white,
          style: TextStyles.inputText,
          items: items
              .map((x) => DropdownMenuItem<String>(value: x, child: Text(x)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
