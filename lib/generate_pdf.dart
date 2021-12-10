import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

///
class GeneratePDF extends StatelessWidget {
  final List<DocumentReference?> selectedTiles;

  GeneratePDF(this.selectedTiles) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: "PDF Output");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Selected observations"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getData(),
        builder: (context, snap) => snap.connectionState != ConnectionState.done
            ? Center(
                child: CircularProgressIndicator(),
              )
            : PdfPreview(
                initialPageFormat: PdfPageFormat.letter,
                build: (format) => _buildDoc(snap.data),
                pdfFileName: "astrolog_export.pdf",
              ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    List<Map<String, dynamic>> outData = [];

    selectedTiles.forEach((element) async {
      final DocumentSnapshot<Map<String, dynamic>> data = await (element!.get(
              GetOptions(
                  source: !kIsWeb ? Source.cache : Source.serverAndCache))
          as FutureOr<DocumentSnapshot<Map<String, dynamic>>>);
      final DocumentSnapshot equipment = await data.data()!['equipment'].get(
          GetOptions(source: !kIsWeb ? Source.cache : Source.serverAndCache));
      outData.add({
        'data': data.data(),
        'equipment': equipment.data(),
      });
    });

    return outData;
  }

  Future<Uint8List> _buildDoc(List<Map<String, dynamic>>? data) {
    final pdfDocument = pw.Document(
        title: "Observation Summary",
        author: FirebaseAuth.instance.currentUser!.displayName,
        creator: "Astronomy Logbook",
        subject: "Astronomy and Stargazing");

    pdfDocument.addPage(
      pw.MultiPage(
        header: (context) => pw.Row(
          // mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Text(FirebaseAuth.instance.currentUser!.displayName!),
            // pw.Text(DateTime.now().yMMMd),
          ],
        ),
        build: (context) => data!
            .map((e) => _observation2Tile(e['data'], e['equipment']))
            .toList(),
      ),
    );

    return pdfDocument.save();
  }

  pw.Widget _observation2Tile(
      Map<String, dynamic> data, Map<String, dynamic> equipment) {
    final DateTime dateTime = data['dateTime'].toDate();

    return pw.Container(
      decoration: pw.BoxDecoration(
        // borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.max,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(data['title'], style: pw.TextStyle(fontSize: 18)),
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
                pw.Text(dateTime.hourMinute + " (${dateTime.timeZoneName})"),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Text("Location"),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("${data['latitude']}, ${data['longitude']}"),
                      pw.Text(data['location']),
                    ]),
              ],
            ),
            pw.TableRow(children: [
              pw.Text("Equipment"),
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
                pw.Text("Sky conditions"),
                pw.Table(columnWidths: {
                  0: pw.FixedColumnWidth(5)
                }, children: [
                  pw.TableRow(children: [
                    pw.Text("Seeing:"),
                    pw.Text("${data['seeing']}")
                  ]),
                  pw.TableRow(children: [
                    pw.Text("Visibility:"),
                    pw.Text("${data['visibility']}")
                  ]),
                  pw.TableRow(children: [
                    pw.Text("Transparency:"),
                    pw.Text("${data['transparency']}")
                  ]),
                ]),
              ],
            ),
          ]),
          pw.Text("Notes: "),
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
