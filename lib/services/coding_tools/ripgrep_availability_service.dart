import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/coding_tools/datasource/ripgrep_availability_datasource_process.dart';

part 'ripgrep_availability_service.g.dart';

/// Returns true if ripgrep (`rg`) is installed. Cached for the session.
/// The user can force a re-check via [RipgrepAvailabilityNotifier.recheck].
@Riverpod(keepAlive: true)
Future<bool> ripgrepAvailability(Ref ref) => RipgrepAvailabilityDatasource().isAvailable();
