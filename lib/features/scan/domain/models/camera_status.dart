/// What the scan tab shows instead of, or as, the viewfinder.
enum CameraStatus {
  /// Not decided yet, or the camera was stopped while the tab was away.
  starting,
  ready,
  denied,
  permanentlyDenied,
  unavailable,
}
