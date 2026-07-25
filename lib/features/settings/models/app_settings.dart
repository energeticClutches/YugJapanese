/// How the app resolves [ThemeMode] for `MaterialApp`.
enum AppThemeMode { system, light, dark }

/// Relative playback/animation speed for lesson and stroke animations.
enum AnimationSpeed { slow, normal, fast }

/// Which hand the writing canvas should be optimized for.
enum WritingHand { left, right }

/// User-configurable application preferences, persisted locally via Hive.
///
/// Add new fields with a sensible default so existing stored settings keep
/// deserializing correctly (see [fromMap]).
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.showStrokeGuide = true,
    this.showGrid = true,
    this.autoPlayAudio = true,
    this.animationSpeed = AnimationSpeed.normal,
    this.preferredWritingHand = WritingHand.right,
    this.language = 'en',
    this.largerWritingArea = false,
  });

  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool showStrokeGuide;
  final bool showGrid;
  final bool autoPlayAudio;
  final AnimationSpeed animationSpeed;
  final WritingHand preferredWritingHand;
  final String language;
  final bool largerWritingArea;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? showStrokeGuide,
    bool? showGrid,
    bool? autoPlayAudio,
    AnimationSpeed? animationSpeed,
    WritingHand? preferredWritingHand,
    String? language,
    bool? largerWritingArea,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      showStrokeGuide: showStrokeGuide ?? this.showStrokeGuide,
      showGrid: showGrid ?? this.showGrid,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      preferredWritingHand: preferredWritingHand ?? this.preferredWritingHand,
      language: language ?? this.language,
      largerWritingArea: largerWritingArea ?? this.largerWritingArea,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'showStrokeGuide': showStrokeGuide,
      'showGrid': showGrid,
      'autoPlayAudio': autoPlayAudio,
      'animationSpeed': animationSpeed.name,
      'preferredWritingHand': preferredWritingHand.name,
      'language': language,
      'largerWritingArea': largerWritingArea,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: _enumFromName(
        AppThemeMode.values,
        map['themeMode'],
        AppThemeMode.system,
      ),
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      showStrokeGuide: map['showStrokeGuide'] as bool? ?? true,
      showGrid: map['showGrid'] as bool? ?? true,
      autoPlayAudio: map['autoPlayAudio'] as bool? ?? true,
      animationSpeed: _enumFromName(
        AnimationSpeed.values,
        map['animationSpeed'],
        AnimationSpeed.normal,
      ),
      preferredWritingHand: _enumFromName(
        WritingHand.values,
        map['preferredWritingHand'],
        WritingHand.right,
      ),
      language: map['language'] as String? ?? 'en',
      largerWritingArea: map['largerWritingArea'] as bool? ?? false,
    );
  }

  static T _enumFromName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    if (name is! String) {
      return fallback;
    }
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
