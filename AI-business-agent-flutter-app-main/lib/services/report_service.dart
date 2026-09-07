import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  Future<Uint8List> buildLocationPassport({
    required String address,
    required double score,
    required String verdict,
    required List<String> risks,
  }) async {
    final document = pw.Document();
    document.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Padding(
        padding: const pw.EdgeInsets.all(28),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('TOCHKA.AI', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
          pw.SizedBox(height: 8),
          pw.Text('Məkan Pasportu', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text(address, style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Text('Məkan indeksi: ${score.toStringAsFixed(1)}/10', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(verdict),
          pw.SizedBox(height: 18),
          pw.Text('Aşkarlanmış risklər', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...risks.map((risk) => pw.Bullet(text: risk)),
          pw.Spacer(),
          pw.Text('Tochka.ai — biznes məkanlarını data ilə seçin', style: const pw.TextStyle(color: PdfColors.grey)),
        ]),
      ),
    ));
    return document.save();
  }

  Future<void> printLocationPassport({required String address, required double score, required String verdict, required List<String> risks}) async {
    final bytes = await buildLocationPassport(address: address, score: score, verdict: verdict, risks: risks);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
