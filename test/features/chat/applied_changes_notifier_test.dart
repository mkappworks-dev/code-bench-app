import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/models/applied_change.dart';
import 'package:code_bench_app/features/chat/notifiers/chat_notifier.dart';

AppliedChange _change({
  String id = 'c1',
  String sessionId = 'sid',
  String messageId = 'mid',
  String filePath = '/tmp/foo.dart',
  String newContent = 'new',
  String? originalContent = 'old',
}) => AppliedChange(
  id: id,
  sessionId: sessionId,
  messageId: messageId,
  filePath: filePath,
  originalContent: originalContent,
  newContent: newContent,
  appliedAt: DateTime(2026),
);

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('apply adds change to correct session', () {
    final notifier = container.read(appliedChangesProvider.notifier);
    notifier.apply(_change(sessionId: 'sid', id: 'c1'));
    notifier.apply(_change(sessionId: 'sid', id: 'c2'));
    notifier.apply(_change(sessionId: 'other', id: 'c3'));

    final forSid = container.read(appliedChangesProvider)['sid']!;
    expect(forSid.length, 2);
    expect(forSid.map((c) => c.id), containsAll(['c1', 'c2']));

    final forOther = container.read(appliedChangesProvider)['other']!;
    expect(forOther.length, 1);
  });

  test('revert removes the change by id', () {
    final notifier = container.read(appliedChangesProvider.notifier);
    notifier.apply(_change(id: 'c1'));
    notifier.apply(_change(id: 'c2'));
    notifier.revert('c1');

    final changes = container.read(appliedChangesProvider)['sid']!;
    expect(changes.map((c) => c.id), ['c2']);
  });

  test('revert removes session key when last change is reverted', () {
    final notifier = container.read(appliedChangesProvider.notifier);
    notifier.apply(_change(sessionId: 'sid', id: 'c1'));
    notifier.revert('c1');

    // Session key must be pruned entirely — not left as an empty list
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('changesForSession returns empty list when no changes', () {
    final notifier = container.read(appliedChangesProvider.notifier);
    expect(notifier.changesForSession('nobody'), isEmpty);
  });

  test('revert does not affect other sessions', () {
    final notifier = container.read(appliedChangesProvider.notifier);
    notifier.apply(_change(sessionId: 'sid', id: 'c1'));
    notifier.apply(_change(sessionId: 'other', id: 'c2'));
    notifier.revert('c1');

    // 'other' must still have c2 intact
    expect(container.read(appliedChangesProvider)['other']!.map((c) => c.id), ['c2']);
    // 'sid' should now be removed from map entirely after the fix
    expect(container.read(appliedChangesProvider)['sid'], isNull);
  });

  test('ChangesPanelVisible toggles', () {
    final notifier = container.read(changesPanelVisibleProvider.notifier);
    expect(container.read(changesPanelVisibleProvider), false);
    notifier.toggle();
    expect(container.read(changesPanelVisibleProvider), true);
    notifier.toggle();
    expect(container.read(changesPanelVisibleProvider), false);
  });

  test('ChangesPanelVisible hide() sets to false', () {
    final notifier = container.read(changesPanelVisibleProvider.notifier);
    notifier.toggle(); // now true
    notifier.hide();
    expect(container.read(changesPanelVisibleProvider), false);
  });

  test('ChangesPanelVisible show() sets to true', () {
    final notifier = container.read(changesPanelVisibleProvider.notifier);
    expect(container.read(changesPanelVisibleProvider), false);
    notifier.show();
    expect(container.read(changesPanelVisibleProvider), true);
  });
}
