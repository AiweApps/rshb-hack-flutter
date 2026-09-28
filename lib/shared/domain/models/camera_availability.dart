/// Whether the viewfinder can run — what `CameraService.start` reports.
enum CameraAvailability {
  ready,

  /// Refused once; the system will ask again.
  denied,

  /// Refused for good; only the system settings can change it.
  permanentlyDenied,

  /// No camera on this device (a simulator, a tablet without one).
  unavailable,
}
