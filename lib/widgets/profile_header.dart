import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  final String? coverImageUrl;
  final String? profileImageUrl;
  final String name;
  final String email;
 

  const ProfileHeader({
    super.key,
    this.coverImageUrl,
    this.profileImageUrl,
    required this.name,
    required this.email,
   
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image with caching
        coverImageUrl != null && coverImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: theme.colorScheme.primaryContainer),
                errorWidget: (context, url, error) =>
                    Container(color: theme.colorScheme.primaryContainer),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

        // Dark overlay
        Container(color: Colors.black.withOpacity(0.3)),

        // Profile image and text
        Positioned(
          left: 16,
          bottom: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile image with caching
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color:theme.colorScheme.surface,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                              'assets/images/default_user.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover),
                        )
                      : Image.asset(
                          'assets/images/default_user.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
