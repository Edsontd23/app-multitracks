
class SectionPreset {
  final String name;
  final int colorValue;

  const SectionPreset({
    required this.name,
    required this.colorValue,
  });
}

class SectionPresets {
  static const List<SectionPreset> defaults = [
    SectionPreset(name: 'Intro', colorValue: 0xFF64748B),
    SectionPreset(name: 'Verso', colorValue: 0xFF3B82F6),
    SectionPreset(name: 'Pre-Coro', colorValue: 0xFF8B5CF6),
    SectionPreset(name: 'Coro', colorValue: 0xFF16A34A),
    SectionPreset(name: 'Puente', colorValue: 0xFFF59E0B),
    SectionPreset(name: 'Instrumental', colorValue: 0xFF06B6D4),
    SectionPreset(name: 'Solo', colorValue: 0xFFEC4899),
    SectionPreset(name: 'Outro', colorValue: 0xFFEF4444),
    SectionPreset(name: 'Break', colorValue: 0xFFA1A1AA),
  ];
}
