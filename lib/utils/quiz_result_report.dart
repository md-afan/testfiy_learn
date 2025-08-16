// pubspec.yaml dependencies (make sure to include):
// pdf: ^3.10.4
// printing: ^5.11.0
// charts_flutter: ^0.12.0 (optional for visualization)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class StudentReportPage extends StatelessWidget {
  final String studentName;
  final int correct;
  final int incorrect;
  final int unanswered;
  final int total;
  final int rank;
  final int totalStudents;

  const StudentReportPage({
    super.key,
    required this.studentName,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
    required this.total,
    required this.rank,
    required this.totalStudents,
  });

  double get percentile => (1 - (rank - 1) / totalStudents) * 100;

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Student Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Name: $studentName'),
            pw.Text('Total Questions: $total'),
            pw.Text('Correct: $correct'),
            pw.Text('Incorrect: $incorrect'),
            pw.Text('Unanswered: $unanswered'),
            pw.SizedBox(height: 12),
            pw.Text('Rank: $rank / $totalStudents'),
            pw.Text('Percentile: ${percentile.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  List<charts.Series<AnswerData, String>> _createChartData() {
    final data = [
      AnswerData('Correct', correct, Colors.green),
      AnswerData('Incorrect', incorrect, Colors.red),
      AnswerData('Unanswered', unanswered, Colors.grey),
    ];

    return [
      charts.Series<AnswerData, String>(
        id: 'Answers',
        domainFn: (AnswerData data, _) => data.label,
        measureFn: (AnswerData data, _) => data.count,
        colorFn: (AnswerData data, _) => charts.ColorUtil.fromDartColor(data.color),
        data: data,
        labelAccessorFn: (AnswerData row, _) => '${row.label}: ${row.count}',
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: charts.PieChart(
                _createChartData(),
                animate: true,
                defaultRenderer: charts.ArcRendererConfig(arcRendererDecorators: [
                  charts.ArcLabelDecorator(
                    labelPosition: charts.ArcLabelPosition.auto,
                  )
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final pdfData = await _generatePdf();
                await Printing.layoutPdf(onLayout: (_) => pdfData);
              },
              child: const Text('Export to PDF'),
            )
          ],
        ),
      ),
    );
  }
}

class AnswerData {
  final String label;
  final int count;
  final Color color;

  AnswerData(this.label, this.count, this.color);
}
