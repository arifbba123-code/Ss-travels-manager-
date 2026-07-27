import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/entry.dart';

/// Handles generating a professional PDF and PNG report for a single
/// [DailyEntry], and sharing them (WhatsApp / any app). Report generation
/// itself works fully offline (no network calls) — only the underlying
/// entry data now lives in Firestore instead of a local database.
class ReportService {
  static const companyName = 'SS Tours & Travels';

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null; // logo optional — app still works without an asset
    }
  }

  /// Builds and saves a PDF report for [entry]. Returns the file.
  static Future<File> generatePdf(DailyEntry entry) async {
    final doc = pw.Document();
    final gold = PdfColor.fromInt(0xFFF2B705);
    final black = PdfColor.fromInt(0xFF0B0B0B);
    final grey = PdfColor.fromInt(0xFF555555);
    final logo = await _logo();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: black, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(children: [
                      if (logo != null) ...[
                        pw.Container(
                          width: 44,
                          height: 44,
                          child: pw.Image(logo),
                        ),
                        pw.SizedBox(width: 10),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(companyName,
                              style: pw.TextStyle(color: gold, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Daily Trip & Account Report', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        ],
                      ),
                    ]),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(DateFormat('dd MMM yyyy').format(DateTime.parse(entry.date)),
                            style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold)),
                        pw.Text(DateFormat('EEEE').format(DateTime.parse(entry.date)),
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              _sectionTitle('Trip Details', gold),
              _infoRow('Vehicle', entry.vehicleName, grey),
              _infoRow('Driver', entry.driverName, grey),
              pw.SizedBox(height: 14),

              _sectionTitle('Collection', gold),
              _infoRow('Online Collection', 'Rs. ${entry.onlineCollection.toStringAsFixed(2)}', grey),
              _infoRow('Cash Collection', 'Rs. ${entry.cashCollection.toStringAsFixed(2)}', grey),
              _infoRow('Total Collection', 'Rs. ${entry.totalCollection.toStringAsFixed(2)}', black, bold: true),
              pw.SizedBox(height: 14),

              _sectionTitle('Expenses', gold),
              _infoRow('CNG', 'Rs. ${entry.cng.toStringAsFixed(2)}', grey),
              _infoRow('Petrol', 'Rs. ${entry.petrol.toStringAsFixed(2)}', grey),
              _infoRow('Driver Salary', 'Rs. ${entry.driverSalary.toStringAsFixed(2)}', grey),
              _infoRow('Rental', 'Rs. ${entry.rental.toStringAsFixed(2)}', grey),
              _infoRow('Other Expense', 'Rs. ${entry.otherExpense.toStringAsFixed(2)}', grey),
              _infoRow('Total Expense', 'Rs. ${entry.totalExpense.toStringAsFixed(2)}', black, bold: true),
              pw.SizedBox(height: 14),

              _sectionTitle('Balance Summary', gold),
              _infoRow('Old Balance', 'Rs. ${entry.oldBalance.toStringAsFixed(2)}', grey),
              _infoRow('Profit', 'Rs. ${entry.profit.toStringAsFixed(2)}', grey, bold: true),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: gold, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Closing Balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Rs. ${entry.balance.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),

              if (entry.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 14),
                _sectionTitle('Notes', gold),
                pw.Text(entry.notes, style: pw.TextStyle(color: grey, fontSize: 10)),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Text('Generated by $companyName Manager App',
                  style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SSTours_Report_${entry.date}_${entry.id ?? DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _sectionTitle(String text, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 12)),
      );

  static pw.Widget _infoRow(String label, String value, PdfColor color, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.black, fontSize: 10)),
            pw.Text(value,
                style: pw.TextStyle(
                    color: color, fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  /// Renders a widget (built by [buildReportWidget]) to a PNG file via the
  /// [ScreenshotController] and returns the saved file.
  static Future<File> generatePng(ScreenshotController controller) async {
    final Uint8List? bytes = await controller.capture(pixelRatio: 3.0);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SSTours_Report_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes ?? Uint8List(0));
    return file;
  }

  /// Shareable widget used as the PNG report layout — visually mirrors the PDF.
  static Widget buildReportWidget(DailyEntry entry) {
    const gold = Color(0xFFF2B705);
    const black = Color(0xFF0B0B0B);
    const panel = Color(0xFF161616);

    Widget row(String label, String value, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(value,
                  style: TextStyle(
                      color: color ?? Colors.white,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ],
          ),
        );

    Widget sectionTitle(String t) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(t, style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 14)),
        );

    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      color: black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    CircleAvatar(backgroundColor: gold, child: Icon(Icons.directions_car, color: Colors.black)),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SS Tours & Travels', style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Daily Report', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(entry.date)),
                    style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          sectionTitle('Trip Details'),
          row('Vehicle', entry.vehicleName),
          row('Driver', entry.driverName),
          sectionTitle('Collection'),
          row('Online', '₹${entry.onlineCollection.toStringAsFixed(0)}'),
          row('Cash', '₹${entry.cashCollection.toStringAsFixed(0)}'),
          row('Total Collection', '₹${entry.totalCollection.toStringAsFixed(0)}', bold: true),
          sectionTitle('Expenses'),
          row('CNG', '₹${entry.cng.toStringAsFixed(0)}'),
          row('Petrol', '₹${entry.petrol.toStringAsFixed(0)}'),
          row('Driver Salary', '₹${entry.driverSalary.toStringAsFixed(0)}'),
          row('Rental', '₹${entry.rental.toStringAsFixed(0)}'),
          row('Other', '₹${entry.otherExpense.toStringAsFixed(0)}'),
          row('Total Expense', '₹${entry.totalExpense.toStringAsFixed(0)}', bold: true),
          sectionTitle('Summary'),
          row('Old Balance', '₹${entry.oldBalance.toStringAsFixed(0)}'),
          row('Profit', '₹${entry.profit.toStringAsFixed(0)}',
              bold: true, color: entry.profit >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE84C6B)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Closing Balance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text('₹${entry.balance.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> sharePdf(DailyEntry entry) async {
    final file = await generatePdf(entry);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Daily report from $companyName - ${entry.date}');
  }

  static Future<void> sharePng(File pngFile, DailyEntry entry) async {
    await Share.shareXFiles([XFile(pngFile.path)],
        text: 'Daily report from $companyName - ${entry.date}');
  }
}
