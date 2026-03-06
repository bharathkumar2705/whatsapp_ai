import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/message_entity.dart';

class ExportService {
  static Future<void> exportChatToPdf({
    required String chatName,
    required List<MessageEntity> messages,
    String? customTitle,
    String? headerContent,
  }) async {
    final pdf = pw.Document();

    // Use a font that supports emojis/unicode if possible, or standard fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(customTitle ?? "Chat Export: $chatName", style: pw.TextStyle(font: boldFont, fontSize: 18)),
                  pw.Text(DateTime.now().toString().split('.')[0], style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            if (headerContent != null) ...[
              pw.Paragraph(text: headerContent, style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Divider(),
            ],
            pw.SizedBox(height: 20),
            ...messages.reversed.map((msg) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(msg.senderId == 'me' ? 'Me' : 'Participant', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blueGrey)),
                        pw.SizedBox(width: 8),
                        pw.Text(msg.timestamp.toString().split('.')[0], style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(msg.text, style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/chat_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Check out this chat export from WhatsApp AI');
  }

  static Future<void> shareTextAsNote(String title, String content) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${title.replaceAll(' ', '_')}.txt');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }
}
