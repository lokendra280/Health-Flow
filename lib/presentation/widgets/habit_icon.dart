class HabitIcon {
  final String label;
  final String? emoji;
  final String? assetPath;
  final bool isAsset;
  final bool isSvg;

  const HabitIcon._({
    required this.label,
    this.emoji,
    this.assetPath,
    required this.isAsset,
    required this.isSvg,
  });

  const HabitIcon.emoji({
    required this.label,
    required String emoji,
  })  : emoji = emoji,
        assetPath = null,
        isAsset = false,
        isSvg = false;

  const HabitIcon.asset({
    required this.label,
    required String assetPath,
  })  : assetPath = assetPath,
        emoji = null,
        isAsset = true,
        isSvg = false;

  const HabitIcon.svg({
    required this.label,
    required String assetPath,
  })  : assetPath = assetPath,
        emoji = null,
        isAsset = true,
        isSvg = true;
}
