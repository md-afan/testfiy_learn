import 'package:flutter/material.dart';
import './global_shimmer_screen.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String? status;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(date, style: const TextStyle(color: Colors.grey)),
                if (status != null)
                  Text(
                    status!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status == "panding"
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class TransecctionTileShimmer extends StatelessWidget {
  final int count; // number of shimmer cards

  const TransecctionTileShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return GlobalShimmerScreen(
            isLoading: true,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: theme.surface),
              ),
              title: Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.surface),
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.surface),
              ),
              trailing: Container(
                width: 50,
                height: 14,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: theme.surface),
              ),
            ),
          );
        },
        childCount: count,
      ),
    );
  }
}
