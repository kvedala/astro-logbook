import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

import 'generated/l10n.dart';
import 'utils.dart';

///
class GeneratePDF extends StatelessWidget {
  final List<DocumentReference?> selectedTiles;

  GeneratePDF(this.selectedTiles, {super.key}) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: "PDF Output");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).selectedObservations),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getData(),
        builder: (context, snap) => snap.connectionState != ConnectionState.done
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : PdfPreview(
                initialPageFormat: PdfPageFormat.letter,
                build: (format) => _buildDoc(context, snap.data),
                pdfFileName: "astrolog_export.pdf",
              ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    List<Map<String, dynamic>> outData = [];

    for (var element in selectedTiles) {
      final DocumentSnapshot<Map<String, dynamic>> data = await (element!.get(
              const GetOptions(
                  source: !kIsWeb ? Source.cache : Source.serverAndCache))
          as FutureOr<DocumentSnapshot<Map<String, dynamic>>>);
      final DocumentSnapshot equipment = await data.data()!['equipment'].get(
          const GetOptions(
              source: !kIsWeb ? Source.cache : Source.serverAndCache));
      outData.add({
        'data': data.data(),
        'equipment': equipment.data(),
      });
    }

    return outData;
  }

  Future<Uint8List> _buildDoc(
      BuildContext context, List<Map<String, dynamic>>? data) {
    final pdfDocument = pw.Document(
        title: S.of(context).observationSummary,
        author: FirebaseAuth.instance.currentUser!.displayName,
        creator: "Astronomy Logbook",
        subject: S.of(context).astronomyAndStargazing);

    pdfDocument.addPage(
      pw.MultiPage(
        header: (context) => pw.Row(
          // mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Text(FirebaseAuth.instance.currentUser!.displayName!),
            // pw.Text(DateTime.now().yMMMd),
          ],
        ),
        build: (_) => data!
            .map((e) => _observation2Tile(context, e['data'], e['equipment']))
            .toList(),
      ),
    );

    return pdfDocument.save();
  }

  pw.Widget _observation2Tile(BuildContext context, Map<String, dynamic> data,
      Map<String, dynamic> equipment) {
    final DateTime dateTime = data['dateTime'].toDate();

    return pw.Container(
      decoration: const pw.BoxDecoration(
        // borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.max,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(data['title'], style: const pw.TextStyle(fontSize: 18)),
            ],
          ),
          pw.Table(children: [
            pw.TableRow(
              children: [
                pw.Text("Messier"),
                pw.Text(data['messier']?.toString() ?? ""),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Text("NGC"),
                pw.Text(data['ngc']?.toString() ?? ""),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Text("Date"),
                pw.Text(dateTime.yMMMd),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Text("Time"),
                pw.Text("${dateTime.hourMinute} (${dateTime.timeZoneName})"),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Text(S.of(context).location),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("${data['latitude']}, ${data['longitude']}"),
                      pw.Text(data['location']),
                    ]),
              ],
            ),
            pw.TableRow(children: [
              pw.Text(S.of(context).equipment),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(equipment['telescope'] +
                      " (${equipment['aperture']}mm, f/" +
                      (equipment['focalLength'] / equipment['aperture'])
                          .toStringAsFixed(1) +
                      ")"),
                  pw.Text(equipment['mount']),
                ],
              ),
            ]),
            pw.TableRow(
              children: [
                pw.Text(S.of(context).skyConditions),
                pw.Table(columnWidths: {
                  0: const pw.FixedColumnWidth(5)
                }, children: [
                  pw.TableRow(children: [
                    pw.Text("${S.of(context).seeing}:"),
                    pw.Text("${data['seeing']}")
                  ]),
                  pw.TableRow(children: [
                    pw.Text("${S.of(context).visibility}:"),
                    pw.Text("${data['visibility']}")
                  ]),
                  pw.TableRow(children: [
                    pw.Text("${S.of(context).transparency}:"),
                    pw.Text("${data['transparency']}")
                  ]),
                ]),
              ],
            ),
          ]),
          pw.Text("${S.of(context).notes}: "),
          pw.ListView.builder(
            itemCount: data['notes'].length,
            itemBuilder: (context, index) => pw.Bullet(
                text: data['notes'][index], textAlign: pw.TextAlign.justify),
          )
        ],
      ),
    );
  }
}
