import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/seekhub_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/seekhub_provider.dart';

class SeekHubScreen extends ConsumerWidget {
  const SeekHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(seekHubRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: size.height * 0.15,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.volunteer_activism,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'SeekHub',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF1F1FA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 52),
                      child: Text(
                        'Request resources from fellow students',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xCCF1F1FA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : const Color(0xFFF1F1FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: requestsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: TextStyle(color: context.faintText)),
                  ),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 24),
                              Text(
                                'No resource requests yet.\nBe the first to request study materials!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: context.faintText,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return _RequestCard(
                          request: requests[index],
                          onSubscribe: () =>
                              _toggleSubscription(ref, requests[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seekhub/create'),
        backgroundColor: AppTheme.tertiaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Request',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _toggleSubscription(
      WidgetRef ref, SeekHubRequestModel request) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final service = ref.read(seekHubServiceProvider);
    final isSubscribed = request.notifyList.contains(user.uid);

    if (isSubscribed) {
      await service.unsubscribeFromRequest(
        university: request.university,
        course: request.course,
        requestId: request.id,
        uid: user.uid,
      );
    } else {
      await service.subscribeToRequest(
        university: request.university,
        course: request.course,
        requestId: request.id,
        uid: user.uid,
      );
    }
  }
}

class _RequestCard extends ConsumerWidget {
  final SeekHubRequestModel request;
  final VoidCallback onSubscribe;

  const _RequestCard({
    required this.request,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isSubscribed =
        user != null && request.notifyList.contains(user.uid);
    final isOwnRequest = user?.uid == request.seekerUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: request.isFulfilled
            ? Border.all(color: const Color(0xFF5CB85C), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Seeker avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: request.seekerPhoto != null
                    ? NetworkImage(request.seekerPhoto!)
                    : null,
                child: request.seekerPhoto == null
                    ? Text(
                        request.seekerName.isNotEmpty
                            ? request.seekerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.seekerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                      ),
                    ),
                    Text(
                      '${request.branch} | Sem ${request.sem}',
                      style: TextStyle(
                          fontSize: 12, color: context.faintText),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: request.isFulfilled
                      ? const Color(0xFF5CB85C).withValues(alpha: 0.15)
                      : const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.isFulfilled ? 'Fulfilled' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: request.isFulfilled
                        ? const Color(0xFF5CB85C)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subject & Category
          Text(
            request.subject,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF161719),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.category,
            style: TextStyle(fontSize: 14, color: context.faintText),
          ),

          const SizedBox(height: 12),

          // Subscribe / Notification bell
          if (!isOwnRequest && request.isPending)
            GestureDetector(
              onTap: onSubscribe,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSubscribed
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    size: 18,
                    color: isSubscribed
                        ? AppTheme.primaryColor
                        : context.faintText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSubscribed ? 'Subscribed' : 'Notify me',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSubscribed
                          ? AppTheme.primaryColor
                          : context.faintText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
