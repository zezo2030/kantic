import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/animation_mixins.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../branches/data/branches_repository.dart';
import '../../../branches/data/branches_api.dart';
import '../../../home/domain/entities/branch_entity.dart';
import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import '../../domain/entities/loyalty_entity.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<LoyaltyCubit>()..loadLoyaltyInfo(),
        ),
        BlocProvider(
          create: (_) => BranchesCubit(
            repository: BranchesRepositoryImpl(api: BranchesApi()),
          )..loadAll(),
        ),
      ],
      child: const _LoyaltyScreenContent(),
    );
  }
}

class _LoyaltyScreenContent extends StatefulWidget {
  const _LoyaltyScreenContent();

  @override
  State<_LoyaltyScreenContent> createState() => _LoyaltyScreenContentState();
}

class _LoyaltyScreenContentState extends State<_LoyaltyScreenContent>
    with
        TickerProviderStateMixin,
        StaggerAnimationMixin,
        CountingAnimationMixin {
  late AnimationController _entranceController;
  late Animation<double> _cardEntrance;
  late Animation<double> _progressEntrance;
  bool _animationStarted = false;
  int _staggerTransactionCount = -1;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: AnimationConstants.luxuryCurve),
    );

    _progressEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: AnimationConstants.luxuryCurve),
    );

    initCountingAnimation(vsync: this);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _startEntranceAnimation() {
    if (_animationStarted) return;
    _animationStarted = true;
    _entranceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoyaltyCubit, LoyaltyState>(
      listener: (context, state) {
        if (state is LoyaltyRedeemSuccess) {
          _showRedeemSuccessDialog(context, state.ticket);
        } else if (state is LoyaltyRedeemError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
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
        return Scaffold(
          backgroundColor: AppColors.luxurySurfaceVariant,
          body: RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () => context.read<LoyaltyCubit>().loadLoyaltyInfo(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                if (state is LoyaltyLoading || state is LoyaltyInitial)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  )
                else if (state is LoyaltyError)
                  SliverFillRemaining(
                    child: _buildErrorState(context, state.message),
                  )
                else
                  _buildContent(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceColor,
      centerTitle: true,
      title: Text(
        'loyalty_program'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  LoyaltyInfoEntity? _extractInfo(LoyaltyState state) {
    if (state is LoyaltyLoaded) return state.info;
    if (state is LoyaltyRedeemLoading) return state.info;
    if (state is LoyaltyRedeemSuccess) return state.info;
    if (state is LoyaltyRedeemError) return state.info;
    return null;
  }

  Widget _buildContent(BuildContext context, LoyaltyState state) {
    final info = _extractInfo(state);
    if (info == null) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    final isRedeeming = state is LoyaltyRedeemLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startEntranceAnimation();
      final txCount = info.transactions.length;
      if (txCount != _staggerTransactionCount) {
        _staggerTransactionCount = txCount;
        initStaggerAnimation(vsync: this, itemCount: txCount);
        setState(() {});
        if (txCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) startStaggerAnimation();
          });
        }
      }
    });

    final padding = Responsive.responsivePadding(context);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          AnimatedBuilder(
            animation: _cardEntrance,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _cardEntrance.value)),
                child: Opacity(opacity: _cardEntrance.value, child: child),
              );
            },
            child: _buildPointsCard(context, info),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _progressEntrance,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _progressEntrance.value)),
                child: Opacity(opacity: _progressEntrance.value, child: child),
              );
            },
            child: _buildProgressCard(context, info),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _progressEntrance,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * _progressEntrance.value),
                child: Opacity(opacity: _progressEntrance.value, child: child),
              );
            },
            child: _buildRedeemButton(context, info, isRedeeming),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _progressEntrance,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-20 * (1 - _progressEntrance.value), 0),
                child: Opacity(opacity: _progressEntrance.value, child: child),
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'loyalty_history'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (info.transactions.isEmpty)
            _buildEmptyTransactions(context)
          else
            _buildTransactionsList(context, info.transactions),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, LoyaltyInfoEntity info) {
    return Semantics(
      label: '${'your_loyalty_points'.tr()}: ${info.points} ${'points'.tr()}',
      button: true,
      child: GestureDetector(
        onTap: () => _showPointsBreakdown(context, info),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'your_loyalty_points'.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'points'.tr(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Iconsax.star1,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildCountingWidget(
                targetValue: info.points,
                builder: (value) => Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      min: 40,
                      max: 56,
                    ),
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniStat(
                    context,
                    Iconsax.ticket,
                    '${info.points ~/ info.pointsPerTicket}',
                    'tickets'.tr(),
                  ),
                  const SizedBox(width: 24),
                  _buildMiniStat(
                    context,
                    Iconsax.chart,
                    '${info.pointsPerTicket}',
                    'per_ticket'.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  void _showPointsBreakdown(BuildContext context, LoyaltyInfoEntity info) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Iconsax.star1, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    '${info.points}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'total_points'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildBreakdownRow(
              context,
              'progress_to_ticket'.tr(),
              '${info.points % info.pointsPerTicket} / ${info.pointsPerTicket}',
              AppColors.primaryRed,
            ),
            const Divider(height: 24),
            _buildBreakdownRow(
              context,
              'tickets_ready'.tr(),
              '${info.points ~/ info.pointsPerTicket}',
              AppColors.successColor,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, LoyaltyInfoEntity info) {
    final progress = (info.pointsPerTicket > 0)
        ? (info.points % info.pointsPerTicket) / info.pointsPerTicket
        : 0.0;
    final pointsNeeded = info.pointsPerTicket > 0
        ? info.pointsPerTicket - (info.points % info.pointsPerTicket)
        : 0;
    final ticketsAvailable = info.pointsPerTicket > 0
        ? info.points ~/ info.pointsPerTicket
        : 0;

    return Semantics(
      label:
          '${'progress_to_ticket'.tr()}: ${(progress * 100).toStringAsFixed(0)}%',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.chart_2,
                          size: 20,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'progress_to_ticket'.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: info.canRedeem
                        ? AppColors.successGradient
                        : LinearGradient(
                            colors: [
                              AppColors.primaryRed.withOpacity(0.8),
                              AppColors.deepRed.withOpacity(0.8),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: info.canRedeem
                        ? [
                            BoxShadow(
                              color: AppColors.successColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.ticket,
                        size: 16,
                        color: Colors.white.withOpacity(0.95),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$ticketsAvailable',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.luxurySurfaceVariant,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: info.canRedeem ? 1.0 : progress.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: AnimationConstants.luxuryCurve,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: info.canRedeem
                          ? AppColors.successGradient
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (info.canRedeem
                                      ? AppColors.successColor
                                      : AppColors.primaryRed)
                                  .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (info.canRedeem)
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.successColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ready_to_redeem'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      '${'need_more_points'.tr()} $pointsNeeded ${'points_for_ticket'.tr()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    '${'ticket_costs'.tr()} ${info.pointsPerTicket} ${'pts'.tr()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemButton(
    BuildContext context,
    LoyaltyInfoEntity info,
    bool isLoading,
  ) {
    return Semantics(
      label: isLoading ? 'loading'.tr() : 'redeem_free_ticket'.tr(),
      button: true,
      enabled: info.canRedeem && !isLoading,
      child: CustomButton(
        onPressed: (info.canRedeem && !isLoading)
            ? () => _showBranchSelectionSheet(context)
            : null,
        text: isLoading ? 'loading' : 'redeem_free_ticket',
        height: 56, // Increased height for a more premium feel
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
            : const Icon(Iconsax.ticket, color: Colors.white, size: 22),
        useGradient: true,
        width: double.infinity,
      ),
    );
  }

  void _showBranchSelectionSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: BranchesCubit(
          repository: BranchesRepositoryImpl(api: BranchesApi()),
        )..loadAll(),
        child: _BranchSelectionSheet(
          onBranchSelected: (branchId) {
            Navigator.of(sheetContext).pop();
            context.read<LoyaltyCubit>().redeemTicket(branchId: branchId);
          },
        ),
      ),
    );
  }

  void _showRedeemSuccessDialog(
    BuildContext context,
    RedeemTicketResult ticket,
  ) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _RedeemSuccessDialog(ticket: ticket),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Iconsax.star1, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'no_loyalty_transactions'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'loyalty_transactions_empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    List<LoyaltyTransactionEntity> transactions,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return buildStaggerWidget(
          index: index,
          child: _TransactionCard(
            icon: _iconForType(transactions[index].type),
            label: _labelForType(transactions[index].type),
            points: transactions[index].points,
            date: transactions[index].createdAt,
            color: _colorForType(transactions[index].type),
            isPositive: _isPositiveType(transactions[index].type),
          ),
        );
      },
    );
  }

  IconData _iconForType(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earn:
        return Iconsax.arrow_down_2;
      case LoyaltyTransactionType.redeemTicket:
        return Iconsax.ticket;
      case LoyaltyTransactionType.bonus:
        return Iconsax.gift;
      case LoyaltyTransactionType.penalty:
        return Iconsax.minus_cirlce;
      case LoyaltyTransactionType.refund:
        return Iconsax.rotate_left;
      case LoyaltyTransactionType.burn:
        return Iconsax.arrow_up_2;
      default:
        return Iconsax.star1;
    }
  }

  String _labelForType(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earn:
        return 'loyalty_earn'.tr();
      case LoyaltyTransactionType.redeemTicket:
        return 'loyalty_redeem_ticket'.tr();
      case LoyaltyTransactionType.bonus:
        return 'loyalty_bonus'.tr();
      case LoyaltyTransactionType.penalty:
        return 'loyalty_penalty'.tr();
      case LoyaltyTransactionType.refund:
        return 'loyalty_refund'.tr();
      case LoyaltyTransactionType.burn:
        return 'loyalty_burn'.tr();
      default:
        return 'loyalty_transaction'.tr();
    }
  }

  Color _colorForType(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earn:
      case LoyaltyTransactionType.bonus:
      case LoyaltyTransactionType.refund:
        return AppColors.successColor;
      case LoyaltyTransactionType.redeemTicket:
      case LoyaltyTransactionType.penalty:
      case LoyaltyTransactionType.burn:
        return AppColors.primaryRed;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _isPositiveType(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earn:
      case LoyaltyTransactionType.bonus:
      case LoyaltyTransactionType.refund:
        return true;
      case LoyaltyTransactionType.redeemTicket:
      case LoyaltyTransactionType.penalty:
      case LoyaltyTransactionType.burn:
        return false;
      default:
        return true;
    }
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.warning_2,
              size: 48,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: () => context.read<LoyaltyCubit>().loadLoyaltyInfo(),
            icon: const Icon(Iconsax.refresh, color: Colors.white, size: 20),
            text: 'retry',
            width: 150,
            useGradient: true,
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int points;
  final DateTime date;
  final Color color;
  final bool isPositive;

  const _TransactionCard({
    required this.icon,
    required this.label,
    required this.points,
    required this.date,
    required this.color,
    required this.isPositive,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
    with MicroInteractionMixin {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${widget.label}: ${widget.isPositive ? '+' : ''}${widget.points} ${'points'.tr()}',
      child: buildMicroInteractionWidget(
        onTap: () => HapticFeedback.selectionClick(),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColorLight,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: widget.color.withOpacity(0.15), width: 1),
          ),
          child:
              Responsive.isMobile(context) &&
                  Responsive.screenWidth(context) < 360
              ? _buildVerticalLayout(context)
              : _buildHorizontalLayout(context),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(widget.icon, color: widget.color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Iconsax.calendar_1, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(widget.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Iconsax.clock, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(widget.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.isPositive ? '+' : ''}${widget.points}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.15),
                    widget.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.isPositive ? '+' : ''}${widget.points}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Iconsax.calendar_1, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(widget.date),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Icon(Iconsax.clock, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              DateFormat('HH:mm').format(widget.date),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _BranchSelectionSheet extends StatefulWidget {
  final void Function(String branchId) onBranchSelected;

  const _BranchSelectionSheet({required this.onBranchSelected});

  @override
  State<_BranchSelectionSheet> createState() => _BranchSelectionSheetState();
}

class _BranchSelectionSheetState extends State<_BranchSelectionSheet> {
  String? _selectedBranchId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Iconsax.ticket,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_branch'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'select_branch_for_ticket'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.luxurySurfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'search_branch'.tr(),
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<BranchesCubit, BranchesState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<BranchesCubit>().loadAll(),
                          icon: const Icon(Iconsax.refresh),
                          label: Text('retry'.tr()),
                        ),
                      ],
                    ),
                  );
                }

                final branches = state.branches
                    .where(
                      (b) =>
                          b.nameAr.contains(_searchQuery) ||
                          b.nameEn.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          b.location.contains(_searchQuery),
                    )
                    .toList();

                if (branches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.search_normal_1,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_branches_found'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isSelected = _selectedBranchId == branch.id;
                    return _BranchListItem(
                      branch: branch,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedBranchId = branch.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'cancel',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    onPressed: _selectedBranchId != null
                        ? () => widget.onBranchSelected(_selectedBranchId!)
                        : null,
                    text: 'confirm',
                    icon: const Icon(
                      Iconsax.ticket,
                      color: Colors.white,
                      size: 20,
                    ),
                    useGradient: true,
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

class _BranchListItem extends StatelessWidget {
  final BranchEntity branch;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchListItem({
    required this.branch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${branch.nameAr}, ${branch.location}',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryRed.withOpacity(0.08)
                : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryRed : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryRed.withOpacity(0.15)
                      : AppColors.luxurySurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.building_3,
                  color: isSelected
                      ? AppColors.primaryRed
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.nameAr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primaryRed
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch.location,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.tick_circle,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedeemSuccessDialog extends StatefulWidget {
  final RedeemTicketResult ticket;

  const _RedeemSuccessDialog({required this.ticket});

  @override
  State<_RedeemSuccessDialog> createState() => _RedeemSuccessDialogState();
}

class _RedeemSuccessDialogState extends State<_RedeemSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: AnimationConstants.luxuryCurve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.successColor.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successColor.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.tick_circle,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'ticket_redeemed_success'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ticket_redeemed_desc'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.ticket.qrCode != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.luxurySurfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.scan_barcode,
                              size: 80,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.ticket.ticketId ?? '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'close',
                    useGradient: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
