import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../models/marketplace_model.dart';
import '../providers/marketplace_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _phone = TextEditingController();
  ListingCondition _condition = ListingCondition.good;
  final List<File> _images = [];
  bool _submitting = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;
  String? _error;

  static const int _maxImages = 5;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _category.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _title.text.trim().length >= 3 &&
      _description.text.trim().isNotEmpty &&
      _parsedPrice != null &&
      _parsedPrice! > 0;

  double? get _parsedPrice => double.tryParse(_price.text.trim());

  Future<void> _addImage(ImageSource source) async {
    if (_images.length >= _maxImages) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_images.length >= _maxImages) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppTheme.primaryColor),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addImage(source);
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _uploadProgress = 0;
      _uploadTotal = _images.length;
    });
    try {
      final id = await createListing(
        ref: ref,
        title: _title.text.trim(),
        description: _description.text.trim(),
        priceInr: _parsedPrice!,
        condition: _condition,
        category: _category.text.trim().isEmpty
            ? null
            : _category.text.trim(),
        sellerPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        imageFiles: _images,
        onImageProgress: (current, total) {
          if (mounted) setState(() => _uploadProgress = current);
        },
      );
      if (id != null && mounted) {
        context.pushReplacement('/marketplace/$id');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Post a Listing',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            children: [
              _label('Photos (up to $_maxImages)', Icons.photo_library),
              const SizedBox(height: 8),
              _buildPhotoStrip(isDark),
              const SizedBox(height: 16),
              _label('Title *', Icons.title),
              const SizedBox(height: 6),
              _field(_title, 'e.g. Cormen CLRS textbook', isDark),
              const SizedBox(height: 16),
              _label('Description *', Icons.description),
              const SizedBox(height: 6),
              _field(
                _description,
                'Condition, edition, why you\'re selling, anything useful.',
                isDark,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _label('Price (INR) *', Icons.currency_rupee),
              const SizedBox(height: 6),
              _field(
                _price,
                'e.g. 650',
                isDark,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _label('Condition', Icons.verified),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ListingCondition.values
                    .map((c) => ChoiceChip(
                          label: Text(c.label),
                          selected: _condition == c,
                          onSelected: (_) =>
                              setState(() => _condition = c),
                          labelStyle: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              _label('Category', Icons.category),
              const SizedBox(height: 6),
              _field(_category, 'e.g. CSE, ECE, All branches', isDark),
              const SizedBox(height: 16),
              _label('Your WhatsApp number', Icons.phone),
              const SizedBox(height: 6),
              _field(
                _phone,
                'e.g. 9876543210 (shown only to interested buyers)',
                isDark,
                keyboard: TextInputType.phone,
              ),
              if (_submitting && _uploadTotal > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Uploading image $_uploadProgress of $_uploadTotal…',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _uploadTotal == 0
                      ? null
                      : _uploadProgress / _uploadTotal,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(
                      AppTheme.primaryColor),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFFF0101),
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _canSubmit && !_submitting ? _submit : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _submitting ? 'Posting…' : 'Post Listing',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStrip(bool isDark) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _images[i],
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_images.length < _maxImages)
            InkWell(
              onTap: _showImageSourceSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo,
                        color: AppTheme.primaryColor, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String t, IconData i) => Row(
        children: [
          Icon(i, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            t,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController c,
    String hint,
    bool isDark, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: context.faintText),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
