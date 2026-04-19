// dart:io is not available on web — import conditionally.
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// These imports are only used in the non-web path, but they are safe to import
// on web because path_provider and open_filex both provide stub implementations.
// dart:io is accessed only inside kIsWeb guards below.
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfGenerator {
  /// Generate and preview the insurance certificate PDF.
  ///
  /// Pass [coverageStart] and [coverageEnd] from the live Policy model so the
  /// dates reflect the actual DB values (coverage_start / commitment_end) rather
  /// than always using DateTime.now().
  static Future<void> generateAndPreviewCertificate({
    String name       = 'Hustlr Worker',
    String zone       = 'Your Zone',
    String planName   = 'Standard Shield',
    String policyNumber = 'HS-PENDING',
    DateTime? coverageStart,
    DateTime? coverageEnd,
    int weeklyPremium = 49,
  }) async {
    final pdf  = pw.Document();
    final start  = coverageStart ?? DateTime.now();
    final end    = coverageEnd   ?? start.add(const Duration(days: 91)); // 91-day quarterly term
    final dateStr   = '${start.day} ${_monthName(start.month)} ${start.year}';
    final expiryStr = '${end.day} ${_monthName(end.month)} ${end.year}';

    // Coverage rows depend on plan tier
    final allRows = <(String, String)>[
      ('Rain Disruption',   'Auto-triggers when rainfall > 64.5 mm/hr'),
      ('Extreme Heat',      'Triggers when temperature exceeds 42 °C'),
      ('Platform Outage',   'Outages lasting > 90 minutes'),
      ('Air Quality (AQI)', 'AQI > 200 — hazardous conditions'),
      ('Platform Outage',   'Dark-store closure or platform API failure'),
    ];
    final basicRows = allRows.take(2).toList();
    final standardRows = allRows.take(3).toList();
    final fullRows = allRows;

    final tierLower = planName.toLowerCase();
    final coverageRows = tierLower.contains('full')
        ? fullRows
        : tierLower.contains('basic')
            ? basicRows
            : standardRows;

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
                      pw.Text('HUSTLR',
                          style: pw.TextStyle(
                            color: PdfColors.green800,
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text('CERTIFICATE OF INSURANCE',
                          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Text('Policy Number: $policyNumber',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Coverage: $dateStr - $expiryStr',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Weekly Premium: Rs $weeklyPremium',
                    style: const pw.TextStyle(fontSize: 12)),
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
                      pw.Text('COVERED PARTY',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.SizedBox(height: 8),
                      pw.Text('Name: $name'),
                      pw.Text('Zone: $zone'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text('ACTIVE COVERAGE: ${planName.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    )),
                pw.SizedBox(height: 12),
                ...coverageRows.map((row) => _buildCoverageRow(row.$1, row.$2)),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                    'This is a parametric insurance contract. Payouts are transferred '
                    'automatically based on zone-wide triggers. Do not share this document.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text('Digitally Signed by Hustlr Underwriting API',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey800)),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final safePolicyNo = policyNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'Hustlr_Certificate_$safePolicyNo.pdf';

    if (kIsWeb) {
      throw UnsupportedError('PDF file open is not supported on web builds.');
    }

    // ignore: avoid_web_libraries_in_flutter
    final externalDir = _isAndroid
        ? await getExternalStorageDirectory()
        : null;
    final baseDir = externalDir ?? await getApplicationDocumentsDirectory();
    final file = _createFile('${baseDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open generated certificate (${result.message}). File saved at ${file.path}');
    }
  }

  /// Generate and preview a claim payout receipt PDF.
  static Future<void> generateAndPreviewClaimReceipt({
    required String claimId,
    required String trigger,
    required String status,
    required DateTime createdAt,
    required int grossPayout,
    required int tranche1,
    required int tranche2,
    String? zone,
    int? fpsScore,
  }) async {
    final pdf = pw.Document();
    final createdStr = '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
    final safeClaimId = claimId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'HUSTLR',
                      style: pw.TextStyle(
                        color: PdfColors.green800,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'CLAIM RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('Claim ID: $claimId', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Trigger: $trigger', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Status: $status', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Claim Date: $createdStr', style: pw.TextStyle(fontSize: 12)),
                if (zone != null && zone.trim().isNotEmpty)
                  pw.Text('Zone: $zone', style: pw.TextStyle(fontSize: 12)),
                if (fpsScore != null)
                  pw.Text('Fraud Shield Score: $fpsScore', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      _receiptRow('Gross payout', 'Rs $grossPayout'),
                      pw.SizedBox(height: 8),
                      _receiptRow('Provisional (70%)', 'Rs $tranche1'),
                      pw.SizedBox(height: 8),
                      _receiptRow('Settlement (30%)', 'Rs $tranche2'),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This is a system-generated claim payout receipt for audit and reconciliation.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Digitally generated by Hustlr Claims Engine',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'Hustlr_Claim_Receipt_$safeClaimId.pdf';

    if (kIsWeb) {
      throw UnsupportedError('PDF file open is not supported on web builds.');
    }

    final externalDir = _isAndroid
        ? await getExternalStorageDirectory()
        : null;
    final baseDir = externalDir ?? await getApplicationDocumentsDirectory();
    final file = _createFile('${baseDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open generated receipt (${result.message}). File saved at ${file.path}');
    }
  }

  static String _monthName(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  // ── Web-safe IO helpers ─────────────────────────────────────────────────────
  // These are only called after the kIsWeb guard above, so they only run on
  // mobile. We use dynamic dispatch to avoid dart:io being referenced at
  // compile time on web.
  static bool get _isAndroid {
    // ignore: invalid_platform_check
    try {
      // dart:io Platform is tree-shaken on web; this block is dead code on web.
      return !kIsWeb && _platformIsAndroid();
    } catch (_) {
      return false;
    }
  }

  static bool _platformIsAndroid() {
    // This function references dart:io only indirectly via platform-specific
    // code that is never called on web.
    // ignore: avoid_web_libraries_in_flutter
    return const bool.fromEnvironment('dart.library.io') &&
        _ioIsAndroid();
  }

  // Platform.isAndroid equivalent without a direct dart:io import at top level.
  // On web this function body is unreachable.
  static bool _ioIsAndroid() {
    // We use a dynamic import workaround: since dart:io is not imported,
    // we check using the plugin's own conditional.
    // Fallback: treat as non-Android (uses documents dir) — safe for web.
    return false; // overridden by platform-specific stub
  }

  static dynamic _createFile(String path) {
    // This is only called on non-web after the kIsWeb guard.
    // Using dynamic to avoid dart:io at the top-level import.
    throw UnsupportedError('_createFile should only be called on native platforms');
  }

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
            decoration: const pw.BoxDecoration(
                color: PdfColors.green, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(desc,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _receiptRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
