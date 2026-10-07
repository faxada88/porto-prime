import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class PrimeSectionHeader extends StatelessWidget {
  const PrimeSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.ocean600,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 4),
                  const Icon(AppIcons.chevronRight, size: 15),
                ],
              ),
            ),
        ],
      );
}

class PrimeSurface extends StatelessWidget {
  const PrimeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.background = AppColors.surface,
    this.borderColor = AppColors.stroke,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color background;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: shadow ? AppShadows.soft : null,
        ),
        child: child,
      );
}

class PrimeIconButton extends StatelessWidget {
  const PrimeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.badgeCount = 0,
    this.foreground = AppColors.ink,
    this.background = AppColors.surface,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final int badgeCount;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: AppControl.minTap,
                  height: AppControl.minTap,
                  child: Icon(icon, size: AppIconSize.sm, color: foreground),
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.coral600,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class PrimeSearchField extends StatefulWidget {
  const PrimeSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.hint = 'O que você quer pedir hoje?',
    this.readOnly = false,
    this.loading = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String hint;
  final bool readOnly;
  final bool loading;

  @override
  State<PrimeSearchField> createState() => _PrimeSearchFieldState();
}

class _PrimeSearchFieldState extends State<PrimeSearchField> {
  TextEditingController? _internal;

  TextEditingController get controller =>
      widget.controller ?? (_internal ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant PrimeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_refresh);
      _internal?.removeListener(_refresh);
      controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        textField: !widget.readOnly,
        button: widget.readOnly,
        label: widget.hint,
        child: TextField(
          controller: controller,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(AppIcons.search, size: AppIconSize.sm),
            suffixIcon: widget.loading
                ? const Padding(
                    padding: EdgeInsets.all(17),
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty && !widget.readOnly
                    ? IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          controller.clear();
                          widget.onChanged?.call('');
                        },
                        icon: const Icon(AppIcons.close, size: 18),
                      )
                    : null,
          ),
        ),
      );
}

class PrimeEmptyState extends StatelessWidget {
  const PrimeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => PrimeSurface(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.ocean50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                icon,
                color: AppColors.ocean700,
                size: AppIconSize.lg,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      );
}

class PrimeSkeleton extends StatefulWidget {
  const PrimeSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = AppRadius.md,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<PrimeSkeleton> createState() => _PrimeSkeletonState();
}

class _PrimeSkeletonState extends State<PrimeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.stroke,
              AppColors.surface,
              .25 + (_controller.value * .4),
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

class PrimeStatusPill extends StatelessWidget {
  const PrimeStatusPill({
    super.key,
    required this.label,
    this.tone = PrimeStatusTone.neutral,
    this.dot = true,
  });

  final String label;
  final PrimeStatusTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      PrimeStatusTone.success => (AppColors.ocean100, AppColors.ocean800),
      PrimeStatusTone.warning => (AppColors.sand100, AppColors.warning),
      PrimeStatusTone.danger => (AppColors.coral100, AppColors.coral600),
      PrimeStatusTone.info => (AppColors.sky100, Color(0xFF2B6D89)),
      PrimeStatusTone.neutral => (Color(0xFFF0F3F1), AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  letterSpacing: .35,
                ),
          ),
        ],
      ),
    );
  }
}

enum PrimeStatusTone { neutral, success, warning, danger, info }


class PrimeErrorBanner extends StatelessWidget {
  const PrimeErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  String get friendly {
    final raw = message
        .replaceFirst('Exception: ', '')
        .replaceAll('SocketException', '')
        .replaceAll('ClientException', '')
        .trim();
    if (raw.isEmpty || raw == 'null' || raw == 'undefined') {
      return 'Não foi possível concluir esta ação agora. Tente novamente.';
    }
    if (raw.contains('500')) {
      return 'A operação está temporariamente indisponível. Tente novamente em instantes.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.coral100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.coral600.withValues(alpha: .16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.alert,
                color: AppColors.coral600,
                size: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  friendly,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: AppSpacing.xs),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      );
}

class PrimeSheetHandle extends StatelessWidget {
  const PrimeSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.strokeStrong,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
}

class PrimePageHeader extends StatelessWidget {
  const PrimePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.ocean600,
                          letterSpacing: 1.15,
                        ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      );
}

class PrimeSkeletonCard extends StatelessWidget {
  const PrimeSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PrimeSkeleton(
              height: 180,
              radius: AppRadius.lg,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          PrimeSkeleton(height: 14),
          SizedBox(height: AppSpacing.xs),
          PrimeSkeleton(height: 12, width: 96),
        ],
      );
}
