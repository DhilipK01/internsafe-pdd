import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Public document preview for shared links (no auth).
class SharedDocumentPreview extends StatefulWidget {
  const SharedDocumentPreview({
    super.key,
    required this.previewUrl,
    this.fileName,
    this.mimeType,
  });

  final String previewUrl;
  final String? fileName;
  final String? mimeType;

  @override
  State<SharedDocumentPreview> createState() => _SharedDocumentPreviewState();
}

class _SharedDocumentPreviewState extends State<SharedDocumentPreview> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;
  PdfControllerPinch? _pdf;

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = Dio();
      final res = await dio.get<List<int>>(
        widget.previewUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? []);
      PdfControllerPinch? pdf;
      if (_isPdf && bytes.isNotEmpty) {
        pdf = PdfControllerPinch(document: PdfDocument.openData(bytes));
      }
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _pdf = pdf;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Document preview unavailable';
          _loading = false;
        });
      }
    }
  }

  bool get _isImage {
    final mime = widget.mimeType ?? '';
    final name = widget.fileName?.toLowerCase() ?? '';
    return mime.startsWith('image/') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg');
  }

  bool get _isPdf {
    final mime = widget.mimeType ?? '';
    return mime == 'application/pdf' ||
        (widget.fileName?.toLowerCase().endsWith('.pdf') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _bytes == null || _bytes!.isEmpty) {
      return _MetaOnly(fileName: widget.fileName);
    }
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          child: Image.memory(_bytes!, fit: BoxFit.contain),
        ),
      );
    }
    if (_isPdf && _pdf != null) {
      return SizedBox(
        height: 360,
        child: PdfViewPinch(controller: _pdf!),
      );
    }
    return _MetaOnly(fileName: widget.fileName);
  }
}

class _MetaOnly extends StatelessWidget {
  const _MetaOnly({this.fileName});
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: context.mutedColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(fileName ?? 'Document', style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
