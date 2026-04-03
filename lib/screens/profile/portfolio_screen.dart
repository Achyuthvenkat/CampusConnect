import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class PortfolioScreen extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;

  const PortfolioScreen({
    super.key,
    required this.user,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (user.portfolioUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No portfolio items yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            if (isOwnProfile) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addPortfolioItem(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: user.portfolioUrls.length +
          (isOwnProfile &&
                  user.portfolioUrls.length < AppConstants.maxPortfolioItems
              ? 1
              : 0),
      itemBuilder: (context, i) {
        if (i == user.portfolioUrls.length && isOwnProfile) {
          return GestureDetector(
            onTap: () => _addPortfolioItem(context),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.primaryColor, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 36, color: AppTheme.primaryColor),
                  SizedBox(height: 8),
                  Text(
                    'Add Item',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          );
        }

        final url = user.portfolioUrls[i];
        return GestureDetector(
          onLongPress: isOwnProfile
              ? () => _confirmDelete(context, url)
              : null,
          onTap: () => _viewImage(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addPortfolioItem(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    if (!context.mounted) return;

    final authProvider = context.read<app_auth.AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final uid = authProvider.currentUser?.uid ?? '';

    await userProvider.addPortfolioItem(uid, File(image.path));
  }

  Future<void> _confirmDelete(BuildContext context, String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content:
            const Text('Remove this item from your portfolio?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<app_auth.AuthProvider>();
      final userProvider = context.read<UserProvider>();
      await userProvider.removePortfolioItem(
          authProvider.currentUser?.uid ?? '', url);
    }
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
