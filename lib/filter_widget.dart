import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'utils.dart';
import 'gallary_tile.dart';
import 'generate_pdf.dart';

/// Track search filter data
final Map<String, dynamic> searchState = {
  'messier': "",
  'ngc': "",
  'string': "",
  'date': null,
  'onlySearch': false,
  'selectedTab': 0,
};

/// Filter buttons
class ObservationTabBar extends StatefulWidget {
  /// Callback to register when filter options change
  final void Function() callback;

  /// Filter buttons
  ObservationTabBar(this.callback);

  _ObservationTabBarState createState() => _ObservationTabBarState();
}

class _ObservationTabBarState extends State<ObservationTabBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ButtonBar(
          buttonPadding: EdgeInsets.all(0),
          children: [
            IconButton(
              padding: EdgeInsets.symmetric(vertical: 8),
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() => searchState['selectedTab'] == 0
                    ? searchState['selectedTab'] = -1
                    : searchState['selectedTab'] = 0);
                widget.callback();
              },
            ),
            IconButton(
              padding: EdgeInsets.symmetric(vertical: 8),
              icon: Icon(searchState['onlySearch']
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined),
              onPressed: () {
                setState(() {
                  searchState['onlySearch'] = !searchState['onlySearch'];
                  searchState['selectedTab'] = 1;
                });
                widget.callback();
              },
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () => selectedTiles.isNotEmpty
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GeneratePDF(selectedTiles)))
                  : showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("No observations selected!"),
                      ),
                    ),
            ),
          ],
        ),
        searchState['selectedTab'] == 0
            ? SearchFilterRow(widget.callback)
            : SizedBox(),
      ],
    );
  }

/*
  Widget build_(BuildContext context) {
    return DefaultTabController(
      length: _tabNames.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: _tabNames
                .map(
                  (tab) => Tab(
                    // child: Text(tab.name),
                    child: tab.icon,
                  ),
                )
                .toList(),
          ),
          Container(
            // padding: EdgeInsets.symmetric(vertical: 0),
            constraints: BoxConstraints.expand(height: 60),
            child: TabBarView(
              children:
                  _tabNames.map((tab) => tab.display).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
*/
}

class SearchFilterRow extends StatefulWidget {
  final void Function() callback;

  _SearchFilterRowState createState() => _SearchFilterRowState();
  SearchFilterRow(this.callback, {Key? key}) : super(key: key);

  // String get ngc => _searchState['ngc'];
  // String get messier => _searchState['messier'];
  // String get stringSearch => _searchState['string'];
  // DateTimeRange get dateRange => _searchState['date'];
}

class _SearchFilterRowState extends State<SearchFilterRow> {
  final ngcSearchController = TextEditingController();
  final messierSearchController = TextEditingController();
  final stringSearchController = TextEditingController();
  final dateSearchController = TextEditingController();
  DateTimeRange? dateSearchRange;
  bool clickOnClear = false;

  void _updateNGC() => searchState['ngc'] = ngcSearchController.text;
  void _updateMessier() =>
      searchState['messier'] = messierSearchController.text;
  void _updateStringSearch() =>
      searchState['string'] = stringSearchController.text;
  void _updateDateRange() => searchState['date'] = dateSearchRange;

  @override
  void initState() {
    super.initState();
    ngcSearchController.addListener(_updateNGC);
    messierSearchController.addListener(_updateMessier);
    stringSearchController.addListener(_updateStringSearch);
    dateSearchController.addListener(_updateDateRange);
  }

  @override
  void dispose() {
    ngcSearchController.removeListener(_updateNGC);
    messierSearchController.removeListener(_updateMessier);
    stringSearchController.removeListener(_updateStringSearch);
    dateSearchController.removeListener(_updateDateRange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.all(0),
      child: Row(
        children: [
          Container(
            width: 100,
            child: TextField(
              controller: messierSearchController,
              keyboardType: TextInputType.numberWithOptions(
                  decimal: false, signed: false),
              decoration: InputDecoration(
                // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                labelText: "Messier#",
                isDense: true,
                suffix: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: 20,
                  icon: Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() => messierSearchController.clear());
                    widget.callback();

                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {});
                widget.callback();
                Future.delayed(
                    Duration(seconds: 2), FocusScope.of(context).unfocus);
              },
            ),
          ),
          Container(
            width: 100,
            child: TextField(
              controller: ngcSearchController,
              keyboardType: TextInputType.numberWithOptions(
                  decimal: false, signed: false),
              decoration: InputDecoration(
                // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                labelText: "NGC#",
                isDense: true,
                suffix: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: 20,
                  icon: Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() => ngcSearchController.clear());
                    widget.callback();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {});
                widget.callback();
                Future.delayed(
                    Duration(seconds: 2), FocusScope.of(context).unfocus);
              },
            ),
          ),
          Expanded(
            child: TextField(
              controller: dateSearchController,
              keyboardType: TextInputType.datetime,
              readOnly: true,
              decoration: InputDecoration(
                // prefixIcon: Icon(Icons.search_rounded, color: Colors.red),
                labelText: "Date Range",
                isDense: true,
                suffix: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: 20,
                  icon: Icon(Icons.clear_rounded),
                  onPressed: () => setState(() {
                    clickOnClear = true;
                    dateSearchController.clear();
                    dateSearchRange = null;
                    widget.callback();
                    FocusScope.of(context).unfocus();
                  }),
                ),
              ),
              onChanged: (value) => setState(() {}),
              onTap: () async {
                if (clickOnClear) {
                  clickOnClear = false;
                  return;
                }
                dateSearchRange = await showDateRangePicker(
                  context: context,
                  initialDateRange: dateSearchRange ?? null,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  fieldStartLabelText: "From date",
                  fieldEndLabelText: "End date",
                );
                if (dateSearchRange != null)
                  setState(() => dateSearchController.text =
                      dateSearchRange!.start.yMMMd +
                          " - " +
                          dateSearchRange!.end.yMMMd);
                else
                  setState(() => dateSearchController.clear());
                widget.callback();
              },
            ),
          ),
        ],
      ),
    );
  }
}
