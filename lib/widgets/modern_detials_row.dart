import 'package:flutter/material.dart';

class ModernDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ModernDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
