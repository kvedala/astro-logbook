import 'package:flutter/material.dart';
import '../models/observation_data.dart';

class ObservationCard extends StatelessWidget {
  final ObservationData observation;
  final VoidCallback? onTap;
  final bool isSelected;

  const ObservationCard({
    super.key,
    required this.observation,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 8),
              _buildDateTime(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      observation.title ?? 'Untitled',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle() {
    final List<String> subtitles = [];
    if (observation.messier != null) subtitles.add('M${observation.messier}');
    if (observation.ngc != null) subtitles.add('NGC ${observation.ngc}');
    return Text(subtitles.join(' • '), style: const TextStyle(fontSize: 14));
  }

  Widget _buildDateTime() {
    return Text(
      observation.dateTime?.toString() ?? '',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }
}
