import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_connect/app/theme/app_colors.dart';
import 'package:campus_connect/core/utils/helpers.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => _initials(),
            errorWidget: (context, url, error) => _initials(),
          )
        : _initials();

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Widget _initials() {
    final initials = AppHelpers.getInitials(name);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentPurple,
      AppColors.accentGreen,
      AppColors.accentOrange,
    ];
    final colorIndex = name.trim().isEmpty ? 0 : name.trim().codeUnits.first;
    final color = backgroundColor ?? colors[colorIndex % colors.length];

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OnlineIndicatorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool isOnline;

  const OnlineIndicatorAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AvatarWidget(imageUrl: imageUrl, name: name, radius: radius),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
