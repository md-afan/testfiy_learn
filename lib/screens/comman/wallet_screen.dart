import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:testify_learn_application/constants/app_routes.dart';
import '../../widgets/sticky_widget.dart';
import "../../widgets/transecction_tile.dart";
import '../../utils/helpers.dart';
import '../../providers/comman providers/wallets_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/global_shimmer_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.userId == null) {
          return const Scaffold(
            body: Center(child: Text('Please login to access wallet.')),
          );
        }

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(context, "Wallet"),
          body: RefreshIndicator(
            onRefresh: provider.refreshTransactions,
            child: CustomScrollView(
              controller: _scrollController(context, provider),
              slivers: [
                // Wallet balance shimmer
                SliverToBoxAdapter(
                  child: GlobalShimmerScreen(
                    isLoading: provider.isLoadingTransactions,
                    child: _walletHeaderCard(provider, context),
                  ),
                ),

                // Filter chips shimmer
                StickyTopPositioned(
                  child: GlobalShimmerScreen(
                    isLoading: provider.isLoadingTransactions,
                    child: _buildFilterChips(provider),
                  ),
                ),

                // Title shimmer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlobalShimmerScreen(
                      isLoading: provider.isLoadingTransactions,
                      child: Text(
                        "Transaction History",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                // Transactions shimmer list
                provider.isLoadingTransactions
                    ? _buildTransactionShimmerList()
                    : _buildTransactionList(provider),

                if (provider.isLoadingMore)
                  const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator())),

                if (!provider.hasMoreTransactions &&
                    provider.allTransactions.isNotEmpty)
                  const SliverToBoxAdapter(
                      child: Center(child: Text("No more transactions"))),
              ],
            ),
          ),
        );
      },
    );
  }

  ScrollController _scrollController(
      BuildContext context, WalletProvider provider) {
    final controller = ScrollController();
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        provider.loadMoreTransactions();
      }
    });
    return controller;
  }

  Widget _walletHeaderCard(WalletProvider provider, BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B61FF), Color(0xFF9C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Balance",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "₹${provider.balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.addMoney);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Money"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.widthrawal);
                    },
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text("Withdraw Money"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(WalletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(provider.filters.length, (index) {
            final isSelected = provider.selectedFilter == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(provider.filters[index]),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                labelStyle:
                    TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (_) => provider.changeFilter(index),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTransactionList(WalletProvider provider) {
    if (provider.filteredTransactions.isEmpty) {
      return const SliverToBoxAdapter(
          child: Center(child: Text("No transactions found.")));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final data = provider.filteredTransactions[index].data()
              as Map<String, dynamic>;
          final date = DateFormat('dd MMM yyyy')
              .format((data['createdAt'] as Timestamp).toDate());
          final amount = (data['amount'] ?? 0.0).toStringAsFixed(2);
          return TransactionTile(
            title: data['type'] ?? 'Unknown',
            date: date,
            amount: "₹$amount",
            status: data['status'] ?? 'Unknown',
          );
        },
        childCount: provider.filteredTransactions.length,
      ),
    );
  }

  Widget _buildTransactionShimmerList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return GlobalShimmerScreen(
            isLoading: true,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                color: Colors.white,
              ),
              title: Container(
                width: double.infinity,
                height: 14,
                color: Colors.white,
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                color: Colors.white,
              ),
              trailing: Container(
                width: 50,
                height: 14,
                color: Colors.white,
              ),
            ),
          );
        },
        childCount: 6,
      ),
    );
  }
}
