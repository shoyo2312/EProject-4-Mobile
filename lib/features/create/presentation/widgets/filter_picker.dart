import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/data/video_filters.dart';

/// Wraps [child] in [filter]'s colour, exactly as the server will apply it.
/// No filter, no wrapper.
class FilteredView extends StatelessWidget {
  const FilteredView({super.key, required this.filter, required this.child});

  final EditFilter? filter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preset = filterById(filter?.id);
    if (filter == null || preset == null) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(colorFilterMatrix(preset, filter!.intensity)),
      child: child,
    );
  }
}

/// A strip of the filters with a swatch each, "None" first. With
/// [showIntensity], a slider under it sets how strong the chosen one is.
class FilterPicker extends StatelessWidget {
  const FilterPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showIntensity = false,
  });

  final EditFilter? value;
  final ValueChanged<EditFilter?> onChanged;
  final bool showIntensity;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: videoFilters.length + 1,
                itemBuilder: (context, i) {
                  final preset = i == 0 ? null : videoFilters[i - 1];
                  final selected = preset?.id == value?.id;
                  return _Swatch(
                    key: Key('filter_${preset?.id ?? 'none'}'),
                    label: preset?.name ?? 'None',
                    filter: preset == null ? null : EditFilter(id: preset.id),
                    selected: selected,
                    // Picking another filter keeps the strength already set.
                    onTap: () => onChanged(preset == null
                        ? null
                        : EditFilter(id: preset.id, intensity: value?.intensity ?? 1.0)),
                  );
                },
              ),
            ),
            if (showIntensity && value != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text('Strength', style: sora(size: 11, color: NowaColors.dim)),
                    Expanded(
                      child: Slider(
                        key: const Key('filter_intensity_slider'),
                        value: value.intensity,
                        activeColor: NowaColors.accent,
                        inactiveColor: NowaColors.hairline,
                        onChanged: (v) => onChanged(value.copyWith(intensity: v)),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${(value.intensity * 100).round()}',
                        style: sora(size: 11, color: NowaColors.text),
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
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.label,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final EditFilter? filter;
  final bool selected;
  final VoidCallback onTap;

  /// The same few colours under every filter, so the swatches compare.
  static const _sample = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NowaColors.accent, NowaColors.support, NowaColors.danger],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? NowaColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FilteredView(
                  filter: filter,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: _sample)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: sora(
                size: 10,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : NowaColors.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
