/// State of the cloud sync indicator on Home and Settings.
enum SyncStatus {
  synced,
  syncing,

  /// No connection; shifts wait on the phone ("Offline · 2 shifts waiting").
  offline,

  /// The last sync attempt failed ("Sync could not finish · Retry").
  failed,
}
