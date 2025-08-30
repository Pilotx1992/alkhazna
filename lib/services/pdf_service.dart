import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
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
                'تم التوليد بتاريخ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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
                _buildExcelTableCell(name ?? '', font),
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
}
