import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TestCard extends StatefulWidget {
  final String title;
  final String subTitle;
  final String? bottomTitle;
  final IconData? icon;
  final String? imagesUrl;
  final VoidCallback onTap;

  const TestCard({
    super.key,
    required this.title,
    required this.subTitle,
    this.bottomTitle,
    this.icon,
    this.imagesUrl,
    required this.onTap,
  });

  @override
  State<TestCard> createState() => _TestCardState();
}

class _TestCardState extends State<TestCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color iconBgColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              // Avatar or Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: ClipOval(
                  child: widget.imagesUrl != null &&
                          widget.imagesUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.imagesUrl!,
                          height: 44,
                          width: 44,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 44,
                            width: 44,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            backgroundColor: iconBgColor,
                            radius: 22,
                            child: Icon(
                              widget.icon ?? Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: iconBgColor,
                          radius: 22,
                          child: Icon(
                            widget.icon ?? Icons.description,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.subTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (widget.bottomTitle != null)
                      Text(
                        widget.bottomTitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow Icon
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1.0 : 0.5,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
