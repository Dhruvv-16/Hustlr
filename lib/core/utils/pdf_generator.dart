import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPreviewCertificate({
    String name = 'Hustlr Worker',
    String zone = 'Your Zone',
    String planName = 'Standard Shield',
    String policyNumber = 'HS-PENDING',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final expiry = DateTime(now.year + 1, now.month, now.day);
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
    final expiryStr = '${expiry.day} ${_monthName(expiry.month)} ${expiry.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('HUSTLR', style: pw.TextStyle(color: PdfColors.green800, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                      pw.Text('CERTIFICATE OF INSURANCE', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Text('Policy Number: $policyNumber', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Effective Dates: $dateStr - $expiryStr', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('COVERED PARTY', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Name: $name'),
                      pw.Text('Zone: $zone'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text('ACTIVE COVERAGE: ${planName.toUpperCase()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.SizedBox(height: 12),
                _buildCoverageRow('Rain Disruption', 'Auto-triggers when rainfall > 64.5mm/hr'),
                _buildCoverageRow('Extreme Heat', 'Triggers when temperature exceeds 42°C'),
                _buildCoverageRow('App Downtime', 'Outages lasting > 90 minutes'),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('This is a parametric insurance contract. Payouts are transferred automatically based on zone-wide triggers. Do not share this document.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text('Digitally Signed by Hustlr Underwriting API', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Hustlr_Certificate_$policyNumber',
    );
  }

  static String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  static pw.Widget _buildCoverageRow(String title, String desc) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            decoration: const pw.BoxDecoration(color: PdfColors.green, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(desc, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
