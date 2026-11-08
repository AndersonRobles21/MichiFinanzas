import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.subtitleKey,
    this.caption,
    this.captionKey,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Key? subtitleKey;
  final String? caption;
  final Key? captionKey;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          key: subtitleKey,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            key: captionKey,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (trailing == null) return titleBlock;
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppSpacing.compact),
              Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpacing.compact),
            trailing!,
          ],
        );
      },
    );
  }
}
