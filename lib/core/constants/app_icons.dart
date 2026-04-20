import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central icon registry. All icon usage in the app goes through this class.
/// To switch icon packages, update the values here only.
abstract final class AppIcons {
  // Navigation / chevrons
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowUpDown = LucideIcons.arrowUpDown;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData close = LucideIcons.x;
  static const IconData trash = LucideIcons.trash2;
  static const IconData revert = LucideIcons.undo2;
  static const IconData check = LucideIcons.check;
  static const IconData copy = LucideIcons.copy;
  static const IconData run = LucideIcons.play;
  static const IconData stop = LucideIcons.squareDot;
  static const IconData apply = LucideIcons.download;
  static const IconData applying = LucideIcons.hourglass;
  static const IconData sort = LucideIcons.arrowUpDown;

  // Visibility / auth
  static const IconData showSecret = LucideIcons.eye;
  static const IconData hideSecret = LucideIcons.eyeOff;
  static const IconData lock = LucideIcons.lock;

  // Content / files
  static const IconData code = LucideIcons.code;
  static const IconData folder = LucideIcons.folder;
  static const IconData folderOpen = LucideIcons.folderOpen;
  static const IconData terminal = LucideIcons.terminal;
  static const IconData archive = LucideIcons.archive;
  static const IconData archiveRestore = LucideIcons.archiveRestore;
  static const IconData storage = LucideIcons.hardDrive;
  static const IconData rename = LucideIcons.pencil;

  // Chat / AI
  static const IconData chat = LucideIcons.messageSquare;
  static const IconData newChat = LucideIcons.messageSquarePlus;
  static const IconData aiMode = LucideIcons.zap;

  // Git
  static const IconData gitMerge = LucideIcons.gitMerge;
  static const IconData gitCommit = LucideIcons.gitCommitHorizontal;
  static const IconData gitDiff = LucideIcons.gitCompare;
  static const IconData gitBranch = LucideIcons.gitBranch;
  static const IconData cloudUpload = LucideIcons.cloudUpload;
  static const IconData gitPullRequest = LucideIcons.gitPullRequest;

  // UI chrome
  static const IconData settings = LucideIcons.settings;
  static const IconData warning = LucideIcons.triangleAlert;
}
