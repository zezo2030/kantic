import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../cubit/notifications_cubit.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/routes/app_route_generator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsCubit>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded &&
                  state.notifications.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'mark_all_read'.tr(),
                  onPressed: () {
                    context.read<NotificationsCubit>().markAllAsRead();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationsCubit>().loadNotifications();
                    },
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<NotificationsCubit>().loadNotifications();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () {
                      context.read<NotificationsCubit>().markAsRead(
                        notification.id,
                      );
                      _handleNotificationTap(context, notification);
                    },
                    onDismiss: () {
                      context.read<NotificationsCubit>().deleteNotification(
                        notification.id,
                      );
                    },
                  );
                },
              ),
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.notification_bing, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_notifications'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_notifications_desc'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Navigate based on notification type
    switch (notification.type) {
      case 'booking':
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_REMINDER':
      case 'BOOKING_END':
      case 'BOOKING_CANCELLED':
      case 'TICKETS_ISSUED':
      case 'RATING_REQUEST':
        // Navigate to booking details
        final bookingId = notification.data?['bookingId'];
        if (bookingId != null) {
          Navigator.pushNamed(
            context,
            '/booking-details',
            arguments: bookingId,
          );
        }
        break;
      case 'trip':
      case 'TRIP_STATUS':
        // Navigate to trip details
        final tripId = notification.data?['tripId'];
        if (tripId != null) {
          Navigator.pushNamed(
            context,
            '/school-trips/details',
            arguments: tripId,
          );
        }
        break;
      case 'offer':
      case 'PROMO':
        Navigator.pushNamed(context, AppRoutes.offers);
        break;
      case 'SUBSCRIPTION_PURCHASE_SUCCESS':
        final purchaseId = notification.data?['subscriptionPurchaseId'] ??
            notification.data?['purchaseId'];
        if (purchaseId != null && purchaseId.toString().isNotEmpty) {
          Navigator.pushNamed(
            context,
            AppRoutes.subscriptionDetails,
            arguments: {'purchaseId': purchaseId.toString()},
          );
        } else {
          Navigator.pushNamed(context, AppRoutes.mySubscriptions);
        }
        break;
      case 'OFFER_PURCHASE_SUCCESS':
        final bookingId = notification.data?['offerBookingId'] ??
            notification.data?['bookingId'];
        if (bookingId != null && bookingId.toString().isNotEmpty) {
          Navigator.pushNamed(
            context,
            AppRoutes.offerBookingDetails,
            arguments: {'bookingId': bookingId.toString()},
          );
        } else {
          Navigator.pushNamed(context, AppRoutes.myOfferBookings);
        }
        break;
      default:
        // Show notification details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ],
          ),
        );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIconColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(notification.type),
                      color: _getIconColor(notification.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.timestamp),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking':
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_REMINDER':
      case 'BOOKING_END':
      case 'BOOKING_CANCELLED':
      case 'TICKETS_ISSUED':
      case 'RATING_REQUEST':
        return Iconsax.calendar_tick;
      case 'offer':
      case 'PROMO':
        return Iconsax.tag;
      case 'trip':
      case 'TRIP_STATUS':
        return Iconsax.bus;
      case 'PAYMENT_SUCCESS':
      case 'WALLET_RECHARGED':
        return Iconsax.wallet_2;
      case 'EVENT_STATUS':
        return Iconsax.calendar_1;
      default:
        return Iconsax.notification;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'booking':
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_REMINDER':
      case 'BOOKING_END':
      case 'BOOKING_CANCELLED':
      case 'TICKETS_ISSUED':
      case 'RATING_REQUEST':
        return const Color(0xFF4CAF50);
      case 'offer':
      case 'PROMO':
        return const Color(0xFFFF9100);
      case 'trip':
      case 'TRIP_STATUS':
        return const Color(0xFF2196F3);
      case 'PAYMENT_SUCCESS':
      case 'WALLET_RECHARGED':
        return const Color(0xFF673AB7);
      case 'EVENT_STATUS':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${'minutes_ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${'hours_ago'.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days_ago'.tr()}';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
