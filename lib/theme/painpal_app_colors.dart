import 'package:flutter/material.dart';

/// Design tokens from `cursor_redesign_prompt.md` (light + dark).
@immutable
class PainpalAppColors extends ThemeExtension<PainpalAppColors> {
  const PainpalAppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgCard,
    required this.bgCardElevated,
    required this.accentPrimary,
    required this.accentPrimaryLight,
    required this.accentSecondary,
    required this.accentSecondaryLight,
    required this.accentSuccess,
    required this.accentSuccessLight,
    required this.accentWarning,
    required this.accentWarningLight,
    required this.accentDanger,
    required this.accentDangerLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.borderDefault,
    required this.borderFocus,
    required this.shadowCard,
    required this.shadowElevated,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgCard;
  final Color bgCardElevated;
  final Color accentPrimary;
  final Color accentPrimaryLight;
  final Color accentSecondary;
  final Color accentSecondaryLight;
  final Color accentSuccess;
  final Color accentSuccessLight;
  final Color accentWarning;
  final Color accentWarningLight;
  final Color accentDanger;
  final Color accentDangerLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;
  final Color borderDefault;
  final Color borderFocus;
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowElevated;

  static const PainpalAppColors light = PainpalAppColors(
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFFFF5FA),
    bgTertiary: Color(0xFFFDF5F8),
    bgCard: Color(0xFFFFFFFF),
    bgCardElevated: Color(0xFFFAFAFA),
    accentPrimary: Color(0xFF7C6FF7),
    accentPrimaryLight: Color(0xFFEDE9FE),
    accentSecondary: Color(0xFFF472B6),
    accentSecondaryLight: Color(0xFFFDF2F8),
    accentSuccess: Color(0xFF4ADE80),
    accentSuccessLight: Color(0xFFF0FDF4),
    accentWarning: Color(0xFFFBBF24),
    accentWarningLight: Color(0xFFFFFBEB),
    accentDanger: Color(0xFFF87171),
    accentDangerLight: Color(0xFFFFF1F2),
    textPrimary: Color(0xFF1C1B2E),
    textSecondary: Color(0xFF6B6880),
    textTertiary: Color(0xFFA89FC0),
    textOnAccent: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFE8E5F0),
    borderFocus: Color(0xFF7C6FF7),
    shadowCard: [
      BoxShadow(
        color: Color(0x147C6FF7),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ],
    shadowElevated: [
      BoxShadow(
        color: Color(0x1F7C6FF7),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const PainpalAppColors dark = PainpalAppColors(
    bgPrimary: Color(0xFF13111E),
    bgSecondary: Color(0xFF1C1929),
    bgTertiary: Color(0xFF0F0E18),
    bgCard: Color(0xFF1E1B2E),
    bgCardElevated: Color(0xFF252238),
    accentPrimary: Color(0xFF9B8FFB),
    accentPrimaryLight: Color(0xFF2A2550),
    accentSecondary: Color(0xFFF9A8D4),
    accentSecondaryLight: Color(0xFF3B1D2E),
    accentSuccess: Color(0xFF6EE7B7),
    accentSuccessLight: Color(0xFF0D2E1F),
    accentWarning: Color(0xFFFCD34D),
    accentWarningLight: Color(0xFF2E2210),
    accentDanger: Color(0xFFFCA5A5),
    accentDangerLight: Color(0xFF2E1010),
    textPrimary: Color(0xFFF0EEF8),
    textSecondary: Color(0xFFA89FC0),
    textTertiary: Color(0xFF6B6880),
    textOnAccent: Color(0xFF13111E),
    borderDefault: Color(0xFF2E2A42),
    borderFocus: Color(0xFF9B8FFB),
    shadowCard: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ],
    shadowElevated: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ],
  );

  @override
  PainpalAppColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgCard,
    Color? bgCardElevated,
    Color? accentPrimary,
    Color? accentPrimaryLight,
    Color? accentSecondary,
    Color? accentSecondaryLight,
    Color? accentSuccess,
    Color? accentSuccessLight,
    Color? accentWarning,
    Color? accentWarningLight,
    Color? accentDanger,
    Color? accentDangerLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAccent,
    Color? borderDefault,
    Color? borderFocus,
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowElevated,
  }) {
    return PainpalAppColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgCard: bgCard ?? this.bgCard,
      bgCardElevated: bgCardElevated ?? this.bgCardElevated,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPrimaryLight: accentPrimaryLight ?? this.accentPrimaryLight,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentSecondaryLight: accentSecondaryLight ?? this.accentSecondaryLight,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentSuccessLight: accentSuccessLight ?? this.accentSuccessLight,
      accentWarning: accentWarning ?? this.accentWarning,
      accentWarningLight: accentWarningLight ?? this.accentWarningLight,
      accentDanger: accentDanger ?? this.accentDanger,
      accentDangerLight: accentDangerLight ?? this.accentDangerLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocus: borderFocus ?? this.borderFocus,
      shadowCard: shadowCard ?? this.shadowCard,
      shadowElevated: shadowElevated ?? this.shadowElevated,
    );
  }

  @override
  PainpalAppColors lerp(ThemeExtension<PainpalAppColors>? other, double t) {
    if (other is! PainpalAppColors) {
      return this;
    }
    if (t == 0) {
      return this;
    }
    if (t == 1) {
      return other;
    }
    return PainpalAppColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardElevated: Color.lerp(bgCardElevated, other.bgCardElevated, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentPrimaryLight:
          Color.lerp(accentPrimaryLight, other.accentPrimaryLight, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentSecondaryLight:
          Color.lerp(accentSecondaryLight, other.accentSecondaryLight, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentSuccessLight:
          Color.lerp(accentSuccessLight, other.accentSuccessLight, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentWarningLight:
          Color.lerp(accentWarningLight, other.accentWarningLight, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentDangerLight:
          Color.lerp(accentDangerLight, other.accentDangerLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      shadowCard: t < 0.5 ? shadowCard : other.shadowCard,
      shadowElevated: t < 0.5 ? shadowElevated : other.shadowElevated,
    );
  }
}

/// Border radii from the redesign spec + bubbly wellness references.
abstract final class PainpalRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  /// Large rounded cards (pet / mood tracker references).
  static const double cardBubble = 28;
  static const double pill = 999;
  static const double dock = 32;
}

extension PainpalThemeContext on BuildContext {
  PainpalAppColors get pp =>
      Theme.of(this).extension<PainpalAppColors>() ?? PainpalAppColors.light;
}
