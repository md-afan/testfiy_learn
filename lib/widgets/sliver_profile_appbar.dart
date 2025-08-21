import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SliverProfileAppBar extends StatelessWidget {
  final String title;
  final double expandedHeight;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String name;
  final String email;
  final VoidCallback? onCoverImageTap;
  final VoidCallback? onProfileImageTap;
  final bool isUploadingImage;
  final bool isUploadingCoverImages;
  final bool showBackButton;
  final List<Widget>? actions;

  const SliverProfileAppBar({
    super.key,
    required this.title,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.coverImageUrl,
    this.onCoverImageTap,
    this.onProfileImageTap,
    this.isUploadingImage = false,
    this.isUploadingCoverImages = false,
    this.expandedHeight = 230,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      centerTitle: false,
      backgroundColor: colorScheme.primary,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildCoverImage(colorScheme),
            // Profile section
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildProfileImage(colorScheme),
                  const SizedBox(width: 16),
                  // Name & Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: themeData.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: themeData.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cover Image with overlay + upload state
  Widget _buildCoverImage(ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        coverImageUrl != null && coverImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: colorScheme.primaryContainer),
                errorWidget: (_, __, ___) =>
                    Container(color: colorScheme.primaryContainer),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

        // Dark overlay
        Container(color: Colors.black.withOpacity(0.4)),

        // Uploading cover overlay
        if (isUploadingCoverImages)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ),

        // Tap button for cover image
        if (onCoverImageTap != null)
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: onCoverImageTap,
              child: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.photo_camera, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  /// Profile Image with overlay + upload state
  Widget _buildProfileImage(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.surface,
          child: ClipOval(
            child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profileImageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: colorScheme.surfaceVariant),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/default_user.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/default_user.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
        ),

        // Camera icon
        if (onProfileImageTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onProfileImageTap,
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),

        // Uploading overlay
        if (isUploadingImage)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
    );
  }
}
