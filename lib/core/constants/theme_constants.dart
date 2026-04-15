import 'package:flutter/material.dart';

class ThemeConstants {
  ThemeConstants._();

  // Surface hierarchy: deepest → darkest chrome → content → floating panels
  static const Color background = Color(0xFF141414);
  static const Color sidebarBackground = Color(0xFF111111);
  static const Color activityBar = Color(0xFF0A0A0A);
  static const Color deepBackground = Color(0xFF050505);
  static const Color titleBar = Color(0xFF111111);
  static const Color editorBackground = Color(0xFF141414);
  static const Color editorLineHighlight = Color(0xFF1E1E1E);
  static const Color editorGutter = Color(0xFF141414);
  static const Color editorGutterForeground = Color(0xFF858585);
  static const Color panelBackground = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFF111111);
  static const Color borderColor = Color(0xFF2A2A2A);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Text colors
  static const Color textPrimary = Color(0xFFD4D4D4);
  static const Color textSecondary = Color(0xFF9D9D9D);
  static const Color textMuted = Color(0xFF666666);

  // Accent colors
  static const Color accent = Color(0xFF4EC9B0);
  static const Color accentLight = Color(0xFF6DD4BE);
  static const Color accentHover = Color(0xFF3AB49A);
  static const Color accentDark = Color(0xFF267A68);

  // Semantic colors
  static const Color success = Color(0xFF4EC9B0);
  static const Color warning = Color(0xFFCCA700);
  static const Color error = Color(0xFFF44747);
  static const Color info = Color(0xFF4FC1FF);

  // Chat colors
  static const Color userMessageBg = Color(0xFF1E1E1E);
  static const Color assistantMessageBg = Color(0xFF141414);
  static const Color codeBlockBg = Color(0xFF0D1117);

  // Syntax highlight colors
  static const Color syntaxKeyword = Color(0xFF569CD6);
  static const Color syntaxString = Color(0xFFCE9178);
  static const Color syntaxComment = Color(0xFF6A9955);
  static const Color syntaxFunction = Color(0xFFDCDCAA);
  static const Color syntaxType = Color(0xFF4EC9B0);
  static const Color syntaxNumber = Color(0xFFB5CEA8);
  static const Color syntaxVariable = Color(0xFF9CDCFE);

  // Tab colors
  static const Color tabActive = Color(0xFF141414);
  static const Color tabInactive = Color(0xFF111111);
  static const Color tabBorder = Color(0xFF4EC9B0);

  // Frosted glass (for cards on dark backgrounds)
  static const Color frostedBg = Color(0x0AFFFFFF);
  static const Color frostedBorder = Color(0x12FFFFFF);

  // VCS status badge
  static const Color gitBadgeText = Color(0xFF4CAF50);
  static const Color gitBadgeBg = Color(0xFF0F3D1F);
  static const Color gitBadgeBorder = Color(0xFF1A6B35);

  // Input / surface tokens (for input boxes, card surfaces, button backgrounds)
  static const Color inputSurface = Color(0xFF1A1A1A);
  static const Color deepBorder = Color(0xFF222222);
  static const Color mutedFg = Color(0xFF555555);
  static const Color faintFg = Color(0xFF333333);

  // Interactive teal (step dots, spinners, links — alias of accent; to be renamed in follow-up)
  static const Color blueAccent = Color(0xFF4EC9B0);

  // Dim foreground (between textSecondary and textMuted — dim icons, labels)
  static const Color dimFg = Color(0xFF888888);

  // Heading text (brighter than textPrimary, used in onboarding titles)
  static const Color headingText = Color(0xFFE0E0E0);

  // Worktree badge
  static const Color worktreeBadgeBg = Color(0xFF2A1F0A);
  static const Color worktreeBadgeFg = Color(0xFFE8A228);

  // Selection / active-state surfaces
  static const Color selectionBg = Color(0xFF0D2B27);
  static const Color selectionBorder = Color(0xFF1A4840);
  static const Color questionCardBg = Color(0xFF0D2B27);

  // PR status
  static const Color prMergedColor = Color(0xFF6E40C9);
  static const Color pendingAmber = Color(0xFFFFAA00);

  // "Edited" badge (pending local edits on a file)
  static const Color editedBadgeBg = Color(0xFF3D2900);
  static const Color editedBadgeBorder = Color(0xFFAA7700);

  // GitHub brand
  static const Color githubBrandColor = Color(0xFF24292E);

  // Diff highlights (20% opacity overlays)
  static const Color diffAdditionBg = Color(0x3300CC66);
  static const Color diffDeletionBg = Color(0x33FF4444);

  // Foreground on accent-coloured surfaces (near-black for contrast on teal)
  static const Color onAccent = Color(0xFF0A0A0A);

  // Frosted surface (dialogs, snackbars — near-black with high opacity)
  static const Color frostedSurface = Color(0xF7161616);

  // Destructive action border (dark red outline for destructive buttons)
  static const Color destructiveBorder = Color(0xFF3D1515);

  // Panel/footer separator (divider between content area and footer)
  static const Color panelSeparator = Color(0xFF242424);

  // Icon in empty / inactive state (between mutedFg and faintFg)
  static const Color iconInactive = Color(0xFF444444);

  // ── Elevated Glass — dark tokens ─────────────────────────────────────────

  // Surface fills (frosted white tints)
  static const Color glassSurface = Color(0x06FFFFFF);
  static const Color chipSurface = Color(0x0AFFFFFF);
  static const Color fieldSurface = Color(0x0AFFFFFF);
  static const Color topBarSurface = Color(0x05FFFFFF);
  static const Color sendDisabledSurface = Color(0x0FFFFFFF);
  static const Color dialogSurface = Color(0xEB121212);

  // Borders (frosted white)
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color glassBorderSubtle = Color(0x0FFFFFFF);
  static const Color glassBorderFaint = Color(0x0DFFFFFF);
  static const Color chipBorder = Color(0x12FFFFFF);
  static const Color userBubbleBorder = Color(0x17FFFFFF);
  static const Color userBubbleHighlight = Color(0x12FFFFFF);
  static const Color dialogTopHighlight = Color(0x0FFFFFFF);
  static const Color fieldBorder = Color(0x1AFFFFFF);
  static const Color sendDisabledBorder = Color(0x2EFFFFFF);

  // Icon / text (disabled states)
  static const Color sendDisabledIcon = Color(0x59FFFFFF);

  // Accent tinted surfaces / borders
  static const Color chatBoxRimGlow = Color(0x124EC9B0);
  static const Color accentGlowBadge = Color(0x2E4EC9B0);
  static const Color accentBorderTeal = Color(0x4D4EC9B0);
  static const Color accentBorderAmber = Color(0x4DE8A228);
  static const Color sendGlow = Color(0x664EC9B0);
  static const Color fieldFocusGlow = Color(0x1F4EC9B0);

  // Code
  static const Color inlineCodeBg = Color(0xCC0D1117);

  // ── Elevated Glass — light tokens ────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightStatusBar = Color(0xFFE8EAEE);
  static const Color lightTopBarSurface = Color(0xCCF0F2F5);
  static const Color lightChatBoxSurface = Color(0xB8FFFFFF);
  static const Color lightChatBoxBorder = Color(0xE6FFFFFF);
  static const Color lightDialogSurface = Color(0xE0FFFFFF);
  static const Color lightDialogBorder = Color(0xF2FFFFFF);
  static const Color lightDialogHighlight = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0x0F000000);
  static const Color lightBorder = Color(0x17000000);
  static const Color lightText = Color(0xFF1E2329);
  static const Color lightTextSecondary = Color(0xFF3A424D);
  static const Color lightTextTertiary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9BA4B0);
  static const Color lightChipSurface = Color(0x0A000000);
  static const Color lightChipBorder = Color(0x1A000000);
  static const Color lightChipText = Color(0xFF7A8494);
  static const Color lightUserBubbleSurface = Color(0x1F4EC9B0);
  static const Color lightUserBubbleBorder = Color(0x4D4EC9B0);
  static const Color lightInlineCodeSurface = Color(0x1F4EC9B0);
  static const Color lightInlineCodeBorder = Color(0x334EC9B0);
  static const Color lightInlineCodeText = Color(0xFF2A7A6E);
  static const Color lightSendDisabledSurface = Color(0x0D000000);
  static const Color lightSendDisabledBorder = Color(0x21000000);
  static const Color lightSendDisabledIcon = Color(0x40000000);

  // Light-mode structural surfaces (no dark equivalents needed — dark uses named tokens above)
  static const Color lightSidebarBackground = Color(0xFFE8EAEE);
  static const Color lightActivityBar = Color(0xFFDFE1E6);
  static const Color lightPanelBackground = Color(0xFFF6F8FA);
  static const Color lightFrostedSurface = Color(0xF0FFFFFF);

  // Box shadow colours
  static const Color shadowDark = Color(0x99000000);
  static const Color shadowMedium = Color(0x66000000);
  // 70% black — heavy drop shadow (snackbar)
  static const Color shadowHeavy = Color(0xB3000000);
  // 85% black — deep dialog drop shadow
  static const Color shadowDeep = Color(0xD9000000);
  // 4% white — inner edge highlight on frosted surfaces
  static const Color innerGlow = Color(0x0AFFFFFF);

  // Tinted icon backgrounds (12.5% opacity) — snackbar icon wells
  static const Color successTintBg = Color(0x1F4EC9B0);
  static const Color errorTintBg = Color(0x1FF44747);
  static const Color warningTintBg = Color(0x1FCCA700);
  static const Color infoTintBg = Color(0x1F4FC1FF);

  // Tinted badge backgrounds (10% opacity) — file status badges (commit dialog)
  static const Color successBadgeBg = Color(0x1A4EC9B0);
  static const Color errorBadgeBg = Color(0x1AF44747);
  static const Color warningBadgeBg = Color(0x1ACCA700);

  // Branding panel gradient stops
  static const Color brandingGradientTop = Color(0xFF0E1A18);
  static const Color brandingGradientMid = Color(0xFF0A0E0D);

  // Branding panel accent glow (25% teal, logo badge shadow)
  static const Color accentGlow = Color(0x404EC9B0);

  // Branding panel tagline text (muted teal foreground)
  static const Color subtleTealFg = Color(0xFF4A6660);

  // Feature card tint fills (4% and 8% teal)
  static const Color accentTintLight = Color(0x0A4EC9B0);
  static const Color accentTintMid = Color(0x144EC9B0);

  // Icon sizes
  static const double iconSizeSmall = 14;
  static const double iconSizeMedium = 18;
  static const double iconSizeLarge = 24;

  // Top action bar: exact height of the small action buttons in the right-hand
  // cluster. Applied via BoxConstraints.tightFor(height: ...) to the _ActionButton
  // helper and both halves of the Commit/Push split button, so every button in
  // that row lines up exactly (minHeight alone leaves a 1px gap when one half's
  // content renders naturally taller than the other).
  static const double actionButtonHeight = 22;

  // Font
  static const String editorFontFamily = 'JetBrains Mono';
  static const double editorFontSize = 13;
  static const double uiFontSize = 12; // body: messages, sidebar titles
  static const double uiFontSizeSmall = 11; // secondary: chips, button labels
  static const double uiFontSizeLabel = 10; // labels: section headers, timestamps
  static const double uiFontSizeBadge = 9; // badges: git tag, provider badge
  static const double uiFontSizeLarge = 15;
}
