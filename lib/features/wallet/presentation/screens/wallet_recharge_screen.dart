import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import 'wallet_moyasar_payment_page.dart';
import 'wallet_recharge_success_page.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({super.key});

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  static const List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 50.0, 'label': '50'},
    {'amount': 100.0, 'label': '100'},
    {'amount': 200.0, 'label': '200'},
    {'amount': 500.0, 'label': '500'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        if (state is WalletRechargeSuccess) {
          final paymentId = state.paymentId;
          final amount = state.amount;

          if (paymentId != null && paymentId.isNotEmpty && amount != null) {
            _openMoyasarCheckout(context, paymentId: paymentId, amount: amount);
          } else if (state.redirectUrl != null &&
              state.redirectUrl!.isNotEmpty) {
            _openPaymentUrl(context, state.redirectUrl!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment data not found'),
                backgroundColor: AppColors.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } else if (state is WalletRechargeFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is WalletRechargeLoading;

        return Scaffold(
          backgroundColor: AppColors.luxurySurfaceVariant,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.surfaceColor,
            centerTitle: true,
            title: Text(
              'recharge_wallet'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Iconsax.arrow_left_2,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: 24),
                  _buildAmountSection(context),
                  const SizedBox(height: 24),
                  _buildQuickAmounts(context),
                  const SizedBox(height: 32),
                  _buildRechargeButton(context, isLoading),
                  const SizedBox(height: 16),
                  _buildSecureNote(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepRed.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.wallet_add_1,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recharge_wallet'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'recharge_wallet_desc'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_amount'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          decoration: InputDecoration(
            labelText: 'amount_sar'.tr(),
            prefixIcon: const Icon(
              Iconsax.dollar_circle,
              color: AppColors.primaryRed,
            ),
            suffixText: 'sar'.tr(),
            suffixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: AppColors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.errorColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'enter_valid_amount'.tr();
            if (n < 10) return 'minimum_recharge_amount'.tr();
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmounts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_amounts'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _quickAmounts.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _amountController.text = item['label'] as String;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _amountController.text == item['label']
                            ? AppColors.primaryRed
                            : AppColors.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColorLight,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${item['label']} ${'sar'.tr()}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRechargeButton(BuildContext context, bool isLoading) {
    return CustomButton(
      onPressed: isLoading ? null : () => _onRechargePressed(context),
      text: isLoading ? 'loading' : 'recharge_now',
      height: 56, // Added height for a more premium look
      showShadow: false, // Removed shadow as requested
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Iconsax.wallet_add_1, color: Colors.white, size: 22),
      useGradient: true,
      width: double.infinity,
    );
  }

  Widget _buildSecureNote(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Iconsax.shield_tick,
          size: 16,
          color: AppColors.successColor,
        ),
        const SizedBox(width: 8),
        Text(
          'secure_payment_note'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _onRechargePressed(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    context.read<WalletCubit>().rechargeWallet(amount: amount);
  }

  Future<void> _openMoyasarCheckout(
    BuildContext context, {
    required String paymentId,
    required double amount,
  }) async {
    final walletCubit = context.read<WalletCubit>();
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: walletCubit,
          child: WalletMoyasarPaymentPage(paymentId: paymentId, amount: amount),
        ),
      ),
    );

    if (!mounted || confirmed == null) return;
    if (confirmed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WalletRechargeSuccessPage(paymentId: paymentId),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('recharge_failed'.tr()),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPaymentUrl(BuildContext context, String url) async {
    try {
      String urlToLaunch = url.trim();
      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }
      final uri = Uri.parse(urlToLaunch);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('payment_opened_in_browser'.tr()),
              backgroundColor: AppColors.infoColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_payment_link'.tr()),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_payment'.tr()),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
