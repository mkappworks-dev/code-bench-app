/// Snapshot of the user's effective denylist (defaults + userAdded −
/// suppressedDefaults). Loaded once per [ToolRegistryService.execute] call
/// and embedded in every [ToolContext] for the duration of that call.
typedef EffectiveDenylist = ({
  Set<String> segments,
  Set<String> filenames,
  Set<String> extensions,
  Set<String> prefixes,
});
