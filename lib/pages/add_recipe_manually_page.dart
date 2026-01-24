import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/components/inputs.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:path/path.dart' as p;

class AddRecipeManuallyPage extends StatefulWidget {
  final bool openCamera;
  final bool editingRecipe;
  final Recipe? oldRecipe;
  const AddRecipeManuallyPage({
    super.key,
    this.openCamera = false,
    this.editingRecipe = false,
    this.oldRecipe,
  });

  @override
  State<AddRecipeManuallyPage> createState() => _AddRecipeManuallyPageState();
}

class _AddRecipeManuallyPageState extends State<AddRecipeManuallyPage> {
  final _addFromURL = TextEditingController();

  final _title = TextEditingController();
  final _description = TextEditingController();

  final _timeMinutes = TextEditingController();
  final _servings = TextEditingController();

  final _tagsInput = TextEditingController();
  final List<String> _tags = [];
  final _tagFocus = FocusNode();
  bool _addingTag = false;
  bool showingTagOptions = false;
  final _ingredientInput = TextEditingController();
  final List<Ingredient> _ingredients = [];

  bool _ingredientParsing = false;
  String? _ingredientError;

  final List<TextEditingController> _stepCtrls = [TextEditingController()];

  final _notes = TextEditingController();

  String _sourceType = 'My Own Recipe'; // cookbook | URL | Social Media
  final _sourceUrl = TextEditingController();
  final _sourceAuthor = TextEditingController();
  final _sourceTitle = TextEditingController();

  String? _selectedCookbookId;

  final _pageNumber = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _images = [];

  bool _saving = false;
  bool _scanning = false;
  bool _scrapping = false;

  @override
  void initState() {
    super.initState();
    if (widget.openCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scanFromSource(ImageSource.camera);
      });
    }
    if (widget.editingRecipe && widget.oldRecipe != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _applyRecipeDraft(widget.oldRecipe!.toFirestore());
        _sourceUrl.text = widget.oldRecipe?.sourceUrl ?? '';
        _sourceType = widget.oldRecipe?.sourceType ?? "My Own Recipe";
        _selectedCookbookId = widget.oldRecipe?.cookbookId;
        final urls = widget.oldRecipe?.imageUrls ?? const <String>[];
        final xfiles = await xfilesFromUrls(urls);
        _images.addAll(xfiles);
        setState(() {});

        // add images
        // add source too
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _timeMinutes.dispose();
    _servings.dispose();

    _tagsInput.dispose();
    _tagFocus.dispose();
    _ingredientInput.dispose();

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

  Future<void> _scanRecipeFromCookbook() async {
    if (_saving) return;

    // pick images first (use your existing sheet for camera/gallery)
    _showScanSheet();
  }

  void _showScanSheet() {
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
                    await _scanFromSource(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Choose from gallery'),
                  titleTextStyle: TextStyles.inputTextSecondary,
                  onTap: () async {
                    Navigator.pop(context);
                    await _scanFromSource(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanFromURL(String url) async {
    if (_saving || _scanning || _scrapping) return;
    setState(() => _scrapping = true);
    try {
      showFullScreenLoader(context);

      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('recipeFromUrl');

      final res = await fn.call({'url': url});
      debugPrint(res.data.toString());
      final data = Map<String, dynamic>.from(res.data as Map);
      _applyRecipeDraft(data);
      _sourceType = 'URL';
      _sourceUrl.text = url;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scan complete - review and save',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scan failed - please try again',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } finally {
      hideFullScreenLoader(context);
      if (mounted) setState(() => _scrapping = false);
    }
  }

  Future<void> _scanFromSource(ImageSource source) async {
    if (_saving || _scanning || _scrapping) return;

    // Pick 1 photo from camera, or 1+ from gallery
    List<XFile> files = [];
    if (source == ImageSource.gallery) {
      final imgs = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (imgs.isEmpty) return;
      files = imgs;
    } else {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (img == null) return;
      files = [img];
    }

    setState(() => _scanning = true);

    try {
      showFullScreenLoader(context);
      final ocrPayload = await _runOcr(files);

      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('parseRecipeFromOcr');

      final res = await fn.call({
        'pages': ocrPayload,
        'hint': {'sourceType': 'Cookbook', 'language': 'en'},
      });
      debugPrint(res.data.toString());
      final data = Map<String, dynamic>.from(res.data as Map);
      _applyRecipeDraft(data);
      // Mark as cookbook source by default
      _sourceType = 'Cookbook';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scan complete - review and save',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scan failed - please try again',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } finally {
      hideFullScreenLoader(context);
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<List<Map<String, dynamic>>> _runOcr(List<XFile> files) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final pages = <Map<String, dynamic>>[];

      for (final f in files) {
        final inputImage = InputImage.fromFilePath(f.path);
        final recognised = await recognizer.processImage(inputImage);

        final blocks = recognised.blocks.map((b) {
          final rect = b.boundingBox;
          return {
            'text': b.text,
            'rect': {
              'l': rect.left,
              't': rect.top,
              'r': rect.right,
              'b': rect.bottom,
            },
            'lines': b.lines.map((l) {
              final r = l.boundingBox;
              return {
                'text': l.text,
                'rect': {'l': r.left, 't': r.top, 'r': r.right, 'b': r.bottom},
                'elements': l.elements.map((e) {
                  final er = e.boundingBox;
                  return {
                    'text': e.text,
                    'rect': {
                      'l': er.left,
                      't': er.top,
                      'r': er.right,
                      'b': er.bottom,
                    },
                  };
                }).toList(),
              };
            }).toList(),
          };
        }).toList();

        pages.add({
          'fileName': f.name,
          'fullText': recognised.text,
          'blocks': blocks,
        });
      }

      return pages;
    } finally {
      await recognizer.close();
    }
  }

  Future<List<XFile>> xfilesFromUrls(List<String> urls) async {
    final dir = await getTemporaryDirectory();

    final files = await Future.wait(
      urls.map((url) async {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) {
          throw Exception('Failed to download $url (${res.statusCode})');
        }

        final ext = p.extension(Uri.parse(url).path);
        final filename = '${DateTime.now().microsecondsSinceEpoch}$ext';
        final file = File(p.join(dir.path, filename));

        await file.writeAsBytes(res.bodyBytes);
        return XFile(file.path);
      }),
    );

    return files;
  }

  void _applyRecipeDraft(Map<String, dynamic> data) {
    String? s(dynamic v) =>
        (v is String && v.trim().isNotEmpty) ? v.trim() : null;

    final title = s(data['title']);
    final description = s(data['description']);
    final notes = s(data['notes']);

    final timeMinutes = data['timeMinutes'];
    final servings = data['servings'];
    final pageNum = data['pageNumber'];
    final sourceAuthor = data['sourceAuthor'];
    final sourceTitle = data['sourceTitle'];

    final notifier = context.read<Notifier>();

    final tags = (data['tags'] is List)
        ? List<String>.from(data['tags'])
              .where(
                (t) => notifier.allTags.any(
                  (a) => a.toLowerCase() == t.toLowerCase(),
                ),
              )
              .map(
                (t) => notifier.allTags.firstWhere(
                  (a) => a.toLowerCase() == t.toLowerCase(),
                ),
              )
              .toList()
        : <String>[];

    final List<Ingredient> parsedIngredients = (data['ingredients'] is List)
        ? (data['ingredients'] as List)
              .map((m) => Ingredient.fromMap(Map<String, dynamic>.from(m)))
              .toList()
        : <Ingredient>[];

    final stepLines = (data['steps'] is List)
        ? List<String>.from(data['steps'])
        : <String>[];

    setState(() {
      if (title != null) _title.text = title;
      _description.text = description ?? '';
      _notes.text = notes ?? '';

      _timeMinutes.text = (timeMinutes is num)
          ? timeMinutes.toInt().toString()
          : '';
      _servings.text = (servings is num) ? servings.toInt().toString() : '';
      _pageNumber.text = (pageNum is num) ? pageNum.toInt().toString() : '';
      _sourceAuthor.text = sourceAuthor ?? '';
      _sourceTitle.text = sourceTitle ?? '';

      _tags
        ..clear()
        ..addAll(tags);

      setState(() {
        // ...existing title/desc/time/tags/etc...

        _ingredients
          ..clear()
          ..addAll(parsedIngredients);

        _ingredientInput.clear();
        _ingredientError = null;
        _ingredientParsing = false;

        // steps stays the same
      });

      _setControllerList(_stepCtrls, stepLines.isEmpty ? [''] : stepLines);
    });
  }

  void _setControllerList(
    List<TextEditingController> ctrls,
    List<String> values,
  ) {
    // dispose extras
    while (ctrls.length > values.length) {
      ctrls.removeLast().dispose();
    }
    // add missing
    while (ctrls.length < values.length) {
      ctrls.add(TextEditingController());
    }
    // set text
    for (var i = 0; i < values.length; i++) {
      ctrls[i].text = values[i];
    }
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

  void showFullScreenLoader(BuildContext context, {String? message}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Loading',
      barrierColor: AppColors.primaryTextColour.withAlpha(225),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryTextColour,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message ?? 'Processing recipe...',
                    style: TextStyles.subheading.copyWith(
                      color: AppColors.secondaryTextColour,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    message ?? 'Please do not leave this page',
                    style: TextStyles.bodyTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void hideFullScreenLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _addIngredientFromInput() async {
    final raw = _ingredientInput.text.trim();
    if (raw.isEmpty || _ingredientParsing) return;

    setState(() {
      _ingredientParsing = true;
      _ingredientError = null;
    });

    try {
      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('parseIngredient');

      final res = await fn.call({'raw': raw});
      final ingred = Ingredient.fromMap(
        Map<String, dynamic>.from(res.data as Map),
      );

      setState(() {
        _ingredients.insert(0, ingred);
        _ingredientInput.clear();
      });
    } catch (_) {
      setState(() => _ingredientError = 'Couldn’t parse');
    } finally {
      if (mounted) setState(() => _ingredientParsing = false);
    }
  }

  void _removeIngredient(int i) {
    setState(() => _ingredients.removeAt(i));
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
      showingTagOptions = false;
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

      final steps = _stepCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final imageUrls = _images.isEmpty
          ? <String>[]
          : await _uploadImagesAndGetUrls(_images);

      await notifier.addRecipe(
        title: title,
        id: widget.editingRecipe ? widget.oldRecipe!.id : null,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        imageUrls: imageUrls,
        ingredients: _ingredients,
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
        updateExisting: widget.editingRecipe,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to add recipe - please try again',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
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
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,

              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
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
                      Expanded(
                        child: Text(
                          widget.editingRecipe ? "Edit Recipe" : 'Add Recipe',
                          style: TextStyles.pageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: (_saving || _scanning || _scrapping)
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryColour,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: (_saving || _scanning || _scrapping)
                                      ? Colors.grey
                                      : AppColors.primaryColour,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Save',
                                    style: TextStyles.smallHeadingSecondary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.editingRecipe)
                            GestureDetector(
                              onTap: (_saving || _scanning || _scrapping)
                                  ? null
                                  : _scanRecipeFromCookbook,
                              child: Container(
                                height: 50,
                                padding: EdgeInsets.all(8),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: (_saving || _scanning || _scrapping)
                                      ? Colors.grey
                                      : AppColors.accentColour1,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Scan recipe from cookbook',
                                    style: TextStyles.smallHeadingSecondary,
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.editingRecipe) const SizedBox(height: 8),
                          if (!widget.editingRecipe)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Input(
                                    controller: _addFromURL,
                                    hint: 'Add recipe from URL or social media',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: (_saving || _scanning || _scrapping)
                                      ? null
                                      : () => _scanFromURL(_addFromURL.text),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (_saving || _scanning || _scrapping)
                                          ? Colors.grey
                                          : AppColors.accentColour1,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Add',
                                        style: TextStyles.smallHeadingSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!widget.editingRecipe) const SizedBox(height: 8),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                    padding:
                                                        const EdgeInsets.all(6),
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
                          Text('Recipe Title', style: TextStyles.subheading),
                          Input(controller: _title, hint: 'Recipe title'),
                          const SizedBox(height: 8),
                          Text('Description', style: TextStyles.subheading),
                          Input(
                            controller: _description,
                            hint: 'Description (optional)',
                            maxLines: 3,
                          ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Time',
                                  style: TextStyles.subheading,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Servings',
                                  style: TextStyles.subheading,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Input(
                                  controller: _timeMinutes,
                                  hint: 'Time (mins)',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Input(
                                  controller: _servings,
                                  hint: 'Servings',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Tags
                          const Text('Tags', style: TextStyles.subheading),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              final q = value.text.trim().toLowerCase();
                              if (q.isEmpty) {
                                showingTagOptions = false;
                                setState(() {});
                                return const Iterable<String>.empty();
                              }
                              final matches = notifier.allTags
                                  .where((t) => t.toLowerCase().contains(q))
                                  .take(3);
                              if (matches.isNotEmpty) {
                                showingTagOptions = true;
                                setState(() {});
                              }
                              return matches;
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return showingTagOptions
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: options.map((t) {
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _tags.add(t);
                                                showingTagOptions = false;
                                              });
                                              _tagsInput.clear();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                t,
                                                style: TextStyles.inputText,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : SizedBox.shrink();
                            },

                            onSelected: (selection) {
                              if (_tags.any(
                                (x) =>
                                    x.toLowerCase() == selection.toLowerCase(),
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

                                  return Input(
                                    controller: textController,
                                    hint: 'Type a tag (e.g. Vegan)',
                                    focusNode: focusNode,
                                    onChanged: (v) {
                                      if (_addingTag) return;

                                      final q = v.trim();
                                      if (q.isEmpty) return;

                                      // Auto-add if exact match (case-insensitive)
                                      final isExact = notifier.allTags.any(
                                        (t) =>
                                            t.toLowerCase() == q.toLowerCase(),
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
                          if (_tags.isEmpty) const SizedBox(height: 45),
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
                                    color: showingTagOptions
                                        ? AppColors.backgroundColour
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        t,
                                        style: TextStyles.inputedText.copyWith(
                                          color: showingTagOptions
                                              ? AppColors.backgroundColour
                                              : AppColors.primaryTextColour,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _removeTag(t),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: showingTagOptions
                                              ? AppColors.backgroundColour
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 16),

                          Text('Ingredients', style: TextStyles.subheading),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Input(
                                      controller: _ingredientInput,
                                      hint: 'e.g. 2 tbsp olive oil',
                                      onChanged: (_) {
                                        if (_ingredientError != null) {
                                          setState(
                                            () => _ingredientError = null,
                                          );
                                        }
                                      },
                                      onSubmitted: (_) =>
                                          _addIngredientFromInput(),
                                    ),
                                    const SizedBox(height: 6),
                                    if (_ingredientError != null)
                                      Text(
                                        _ingredientError!,
                                        style: TextStyles.inputText.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _ingredientParsing
                                    ? null
                                    : _addIngredientFromInput,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentColour1,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _ingredientParsing
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                AppColors.secondaryTextColour,
                                          ),
                                        )
                                      : Text(
                                          'Add',
                                          style:
                                              TextStyles.bodyTextBoldSecondary,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          if (_ingredients.isNotEmpty)
                            Column(
                              children: List.generate(_ingredients.length, (i) {
                                final ingred = _ingredients[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ParsedIngredientPill(
                                          ingredient: ingred,
                                          showSubOption: false,
                                          onSub: () async {},
                                          subs: [],
                                          removeSubs: () {},
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _removeIngredient(i),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            size: 16,
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

                          const SizedBox(height: 8),

                          // Steps
                          Text('Steps', style: TextStyles.subheading),
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
                                          style:
                                              TextStyles.bodyTextBoldSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Input(
                                        controller: _stepCtrls[i],
                                        hint: 'Step ${i + 1}',
                                        maxLines: 3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _removeStep(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          size: 16,
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
                          Row(
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
                                    '${_stepCtrls.length + 1}',
                                    style: TextStyles.bodyTextBoldSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                    'Add New Step',
                                    style: TextStyles.bodyTextBoldSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Notes
                          const Text('Notes', style: TextStyles.subheading),
                          Input(
                            controller: _notes,
                            hint: 'Personal notes (optional)',
                            maxLines: 3,
                          ),

                          const SizedBox(height: 16),

                          // Source
                          const Text('Source', style: TextStyles.subheading),
                          Dropdown(
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
                            Input(
                              controller: _sourceUrl,
                              hint: 'Source URL (optional)',
                            ),
                            const SizedBox(height: 8),
                            Input(
                              controller: _sourceAuthor,
                              hint: 'Source author (optional)',
                            ),
                            const SizedBox(height: 8),
                            Input(
                              controller: _sourceTitle,
                              hint: 'Source title (optional)',
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Cookbook link
                          if (_sourceType == "Cookbook") ...[
                            const Text(
                              'Cookbook link',
                              style: TextStyles.subheading,
                            ),
                            CookbookDropdown(
                              value: _selectedCookbookId,
                              cookbooks: notifier.cookbooks,
                              onChanged: (v) =>
                                  setState(() => _selectedCookbookId = v),
                            ),
                            const SizedBox(height: 8),
                            Input(
                              controller: _pageNumber,
                              hint: 'Page number (optional)',
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 16),
                          ],

                          // Save button
                          GestureDetector(
                            onTap: (_saving || _scanning || _scrapping)
                                ? null
                                : _save,
                            child: Container(
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (_saving || _scanning || _scrapping)
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
                                          color: AppColors.secondaryTextColour,
                                        ),
                                      )
                                    : Text(
                                        'Save Recipe',
                                        style: TextStyles.smallHeadingSecondary,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
