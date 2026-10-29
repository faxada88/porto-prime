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
  static const _accent = Color(0xFFF0A93A);
  static const _accentSoft = Color(0xFFFFF1D5);

  bool uploading = false;
  String? error;

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
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
    final complete = selected != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: complete
              ? const [
                  AppColors.ocean900,
                  AppColors.ocean700,
                ]
              : const [
                  Color(0xFFFFFBF3),
                  Color(0xFFFFF3DE),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -45,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete
                      ? Colors.white.withValues(alpha: .055)
                      : _accent.withValues(alpha: .08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: complete
                              ? Colors.white.withValues(alpha: .12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: complete
                                ? Colors.white.withValues(alpha: .12)
                                : _accent.withValues(alpha: .16),
                          ),
                        ),
                        child: Icon(
                          complete
                              ? AppIcons.check_circle_rounded
                              : AppIcons.shield_outlined,
                          color: complete
                              ? Colors.white
                              : const Color(0xFF9A6419),
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complete
                                  ? 'Certidão anexada'
                                  : 'Anexe sua certidão',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.35,
                                color: complete
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              complete
                                  ? 'Documento recebido e pronto para seguir com sua candidatura.'
                                  : 'Selecione o PDF oficial da Polícia Federal para continuar.',
                              style: TextStyle(
                                fontSize: 10.3,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: complete
                                    ? const Color(0xFFD5E5E1)
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (complete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: AppColors.ocean300,
                              fontSize: 8,
                              letterSpacing: .7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!complete)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .82),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _accent.withValues(alpha: .13),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.info_outline_rounded,
                            color: Color(0xFF9A6419),
                            size: 18,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Formato PDF • máximo 5 MB • o documento fica vinculado à análise da sua candidatura.',
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.45,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (complete) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              AppIcons.receipt_long_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_sizeLabel(selected.size)} • PDF seguro',
                                  style: const TextStyle(
                                    color: Color(0xFFC7DDD7),
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover anexo',
                            onPressed: uploading
                                ? null
                                : () => widget.onChanged(null),
                            icon: const Icon(
                              AppIcons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (error != null && error!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.coral100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            AppIcons.error_outline_rounded,
                            color: AppColors.coral600,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(
                                color: AppColors.coral600,
                                fontSize: 9.7,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: complete
                        ? OutlinedButton.icon(
                            onPressed: uploading ? null : _pick,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .26),
                              ),
                            ),
                            icon: const Icon(
                              AppIcons.refresh_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'Trocar arquivo',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: uploading ? null : _pick,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ocean900,
                            ),
                            icon: uploading
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    AppIcons.plus,
                                    size: 18,
                                  ),
                            label: Text(
                              uploading
                                  ? 'Enviando PDF...'
                                  : 'Selecionar certidão em PDF',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
