import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;

  const OptimizedImage({super.key, this.imagePath, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) return const SizedBox();

    return CachedNetworkImage(
      imageUrl: imagePath!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}
