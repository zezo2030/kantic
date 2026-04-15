import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../cubit/my_hall_tickets_cubit.dart';
import '../widgets/hall_ticket_card_widget.dart';

class MyHallTicketsPage extends StatelessWidget {
  const MyHallTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyHallTicketsCubit>()..refresh(),
      child: const _MyHallTicketsView(),
    );
  }
}

class _MyHallTicketsView extends StatelessWidget {
  const _MyHallTicketsView();

  Future<void> _openQr(
    BuildContext context,
    TicketsRemoteDataSource tickets,
    String ticketId,
    String bookingId,
  ) async {
    var tid = ticketId;
    if (tid.isEmpty && bookingId.isNotEmpty) {
      try {
        final list = await tickets.getBookingTickets(bookingId);
        if (list.isNotEmpty) tid = list.first.id;
      } catch (_) {}
    }
    if (tid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_qr_available'.tr())),
      );
      return;
    }
    try {
      final qr = await tickets.getTicketQr(tid);
      if (!context.mounted) return;
      if (qr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_qr_available'.tr())),
        );
        return;
      }
      _showHallQrDialog(context, qr);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showHallQrDialog(BuildContext context, String qr) {
    final Widget imageChild = qr.startsWith('data:image')
        ? _dataUrlImage(qr)
        : QrImageView(
            data: qr,
            version: QrVersions.auto,
            size: 200,
          );

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.scan_barcode,
                  color: AppColors.primaryRed, size: 32),
              const SizedBox(height: 12),
              Text(
                'my_qr_code'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'use_at_counter'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: imageChild,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'close'.tr(),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataUrlImage(String dataUrl) {
    final i = dataUrl.indexOf(',');
    if (i <= 0 || i >= dataUrl.length - 1) {
      return const SizedBox(width: 200, height: 200);
    }
    try {
      final bytes = base64Decode(dataUrl.substring(i + 1));
      return Image.memory(
        bytes,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      );
    } catch (_) {
      return const SizedBox(width: 200, height: 200);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = sl<TicketsRemoteDataSource>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        title: Text(
          'my_hall_tickets'.tr(),
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocBuilder<MyHallTicketsCubit, MyHallTicketsState>(
        builder: (context, state) {
          if (state is MyHallTicketsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          if (state is MyHallTicketsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.warning_2,
                      size: 48, color: AppColors.errorColor),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MyHallTicketsCubit>().refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'retry'.tr(),
                      style:
                          const TextStyle(fontFamily: 'MontserratArabic'),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is MyHallTicketsLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.ticket,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'my_hall_tickets_empty'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () async =>
                  context.read<MyHallTicketsCubit>().refresh(),
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final b = state.items[i];
                  final tid = b.primaryTicketId;
                  return HallTicketCardWidget(
                    booking: b,
                    onViewQr: () =>
                        _openQr(context, tickets, tid, b.id),
                    onCopyId: () {
                      final text =
                          tid.isNotEmpty ? tid : b.id;
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('id_copied'.tr())),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
