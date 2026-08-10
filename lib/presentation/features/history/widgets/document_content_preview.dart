import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfx/pdfx.dart';

class DocumentContentPreview extends ConsumerStatefulWidget {
  const DocumentContentPreview({
    super.key,
    required this.fileId,
    this.fileName,
    this.mimeType,
  });

  final String fileId;
  final String? fileName;
  final String? mimeType;

  @override
  ConsumerState<DocumentContentPreview> createState() =>
      _DocumentContentPreviewState();
}

class _DocumentContentPreviewState extends ConsumerState<DocumentContentPreview> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;
  PdfControllerPinch? _pdfController;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(fileRepositoryProvider)
          .downloadFileContent(widget.fileId);
      if (!mounted) return;
      final bytes = Uint8List.fromList(data);
      PdfControllerPinch? pdf;
      if (_isPdf) {
        pdf = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
        );
      }
      setState(() {
        _bytes = bytes;
        _pdfController = pdf;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'This file is no longer available.';
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
        name.endsWith('.jpeg') ||
        name.endsWith('.webp');
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
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _UnavailableCard(message: _error!);
    }
    if (_bytes == null || _bytes!.isEmpty) {
      return const _UnavailableCard(
        message: 'No preview available for this document.',
      );
    }

    if (_isImage) {
      return _ImagePreview(bytes: _bytes!);
    }
    if (_isPdf && _pdfController != null) {
      return _PdfPreview(
        controller: _pdfController!,
        fileName: widget.fileName,
        onFullscreen: () => _openFullscreen(context),
      );
    }

    return _UnavailableCard(
      message: widget.fileName ?? 'Document uploaded for AI analysis',
    );
  }

  void _openFullscreen(BuildContext context) {
    if (_bytes == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) {
          if (_isImage) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              body: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(child: Image.memory(_bytes!)),
              ),
            );
          }
          if (_pdfController != null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.fileName ?? 'PDF')),
              body: PdfViewPinch(controller: _pdfController!),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
        ),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({
    required this.controller,
    this.fileName,
    required this.onFullscreen,
  });

  final PdfControllerPinch controller;
  final String? fileName;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.fileText, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                fileName ?? 'PDF document',
                style: context.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Full screen',
              onPressed: onFullscreen,
              icon: const Icon(LucideIcons.maximize2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 420,
            child: PdfViewPinch(
              controller: controller,
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileWarning, color: context.mutedColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
