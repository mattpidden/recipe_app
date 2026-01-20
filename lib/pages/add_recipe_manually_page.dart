import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/notifiers/notifier.dart';
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
  final _tagFocus = FocusNode();
  bool _addingTag = false;

  final List<TextEditingController> _ingredientCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepCtrls = [TextEditingController()];

  final _notes = TextEditingController();

  String _sourceType =
      'My Own Recipe'; // cookbook | url | tiktok | instagram | manual
  final _sourceUrl = TextEditingController();
  final _sourceAuthor = TextEditingController();
  final _sourceTitle = TextEditingController();

  String? _selectedCookbookId;

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
    _tagFocus.dispose();
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

  void addTagIfExact(String input) {
    final q = input.trim();
    if (q.isEmpty) return;
    final notifier = context.read<Notifier>();
    final match = notifier.allTags.firstWhere(
      (t) => t.toLowerCase() == q.toLowerCase(),
      orElse: () => '',
    );
    if (match.isEmpty) return;

    if (_tags.any((x) => x.toLowerCase() == match.toLowerCase())) return;

    setState(() {
      _tags.add(match);
    });

    _tagsInput.clear();
  }

  void _removeTag(String t) {
    setState(() => _tags.remove(t));
  }

  Future<List<String>> _uploadImagesAndGetUrls(List<XFile> files) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const [];

    final futures = files.map((f) async {
      final bytes = await f.readAsBytes();

      final path =
          'users/${user.uid}/recipe_images/${DateTime.now().millisecondsSinceEpoch}_${f.name}.jpg';

      final ref = FirebaseStorage.instance.ref().child(path);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      return await ref.getDownloadURL();
    }).toList();

    return await Future.wait(futures);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    try {
      final notifier = context.read<Notifier>();

      final ingredients = _ingredientCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => Ingredient(raw: t))
          .toList();

      final steps = _stepCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final imageUrls = _images.isEmpty
          ? <String>[]
          : await _uploadImagesAndGetUrls(_images);

      await notifier.addRecipe(
        title: title,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        imageUrls: imageUrls,
        ingredients: ingredients,
        steps: steps,
        tags: _tags,
        timeMinutes: int.tryParse(_timeMinutes.text),
        servings: int.tryParse(_servings.text),
        sourceType: _sourceType,
        sourceUrl: _sourceUrl.text.trim().isEmpty
            ? null
            : _sourceUrl.text.trim(),
        sourceAuthor: _sourceAuthor.text.trim().isEmpty
            ? null
            : _sourceAuthor.text.trim(),
        sourceTitle: _sourceTitle.text.trim().isEmpty
            ? null
            : _sourceTitle.text.trim(),
        cookbookId: _selectedCookbookId,
        pageNumber: int.tryParse(_pageNumber.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add recipe')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                                      Icon(
                                        Icons.add_a_photo,
                                        color: Colors.grey,
                                      ),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.55),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
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
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue value) {
                            final q = value.text.trim().toLowerCase();
                            if (q.isEmpty)
                              return const Iterable<String>.empty();

                            return notifier.allTags.where(
                              (t) => t.toLowerCase().contains(q),
                            );
                          },
                          onSelected: (selection) {
                            if (_tags.any(
                              (x) => x.toLowerCase() == selection.toLowerCase(),
                            ))
                              return;
                            setState(() => _tags.add(selection));
                            _tagsInput.clear();
                            _tagFocus.requestFocus();
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                // Keep your existing controller so the rest of your code still works
                                if (textController != _tagsInput) {
                                  textController.value = _tagsInput.value;
                                  textController.addListener(() {
                                    _tagsInput.value = textController.value;
                                  });
                                }

                                return _Input(
                                  controller: _tagsInput,
                                  hint: 'Type a tag (e.g. Vegan)',
                                  focusNode: _tagFocus,
                                  onChanged: (v) {
                                    if (_addingTag) return;

                                    final q = v.trim();
                                    if (q.isEmpty) return;

                                    // Auto-add if exact match (case-insensitive)
                                    final isExact = notifier.allTags.any(
                                      (t) => t.toLowerCase() == q.toLowerCase(),
                                    );
                                    if (!isExact) return;

                                    _addingTag = true;
                                    addTagIfExact(q);
                                    _addingTag = false;
                                  },
                                  onSubmitted: (v) => addTagIfExact(v),
                                );
                              },
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
                        Text('Ingredients', style: TextStyles.smallHeading),
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
                                  (i == _ingredientCtrls.length - 1)
                                      ? GestureDetector(
                                          onTap: _addIngredient,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentColour1,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Add',
                                              style: TextStyles
                                                  .smallHeadingSecondary,
                                            ),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () => _removeIngredient(i),
                                          child: Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                        Text('Steps', style: TextStyles.smallHeading),
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
                                      child: Column(
                                        children: [
                                          Text(
                                            '${i + 1}',
                                            style: TextStyles
                                                .smallHeadingSecondary,
                                          ),
                                        ],
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
                                  (i == _stepCtrls.length - 1)
                                      ? GestureDetector(
                                          onTap: _addStep,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentColour1,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Add',
                                              style: TextStyles
                                                  .smallHeadingSecondary,
                                            ),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () => _removeStep(i),
                                          child: Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                        _Input(
                          controller: _notes,
                          hint: 'Personal notes (optional)',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        // Source
                        const Text('Source', style: TextStyles.smallHeading),
                        _Dropdown(
                          value: _sourceType,
                          items: const [
                            'My Own Recipe',
                            'Cookbook',
                            'URL',
                            'Social Media',
                          ],
                          onChanged: (v) => setState(() => _sourceType = v),
                        ),
                        if (_sourceType == "URL" ||
                            _sourceType == "Social Media") ...[
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
                        ],
                        const SizedBox(height: 16),

                        // Cookbook link
                        if (_sourceType == "Cookbook") ...[
                          const Text(
                            'Cookbook link',
                            style: TextStyles.smallHeading,
                          ),
                          _CookbookDropdown(
                            value: _selectedCookbookId,
                            cookbooks: notifier.cookbooks,
                            onChanged: (v) =>
                                setState(() => _selectedCookbookId = v),
                          ),
                          const SizedBox(height: 8),
                          _Input(
                            controller: _pageNumber,
                            hint: 'Page number (optional)',
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 16),
                        ],

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
      },
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _Input({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
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
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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

class _CookbookDropdown extends StatelessWidget {
  final String? value;
  final List<dynamic>
  cookbooks; // keep dynamic to avoid needing Cookbook import here
  final ValueChanged<String?> onChanged;

  const _CookbookDropdown({
    required this.value,
    required this.cookbooks,
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
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: AppColors.primaryTextColour,
          style: TextStyles.inputText,
          hint: const Text('Cookbook (optional)', style: TextStyles.inputText),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('None')),
            ...cookbooks.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id as String,
                child: Text(
                  (c.title as String?) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
