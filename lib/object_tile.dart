import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'services/tonight_service.dart';

class ObjectTile extends StatelessWidget {
  final String name;
  final String title;
  final String details;
  final String visibilityLabel;
  final TargetVisibility? visibility;
  final bool visibilityKnown;
  final bool? viewed;
  final VoidCallback onOpenObject;
  final VoidCallback? onOpenObservations;

  const ObjectTile({
    super.key,
    required this.name,
    required this.title,
    required this.details,
    required this.visibilityLabel,
    required this.visibility,
    this.visibilityKnown = true,
    required this.viewed,
    required this.onOpenObject,
    required this.onOpenObservations,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenObject,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Open $name on Wikipedia',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: onOpenObject,
                ),
                IconButton(
                  tooltip: 'Visibility details: $visibilityLabel',
                  icon: Icon(
                    !visibilityKnown
                        ? Icons.help_outline
                        : visibility == null
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    final time = DateFormat('EEE HH:mm');
                    final result = visibility;
                    final summary = result == null
                        ? visibilityLabel
                        : '$visibilityLabel\n'
                              'Visible in darkness: ${result.intervals.map((i) => '${time.format(i.start)}–${time.format(i.end)}').join(', ')}\n'
                              'Best ${time.format(result.bestTime)} · ${result.altitudeDegrees.round()}° high'
                              '${result.moonUp ? '\nMoon up at best time' : ''}';
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('$name visibility'),
                        content: SingleChildScrollView(
                          child: Text(
                            '$summary\n\nVisibility means above the horizon during astronomical darkness. Weather, moonlight and local conditions also matter.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: viewed == null
                      ? 'Observation status loading or unavailable'
                      : viewed!
                      ? 'Observed: View observations'
                      : 'Not observed: Add observation',
                  icon: Icon(
                    viewed == null
                        ? Icons.help_outline
                        : viewed!
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                  ),
                  onPressed: viewed == null ? null : onOpenObservations,
                ),
              ],
            ),
            if (details.isNotEmpty)
              Text(details, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
