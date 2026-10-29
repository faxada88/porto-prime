import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CourierCertificateSelection {
  const CourierCertificateSelection({
    required this.uploadToken,
    required this.fileName,
    required this.size,
  });

  final String uploadToken;
  final String fileName;
  final int size;
}

class CourierCertificateAttachment extends StatefulWidget {
  const CourierCertificateAttachment({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CourierCertificateSelection? value;
  final ValueChanged<CourierCertificateSelection?> onChanged;

  @override
  State<CourierCertificateAttachment> createState() =>
      _CourierCertificateAttachmentState();
}

class _CourierCertificateAttachmentState
    extends State<CourierCertificateAttachment> {
  bool uploading = false;
  String? error;

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pick() async {
    if (uploading) return;

    setState(() {
      uploading = true;
      error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Não foi possível ler este PDF.');
      }
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('O PDF deve ter no máximo 5 MB.');
      }
      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw Exception('Selecione um arquivo PDF válido.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiClient.instance.baseUrl}/auth/courier-certificate',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name.toLowerCase().endsWith('.pdf')
              ? file.name
              : '${file.name}.pdf',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      dynamic data;
      try {
        data = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? data['message'] : null;
        throw Exception(
          message is List
              ? message.join(', ')
              : message?.toString() ?? 'Não foi possível enviar o PDF.',
        );
      }

      final map = Map<String, dynamic>.from(data as Map);
      final token = map['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('O servidor não confirmou o anexo.');
      }

      widget.onChanged(
        CourierCertificateSelection(
          uploadToken: token,
          fileName: file.name,
          size: bytes.length,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected == null ? Colors.white : AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected == null ? AppColors.stroke : AppColors.mintStrong,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected == null ? AppColors.sand : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  selected == null
                      ? AppIcons.shield_outlined
                      : AppIcons.check_circle_rounded,
                  color: selected == null
                      ? const Color(0xFFB77818)
                      : AppColors.oceanDeep,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certidão de antecedentes criminais',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Anexe o PDF oficial da Polícia Federal. O arquivo fica vinculado à sua candidatura para análise.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.45,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.receipt_long_outlined,
                    color: AppColors.oceanDeep,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_sizeLabel(selected.size)} • PDF anexado',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover anexo',
                    onPressed:
                        uploading ? null : () => widget.onChanged(null),
                    icon: const Icon(
                      AppIcons.close_rounded,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: uploading ? null : _pick,
              icon: uploading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      selected == null
                          ? AppIcons.plus
                          : AppIcons.refresh_rounded,
                      size: 18,
                    ),
              label: Text(
                uploading
                    ? 'Enviando PDF...'
                    : selected == null
                        ? 'Selecionar certidão em PDF'
                        : 'Trocar arquivo',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Somente PDF • máximo 5 MB • documento usado exclusivamente na análise da candidatura.',
            style: TextStyle(
              fontSize: 9,
              height: 1.4,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
