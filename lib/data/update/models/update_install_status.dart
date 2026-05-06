/// Outcome of a previous install attempt, persisted by the relaunch script
/// to a sentinel file under Application Support so the new process can read
/// it on next launch and surface failures the parent process couldn't.
typedef UpdateInstallStatus = ({String status, String detail, String timestamp});
