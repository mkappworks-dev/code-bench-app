import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project_sidebar/notifiers/project_sidebar_actions.dart';

/// Returns `true` if the project folder at [projectPath] currently exists on
/// disk. When the folder is missing:
///  • Shows a snackbar directing the user to Relocate or Remove the project.
///  • Fires a background status refresh so the sidebar flips to the "missing"
///    visual state on the next Drift stream emission.
///  • Returns `false` so the caller can abort the pending action.
///
/// Checks the filesystem directly — does NOT rely on cached `project.status`,
/// which may be stale.
bool ensureProjectAvailable(BuildContext context, WidgetRef ref, String projectId, String projectPath) {
  if (ref.read(projectSidebarActionsProvider.notifier).projectExistsOnDisk(projectPath)) return true;
  // Fire-and-forget: the snackbar shows immediately; the sidebar re-render
  // follows on the next Drift stream emission. Swallow errors here so this
  // background refresh cannot surface as an uncaught exception.
  unawaited(ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(projectId).catchError((Object _) {}));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'This project folder is missing. Right-click the project in the '
        'sidebar to Relocate or Remove it.',
      ),
      duration: Duration(seconds: 4),
    ),
  );
  return false;
}
