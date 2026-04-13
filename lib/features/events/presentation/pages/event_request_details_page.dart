// Event Request Details Page - Presentation Layer
import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../../booking/presentation/widgets/modern_ticket_widget.dart';
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../domain/entities/event_request_entity.dart';
import '../../domain/entities/event_request_status.dart';
import '../cubit/event_request_cubit.dart';
import '../cubit/event_request_state.dart';
import '../widgets/event_request_status_badge.dart';

class _EventRequestDetailsHelper {
  static String getEventTypeTranslation(String type) {
    switch (type) {
      case 'birthday':
        return 'event_type_birthday'.tr();
      case 'graduation':
        return 'event_type_graduation'.tr();
      case 'family':
        return 'event_type_family'.tr();
      case 'corporate':
        return 'event_type_corporate'.tr();
      case 'wedding':
        return 'event_type_wedding'.tr();
      case 'other':
        return 'event_type_other'.tr();
      default:
        return type;
    }
  }
}

class EventRequestDetailsPage extends StatefulWidget {
  final String requestId;

  const EventRequestDetailsPage({super.key, required this.requestId});

  @override
  State<EventRequestDetailsPage> createState() =>
      _EventRequestDetailsPageState();
}

class _EventRequestDetailsPageState extends State<EventRequestDetailsPage>
    with WidgetsBindingObserver {
  Timer? _paymentStatusTimer;
  List<Map<String, dynamic>> _tickets = [];
  bool _loadingTickets = false;
  String? _lastLoadedRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentStatusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh request details when app resumes (e.g. returning from payment)
      context.read<EventRequestCubit>().getRequest(widget.requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EventRequestCubit>()..getRequest(widget.requestId),
      child: Scaffold(
        appBar: AppBar(title: Text('event_request_details_title'.tr())),
        body: BlocBuilder<EventRequestCubit, EventRequestState>(
          builder: (context, state) {
            if (state is EventRequestDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EventRequestDetailError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<EventRequestCubit>().getRequest(
                          widget.requestId,
                        );
                      },
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            if (state is EventRequestDetailLoaded) {
              // Load tickets if event is paid or confirmed
              if ((state.request.status == EventRequestStatus.paid ||
                   state.request.status == EventRequestStatus.confirmed) &&
                  !_loadingTickets &&
                  _lastLoadedRequestId != state.request.id) {
                // Use post-frame callback to avoid calling setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _lastLoadedRequestId != state.request.id) {
                    _loadTickets(context, state.request.id);
                  }
                });
              }
              return _buildDetails(context, state.request);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _loadTickets(BuildContext context, String eventRequestId) async {
    if (_lastLoadedRequestId == eventRequestId) return;
    
    setState(() {
      _loadingTickets = true;
      _lastLoadedRequestId = eventRequestId;
    });

    try {
      final cubit = context.read<EventRequestCubit>();
      final tickets = await cubit.getEventTickets(eventRequestId);
      if (mounted && _lastLoadedRequestId == eventRequestId) {
        setState(() {
          _tickets = tickets;
          _loadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted && _lastLoadedRequestId == eventRequestId) {
        setState(() {
          _loadingTickets = false;
        });
      }
    }
  }

  Widget _buildDetails(BuildContext context, EventRequestEntity request) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'status'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  EventRequestStatusBadge(status: request.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Basic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.information,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'event_request_info'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'event_type'.tr(),
                    _EventRequestDetailsHelper.getEventTypeTranslation(
                      request.type,
                    ),
                    Iconsax.calendar,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'date_time'.tr(),
                    dateFormat.format(request.startTime.toLocal()),
                    Iconsax.calendar_1,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'duration'.tr(),
                    'duration_hours_value'.tr(
                      args: [request.durationHours.toString()],
                    ),
                    Iconsax.timer,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'persons_count'.tr(),
                    'persons_count_value'.tr(args: [request.persons.toString()]),
                    Iconsax.people,
                  ),
                  if (request.hallId != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'hall'.tr(),
                      request.hallId!,
                      Iconsax.home,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'decorated'.tr(),
                    request.decorated ? 'yes'.tr() : 'no'.tr(),
                    Iconsax.magic_star,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price Card (if quoted)
          if (request.quotedPrice != null)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Iconsax.money_recive, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'quoted_price'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${request.quotedPrice!.toStringAsFixed(2)} ${'currency'.tr()}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (request.quotedPrice != null) const SizedBox(height: 16),

          // Notes Card (if exists)
          if (request.notes != null && request.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.note, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'notes'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(request.notes!),
                  ],
                ),
              ),
            ),
          if (request.notes != null && request.notes!.isNotEmpty)
            const SizedBox(height: 16),

          // Add-ons Card (if exists)
          if (request.addOns != null && request.addOns!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.box, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'add_ons'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...request.addOns!.map((addon) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${addon['name'] ?? ''} (${addon['quantity'] ?? 1}x)',
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          if (request.addOns != null && request.addOns!.isNotEmpty)
            const SizedBox(height: 16),

          // Tickets Card (if exists)
          if (_tickets.isNotEmpty) ...[
            _buildTicketsCard(context, request),
            const SizedBox(height: 16),
          ],

          // Action Buttons based on status
          _buildActionButtons(context, request),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EventRequestEntity request) {
    final theme = Theme.of(context);

    // Show payment button if quoted
    if (request.status == EventRequestStatus.quoted &&
        request.quotedPrice != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFFF5CAB), Color(0xFFFF6A00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showPaymentMethodDialog(context, request);
                },
                icon: const Icon(Iconsax.wallet_3, color: Colors.white),
                label: Text(
                  'pay_now'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Open contact dialog or navigate to contact page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('contact_us_phone'.tr()),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Iconsax.call, size: 20),
              label: Text(
                'contact_us'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(
                  color: AppColors.luxuryBorderRose,
                  width: 2.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show waiting message if paid
    if (request.status == EventRequestStatus.paid) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Iconsax.clock, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'waiting_confirmation'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'payment_received_wait_confirm'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show confirmed message if confirmed
    if (request.status == EventRequestStatus.confirmed) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Iconsax.tick_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'confirmed'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'event_confirmed_success'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show rejected message if rejected
    if (request.status == EventRequestStatus.rejected) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Iconsax.close_circle, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'request_rejected'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'request_rejected_create_new'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show waiting message for other statuses
    if (request.status == EventRequestStatus.submitted ||
        request.status == EventRequestStatus.underReview) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Iconsax.clock, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'under_review'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'request_under_review_quote_soon'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTicketsCard(BuildContext context, EventRequestEntity request) {
    final theme = Theme.of(context);
    final ticketsDataSource = TicketsRemoteDataSourceImpl(dio: DioClient.instance);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Iconsax.ticket, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'tickets'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_loadingTickets)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ..._tickets.asMap().entries.map((entry) {
            final index = entry.key;
            final ticket = entry.value;
            final ticketId = ticket['id']?.toString() ?? '';
            final status = ticket['status']?.toString().toLowerCase() ?? 'valid';
            final validFrom = ticket['validFrom'] != null
                ? DateTime.tryParse(ticket['validFrom'].toString())
                : null;
            final validUntil = ticket['validUntil'] != null
                ? DateTime.tryParse(ticket['validUntil'].toString())
                : null;
            final createdAt = ticket['createdAt'] != null
                ? DateTime.tryParse(ticket['createdAt'].toString())
                : null;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ModernTicketWidget(
                ticketId: ticketId,
                status: status,
                personNumber: index + 1,
                totalPersons: _tickets.length,
                validFrom: validFrom,
                validUntil: validUntil,
                createdAt: createdAt,
                onViewQr: () async {
                  try {
                    final qr = await ticketsDataSource.getTicketQr(ticketId);
                    if (!mounted) return;
                    
                    showDialog(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'qr_code'.tr(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (qr.startsWith('data:image'))
                                  Image.memory(
                                    base64Decode(qr.split(',').last),
                                  )
                                else
                                  SelectableText(
                                    qr,
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        HapticFeedback.selectionClick();
                                        await shareTicketQrPreferWhatsApp(
                                          context: context,
                                          ticketId: ticketId,
                                          qrData: qr,
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${'error'.tr()}: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Iconsax.share),
                                    label: Text('share'.tr()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text('close'.tr()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'qr_load_error'.tr(args: [e.toString()]),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onCopyId: () async {
                  await Clipboard.setData(ClipboardData(text: ticketId));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ticket_id_copied'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onShare: () async {
                  try {
                    final qr = await ticketsDataSource.getTicketQr(ticketId);
                    if (!mounted) return;
                    await shareTicketQrPreferWhatsApp(
                      context: context,
                      ticketId: ticketId,
                      qrData: qr,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${'error'.tr()}: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  void _showPaymentMethodDialog(
    BuildContext context,
    EventRequestEntity request,
  ) {
    if (request.quotedPrice == null) return;

    final authState = context.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    final walletBalance = user?.wallet?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= request.quotedPrice!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_payment_method'.tr()),
        content: BlocProvider(
          create: (_) {
            final cubit = GetIt.instance<WalletCubit>();
            if (cubit.state is WalletInitial) {
              cubit.loadWallet();
            }
            return cubit;
          },
          child: BlocBuilder<WalletCubit, WalletState>(
            builder: (context, walletState) {
              double currentBalance = walletBalance;
              bool currentHasEnoughBalance = hasEnoughBalance;

              if (walletState is WalletLoaded) {
                currentBalance = walletState.wallet.balance;
                currentHasEnoughBalance =
                    currentBalance >= request.quotedPrice!;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Credit Card / Visa / Mastercard
                  ListTile(
                    leading: const Icon(Iconsax.card, color: Colors.blue),
                    title: Text('credit_card'.tr()),
                    subtitle: Text('visa_mastercard'.tr()),
                    trailing: const Icon(Iconsax.arrow_left_2),
                    onTap: () {
                      Navigator.pop(context);
                      _processPayment(context, request, 'credit_card');
                    },
                  ),
                  const Divider(),
                  // Mada (مدى)
                  ListTile(
                    leading: const Icon(Iconsax.card, color: Colors.green),
                    title: Text('mada'.tr()),
                    subtitle: Text('mada_card'.tr()),
                    trailing: const Icon(Iconsax.arrow_left_2),
                    onTap: () {
                      Navigator.pop(context);
                      _processPayment(context, request, 'mada');
                    },
                  ),
                  const Divider(),
                  // Wallet
                  ListTile(
                    leading: const Icon(Iconsax.wallet_3, color: Colors.green),
                    title: Text('pay_with_wallet'.tr()),
                    subtitle: currentHasEnoughBalance
                        ? Text(
                            '${'wallet_balance'.tr()}: ${currentBalance.toStringAsFixed(2)} ${'currency'.tr()}',
                          )
                        : Text(
                            'insufficient_balance'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                    trailing: currentHasEnoughBalance
                        ? const Icon(Iconsax.arrow_left_2)
                        : const Icon(Iconsax.info_circle, color: Colors.red),
                    enabled: currentHasEnoughBalance,
                    onTap: currentHasEnoughBalance
                        ? () {
                            Navigator.pop(context);
                            _processPayment(context, request, 'wallet');
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );

    // Load wallet balance if needed
    if (GetIt.instance<WalletCubit>().state is WalletInitial) {
      GetIt.instance<WalletCubit>().loadWallet();
    }
  }

  void _processPayment(
    BuildContext context,
    EventRequestEntity request,
    String method,
  ) {
    try {
      payments_di.initPayments();
    } catch (_) {}

    final paymentCubit = payments_di.sl<PaymentCubit>();
    final pageContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: paymentCubit,
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (dialogContext, state) async {
            if (state is PaymentIntentCreated) {
              Navigator.pop(dialogContext); // Close loading dialog

              if (pageContext.mounted) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'complete_payment_open_page'.tr(),
                    ),
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.blue,
                    action: SnackBarAction(
                      label: 'verify_status'.tr(),
                      textColor: Colors.white,
                      onPressed: () {
                        paymentCubit.checkPaymentStatus(
                          eventRequestId: request.id,
                          paymentId: state.intent.paymentId,
                          chargeId: state.intent.chargeId,
                        );
                      },
                    ),
                  ),
                );

                // Polling
                _paymentStatusTimer?.cancel();
                _paymentStatusTimer = Timer.periodic(
                  const Duration(seconds: 10),
                  (timer) async {
                    if (!pageContext.mounted) {
                      timer.cancel();
                      return;
                    }

                    paymentCubit.checkPaymentStatus(
                      eventRequestId: request.id,
                      paymentId: state.intent.paymentId,
                      chargeId: state.intent.chargeId,
                    );

                    if (timer.tick >= 30) {
                      timer.cancel();
                      _paymentStatusTimer = null;
                    }
                  },
                );
              }
            } else if (state is PaymentSuccess) {
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              Navigator.pop(dialogContext); // Close loading dialog

              if (pageContext.mounted) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text('payment_success'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh request
                pageContext.read<EventRequestCubit>().getRequest(request.id);
              }
            } else if (state is PaymentFailure) {
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              Navigator.pop(dialogContext); // Close loading dialog
              if (pageContext.mounted) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('processing'.tr()),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Process payment
    paymentCubit.payForEventRequest(eventRequest: request, method: method);
  }
}
