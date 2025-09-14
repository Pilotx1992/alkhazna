import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bidi/bidi.dart' as bidi;
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';

class PdfService {
  static Future<void> exportComprehensiveReport({
    required String month,
    required int year,
    required List<IncomeEntry> incomeEntries,
    required List<OutcomeEntry> outcomeEntries,
  }) async {
    final doc = pw.Document();
    final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf'));

    final filteredIncome =
        incomeEntries.where((e) => e.name.isNotEmpty || e.amount > 0).toList();
    final filteredOutcome =
        outcomeEntries.where((e) => e.name.isNotEmpty || e.amount > 0).toList();
    
    final totalIncome = filteredIncome.fold<double>(0, (s, e) => s + e.amount);
    final totalOutcome =
        filteredOutcome.fold<double>(0, (s, e) => s + e.amount);
    final balance = totalIncome - totalOutcome;
    final isPositive = balance >= 0;

    // صفحات الدخل
    if (filteredIncome.isNotEmpty) {
      _addPaginatedTablePages(
        doc: doc,
        entries: filteredIncome,
        font: font,
        boldFont: boldFont,
        title: 'تقرير الدخل - $month $year',
        headerColor: PdfColors.blue100,
        totalColor: PdfColors.blue200,
        totalAmount: totalIncome,
      );
    }

    // صفحات المصروفات
    if (filteredOutcome.isNotEmpty) {
      _addPaginatedTablePages(
        doc: doc,
        entries: filteredOutcome,
        font: font,
        boldFont: boldFont,
        title: 'تقرير المصروفات - $month $year',
        headerColor: PdfColors.red100,
        totalColor: PdfColors.red200,
        totalAmount: totalOutcome,
      );
    }

    // صفحة الملخص
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: isPositive ? PdfColors.green700 : PdfColors.orange700,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text('ملخص الرصيد',
                      style: pw.TextStyle(
                          font: boldFont, fontSize: 20, color: PdfColors.white),
                      textDirection: pw.TextDirection.rtl),
                  pw.SizedBox(height: 5),
                  pw.Text('$month $year',
                      style: pw.TextStyle(
                          font: font, fontSize: 16, color: PdfColors.white),
                      textDirection: pw.TextDirection.rtl),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildExcelTableCell('الفئة', boldFont, isHeader: true),
                    _buildExcelTableCell('القيمة', boldFont, isHeader: true),
                    _buildExcelTableCell('الحالة', boldFont, isHeader: true),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _buildExcelTableCell('إجمالي الدخل', font),
                    _buildExcelTableCell(_formatNumber(totalIncome), font),
                    _buildExcelTableCell('↗', font),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red50),
                  children: [
                    _buildExcelTableCell('إجمالي المصروفات', font),
                    _buildExcelTableCell(_formatNumber(totalOutcome), font),
                    _buildExcelTableCell('↘', font),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: isPositive
                          ? PdfColors.green100
                          : PdfColors.orange100),
                  children: [
                    _buildExcelTableCell('الرصيد الصافي', boldFont,
                        isHeader: true),
                    _buildExcelTableCell(_formatNumber(balance.abs()), boldFont,
                        isHeader: true),
                    _buildExcelTableCell(isPositive ? 'فائض' : 'عجز', boldFont,
                        isHeader: true),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(
                    font: font, fontSize: 10, color: PdfColors.grey600),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> shareComprehensiveReport({
    required String month,
    required int year,
    required List<IncomeEntry> incomeEntries,
    required List<OutcomeEntry> outcomeEntries,
  }) async {
    // Create the PDF document
    final doc = pw.Document();
    final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf'));

    final filteredIncome =
        incomeEntries.where((e) => e.name.isNotEmpty || e.amount > 0).toList();
    final filteredOutcome =
        outcomeEntries.where((e) => e.name.isNotEmpty || e.amount > 0).toList();

    final totalIncome = filteredIncome.fold<double>(0, (s, e) => s + e.amount);
    final totalOutcome = filteredOutcome.fold<double>(0, (s, e) => s + e.amount);
    final balance = totalIncome - totalOutcome;
    final isPositive = balance >= 0;

    // Add detailed income pages if data exists
    if (filteredIncome.isNotEmpty) {
      _addPaginatedTablePages<IncomeEntry>(
        doc: doc,
        entries: filteredIncome,
        font: font,
        boldFont: boldFont,
        title: 'Income - $month $year',
        headerColor: PdfColors.blue100,
        totalColor: PdfColors.blue200,
        totalAmount: totalIncome,
      );
    }

    // Add detailed expense pages if data exists
    if (filteredOutcome.isNotEmpty) {
      _addPaginatedTablePages<OutcomeEntry>(
        doc: doc,
        entries: filteredOutcome,
        font: font,
        boldFont: boldFont,
        title: 'Expensess- $month $year',
        headerColor: PdfColors.red100,
        totalColor: PdfColors.red200,
        totalAmount: totalOutcome,
      );
    }

    // Add final summary page
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Summary Title
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey700,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Text(
                'Summary',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.SizedBox(height: 40),

            // Income Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.green, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Income',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '+${_formatNumber(totalIncome)}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.Text(
                    '${filteredIncome.length} entries',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.green600,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Expenses Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.red100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.red, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Expenses',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                      color: PdfColors.red700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '-${_formatNumber(totalOutcome)}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.red700,
                    ),
                  ),
                  pw.Text(
                    '${filteredOutcome.length} entries',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.red600,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Net Balance
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: isPositive ? PdfColors.green : PdfColors.red,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Net Balance',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${isPositive ? '+' : '-'}${_formatNumber(balance.abs())}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    isPositive ? 'Surplus' : 'Deficit',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Center(
              child: pw.Text(
                'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(
                    font: font, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    // Share the PDF with enhanced filename
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${month}_$year.pdf',
    );
  }

  static Future<void> generateAndPrintReport({
    required String month,
    required int year,
    required List<IncomeEntry> incomeEntries,
    required List<OutcomeEntry> outcomeEntries,
  }) async {
    await exportComprehensiveReport(
      month: month,
      year: year,
      incomeEntries: incomeEntries,
      outcomeEntries: outcomeEntries,
    );
  }

  /// Share names of income entries with zero amounts as PDF
  static Future<void> shareZeroAmountNames({
    required List<IncomeEntry> incomeEntries,
    required String month,
    required int year,
  }) async {
    // Filter entries with zero amounts and non-empty names
    final zeroAmountEntries = incomeEntries
        .where((entry) => entry.amount == 0 && entry.name.trim().isNotEmpty)
        .toList();

    if (zeroAmountEntries.isEmpty) {
      // Show message if no zero amount entries found
      return;
    }

    final doc = pw.Document();
    final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf'));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Excel-style design
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'الخزنة',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: PdfColors.white,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '$month $year',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Excel-style table
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4), // Name
                    1: const pw.FlexColumnWidth(1), // Index
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildExcelTableCell('الاسم', boldFont, isHeader: true),
                        _buildExcelTableCell('م', boldFont, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...zeroAmountEntries.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final incomeEntry = entry.value;
                      // Fix Arabic text direction and rendering
                      final arabicName = _fixArabicText(incomeEntry.name);
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                        ),
                        children: [
                          _buildExcelTableCell(arabicName, font),
                          _buildExcelTableCell('$index', font),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ' عدد: ${zeroAmountEntries.length}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: PdfColors.black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      ' تاريخ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Share the PDF with proper filename
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${month}_$year.pdf',
    );
  }

  static void _addPaginatedTablePages<T>({
    required pw.Document doc,
    required List<T> entries,
    required pw.Font font,
    required pw.Font boldFont,
    required String title,
    required PdfColor headerColor,
    required PdfColor totalColor,
    required double totalAmount,
    int maxRowsPerPage = 14,
  }) {
    final pages = <List<T>>[];
    if (entries.isEmpty) {
      pages.add([]);
    } else {
      for (int i = 0; i < entries.length; i += maxRowsPerPage) {
        int end = (i + maxRowsPerPage < entries.length)
            ? i + maxRowsPerPage
            : entries.length;
        final chunk = entries.sublist(i, end);
        pages.add(chunk);
      }
    }

    // Debug: Print the total number of entries
    
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final chunk = pages[pageIndex];
      
      final isLastPage = pageIndex == pages.length - 1;

      final dataRows = <pw.TableRow>[];
      if (chunk.isEmpty) {
        dataRows.add(
          pw.TableRow(
            children: [
              _buildExcelTableCell('لا توجد بيانات', font),
              _buildExcelTableCell('', font),
              _buildExcelTableCell('', font),
              _buildExcelTableCell('', font),
            ],
          ),
        );
      } else {
        for (int i = 0; i < chunk.length; i++) {
          final item = chunk[i];
          double? amount;
          String? name;
          DateTime? date;

          if (item is IncomeEntry) {
            amount = item.amount;
            name = item.name;
            date = item.date;
          } else if (item is OutcomeEntry) {
            amount = item.amount;
            name = item.name;
            date = item.date;
          } else if (item is Map) {
            amount = item['amount'] as double?;
            name = item['name'] as String?;
            date = item['date'] as DateTime?;
          }

          dataRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
              ),
              children: [
                _buildExcelTableCell(
                  (amount != null && amount > 0) ? _formatNumber(amount) : '',
                  font,
                ),
                _buildExcelTableCell(_fixArabicText(name ?? ''), font),
                _buildExcelTableCell(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                      : '',
                  font,
                ),
                _buildExcelTableCell(
                    '${pageIndex * maxRowsPerPage + i + 1}', font),
              ],
            ),
          );
        }
      }

      final tableRows = <pw.TableRow>[
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildExcelTableCell('القيمة', boldFont, isHeader: true),
            _buildExcelTableCell('الاسم', boldFont, isHeader: true),
            _buildExcelTableCell('التاريخ', boldFont, isHeader: true),
            _buildExcelTableCell('م', boldFont, isHeader: true),
          ],
        ),
        ...dataRows,
        if (isLastPage && entries.isNotEmpty)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: totalColor),
            children: [
              _buildExcelTableCell(_formatNumber(totalAmount), boldFont,
                  isHeader: true),
              _buildExcelTableCell('الإجمالي', boldFont, isHeader: true),
              _buildExcelTableCell('', boldFont),
              _buildExcelTableCell('', boldFont),
            ],
          ),
      ];

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildReportHeader(
                title,
                font,
                boldFont,
                headerColor,
                pages.length > 1
                    ? '(صفحة ${pageIndex + 1} من ${pages.length})'
                    : '',
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: tableRows,
                ),
              ),
              pw.SizedBox(height: 10),
              if (pages.length > 1 && chunk.isNotEmpty)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'عرض الصفوف من ${pageIndex * maxRowsPerPage + 1} إلى ${pageIndex * maxRowsPerPage + chunk.length} من ${entries.length}',
                    style: pw.TextStyle(
                        font: font, fontSize: 10, color: PdfColors.grey600),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  static pw.Widget _buildReportHeader(
    String title,
    pw.Font font,
    pw.Font boldFont,
    PdfColor color,
    String subtitle,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
                font: boldFont, fontSize: 20, color: PdfColors.white),
            textDirection: pw.TextDirection.rtl,
          ),
          if (subtitle.isNotEmpty) pw.SizedBox(height: 5),
          if (subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                  font: font, fontSize: 14, color: PdfColors.white),
              textDirection: pw.TextDirection.rtl,
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildExcelTableCell(String text, pw.Font font,
      {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 14 : 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static String _formatNumber(double number) {
    if (number == 0) return '0';
    final parts = number.toStringAsFixed(0).split('.');
    final integerPart = parts[0];
    final reversed = integerPart.split('').reversed.join('');
    final withCommas =
        RegExp(r'.{1,3}').allMatches(reversed).map((m) => m.group(0)).join(',');
    return withCommas.split('').reversed.join('');
  }

  /// Fix Arabic text rendering issues
  static String _fixArabicText(String text) {
    if (text.isEmpty) return text;

    try {
      // Check if text contains Arabic characters
      final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
      if (!arabicRegex.hasMatch(text)) {
        return text; // Return as-is if no Arabic text
      }

      // Simply return the text as-is for now
      // The PDF widget with proper font should handle Arabic text correctly
      return text;
    } catch (e) {
      // If processing fails, return original text
      return text;
    }
  }
}
