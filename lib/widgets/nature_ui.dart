import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class NatureBackdrop extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showSun;

  const NatureBackdrop({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.showSun = true,
  });

  @override
  Widget build(BuildContext context) {
    final oak = context.oak;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  oak.backdropTop,
                  oak.backdropMid,
                  oak.backdropBottom,
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
        ),
        if (showSun)
          Positioned(
            top: -70,
            right: -54,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    oak.accent.withValues(alpha: 0.26),
                    oak.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: 98,
          left: -40,
          child: Transform.rotate(
            angle: -0.35,
            child: Icon(
              Icons.eco_rounded,
              size: 118,
              color: oak.leaf.withValues(alpha: 0.09),
            ),
          ),
        ),
        // Keep page bodies bounded. A loose Stack child can collapse scroll views
        // or make Column/Expanded layouts fail before anything is painted.
        Positioned.fill(
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}

class NatureHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? startColor;
  final Color? endColor;

  const NatureHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.startColor,
    this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    final oak = context.oak;
    final content = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            startColor ?? oak.forestDeep,
            endColor ?? Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: oak.forestDeep.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: oak.accent.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -30,
            child: Transform.rotate(
              angle: -0.24,
              child: Icon(
                Icons.park_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}

class NatureSectionTitle extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const NatureSectionTitle({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class NatureEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const NatureEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.secondary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class NatureErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const NatureErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: NatureEmptyState(
          icon: Icons.cloud_off_rounded,
          title: title,
          message: message,
          action: onRetry == null
              ? null
              : OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
        ),
      ),
    );
  }
}

class NatureBookCover extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double? width;
  final double? height;
  final double radius;
  final Widget? badge;

  const NatureBookCover({
    super.key,
    required this.imageUrl,
    required this.title,
    this.width,
    this.height,
    this.radius = 11,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(context),
            )
          else
            _fallback(context),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (badge != null) Positioned(top: 7, right: 7, child: badge!),
        ],
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: OakShelfTheme.forestDeep.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: cover,
    );
  }

  Widget _fallback(BuildContext context) {
    final oak = context.oak;
    final hue = title.codeUnits.fold<int>(0, (sum, value) => sum + value) % 3;
    final gradients = [
      [oak.forestDeep, Theme.of(context).colorScheme.primary],
      const [Color(0xFF0D526F), OakShelfTheme.oceanBlueColor],
      [const Color(0xFF3A465E), oak.accent],
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients[hue],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -16,
            child: Transform.rotate(
              angle: math.pi / 10,
              child: Icon(
                Icons.eco_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
