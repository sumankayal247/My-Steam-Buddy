import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_state.dart';
import '../../theme.dart';

/// Bottom sheet with the price range, discount slider and sort options.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogState>();
    final ceiling = cat.priceCeiling;
    final range = cat.priceRange;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filters & sorting',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => cat.resetFilters(),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sort
          const Text('Sort by', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SortMode.values.map((m) {
              final selected = cat.sort == m;
              return ChoiceChip(
                label: Text(m.label),
                selected: selected,
                onSelected: (_) => cat.setSort(m),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600),
                backgroundColor: AppColors.surfaceAlt,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Price range
          Row(
            children: [
              const Text('Price range', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Text(
                '${formatPrice(range.start, cat.repo?.itad.country == 'IN' ? 'INR' : 'USD')} '
                '– ${formatPrice(range.end, cat.repo?.itad.country == 'IN' ? 'INR' : 'USD')}'
                '${range.end >= ceiling ? '+' : ''}',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(
              range.start.clamp(0, ceiling),
              range.end.clamp(0, ceiling),
            ),
            min: 0,
            max: ceiling,
            divisions: 40,
            labels: RangeLabels(
              range.start.round().toString(),
              range.end.round().toString(),
            ),
            onChanged: (v) => cat.setPriceRange(v),
          ),
          const SizedBox(height: 12),

          // Discount slider
          Row(
            children: [
              const Text('Minimum discount', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Text('${cat.minDiscount}%+',
                  style: const TextStyle(color: AppColors.sale, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: cat.minDiscount.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${cat.minDiscount}%',
            onChanged: (v) => cat.setMinDiscount(v.round()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Show results',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
