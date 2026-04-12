import 'package:flutter/material.dart';

import 'package:kindmap/config/app_theme.dart';

// Skeleton loader widget for grid content
class GridInfoCardSkeleton extends StatelessWidget {
  const GridInfoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxCardWidth =
            (MediaQuery.of(context).size.width * 0.4).clamp(200.0, 320.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryText.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton for drag handle
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.lineColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Skeleton for header row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.lineColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Skeleton for people count
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skeleton for divider
                Container(
                  height: 1,
                  color: theme.lineColor,
                ),
                const SizedBox(height: 16),
                // Skeleton for buttons
                Column(
                  children: [
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.lineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
