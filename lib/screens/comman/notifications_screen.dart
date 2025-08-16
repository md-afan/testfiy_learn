import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../providers/comman providers/notification_provider.dart';
import '../../widgets/global_shimmer_screen.dart';

class NotificationScreen extends StatelessWidget {
  final String role; // 'students' or 'teachers'
  const NotificationScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.userId.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(
            context,
            "Notifications",
            automaticallyImplyLeading: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onSelected: provider.changeFilter,
                itemBuilder: (context) => provider.filters
                    .map((type) => PopupMenuItem<String>(
                          value: type,
                          child: Text(
                            type == 'All'
                                ? 'All Notifications'
                                : provider.capitalize(type.replaceAll('_', ' ')),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: provider.realTimeNotifications,
            builder: (context, snapshot) {
              bool isLoading = !snapshot.hasData && provider.olderNotifications.isEmpty;

              // ✅ Show shimmer while loading
              if (isLoading) {
                return GlobalShimmerScreen(
                  isLoading: true,
                  itemCount: 8,
                  height: 70,
                  child: ListView.builder(
                    itemCount: 8,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (_, __) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 70,
                    ),
                  ),
                );
              }

              final realTimeDocs = snapshot.data?.docs ?? [];
              final allNotifications = [
                ...realTimeDocs,
                ...provider.olderNotifications
              ];

              if (allNotifications.isEmpty) {
                return const Center(child: Text("No notifications yet."));
              }

              return ListView.builder(
                itemCount: allNotifications.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == allNotifications.length) {
                    provider.loadMoreNotifications(role);
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final doc = allNotifications[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'] as Timestamp?;
                  final timeAgo =
                      ts != null ? provider.formatTimeAgo(ts.toDate()) : '';

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await provider.deleteNotification(doc);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Notification deleted")),
                      );
                    },
                    child: ListTile(
                      leading: Icon(
                        provider.getIconForType(data['type'] ?? ''),
                        color: (data['isRead'] ?? false)
                            ? Colors.grey
                            : Colors.deepPurple,
                      ),
                      title: Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          fontWeight: (data['isRead'] ?? false)
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(data['body'] ?? ''),
                      trailing:
                          Text(timeAgo, style: const TextStyle(fontSize: 12)),
                      onTap: () => provider.markAsRead(doc),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
