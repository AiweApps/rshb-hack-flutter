import SwiftUI
import AVFoundation
import SharedLogic
import UniformTypeIdentifiers

struct ScanHomeView: View {
    @ObservedObject private var observableState: ObservableValue<ScanHomeState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, ScanHomeComponentModal>>
    @StateObject private var camera = CameraController()
    @State private var isVisible = false
    @State private var pickerPresentationID: UUID?
    @State private var pickerOperationID: UUID?
    @State private var pickerTask: Task<Void, Never>?
    @State private var cameraStartTask: Task<Void, Never>?
    @State private var captureTask: Task<Void, Never>?
    @State private var captureOperationID: UUID?
    @State private var focusMark: FocusMark?
    @State private var focusCount = 0
    /// Bumped when a shot is taken: the bottle pours and the viewfinder flashes white.
    @State private var shotCount = 0
    private let component: ScanHomeComponent

    init(component: ScanHomeComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value

        content
            .navigationTitle(String(localized: "tab_scan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(isViewfinderShown(state) ? .dark : nil, for: .navigationBar)
        .toastBanner(message: toastMessage(state), onConsumed: component.onToastConsumed)
        .appModalSheet(modal: modalSlot.value.child?.instance, onDismiss: component.onModalDismissed) { modal in
            if let detail = modal as? ScanHomeComponentModal.ServiceDetail {
                ServiceDetailSheetView(component: detail.component)
            }
        }
        .background {
            PhotoLibraryPicker(requestID: pickerPresentationID, onFinish: pickerFinished)
                .frame(width: 0, height: 0)
        }
        .onAppear {
            isVisible = true
            startCameraIfNeeded()
            if state.isPicking { beginPicking() }
        }
        .onDisappear {
            isVisible = false
            cancelPicking()
            stopCamera()
        }
        .onChange(of: state.isCameraWanted, initial: true) { _, wanted in
            wanted ? startCameraIfNeeded() : stopCamera()
        }
        .onChange(of: state.cameraStatus == CameraStatus.starting) { _, _ in startCameraIfNeeded() }
        .onChange(of: state.permissionRequestTicket) { _, _ in startCameraIfNeeded(force: true) }
        .onChange(of: state.isCapturing) { _, capturing in
            if capturing {
                shotCount += 1
                capturePhoto()
            }
        }
        .onChange(of: state.isPicking) { _, picking in
            if picking { beginPicking() } else { cancelPicking() }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: focusCount)
        .sensoryFeedback(trigger: state.toast) { _, toast in toast == nil ? nil : .warning }
    }

    @ViewBuilder
    private var content: some View {
        let state = observableState.value
        let screenState = state.screenState

        if screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: nil)
        } else if screenState is ScreenState.Content {
            mainContent(state: state)
        }
    }

    @ViewBuilder
    private func mainContent(state: ScanHomeState) -> some View {
        if isViewfinderShown(state) {
            ZStack {
                AppTheme.scrim.ignoresSafeArea()
                // The overlay is laid out before ignoring the safe area, so it shares the
                // preview's full-screen coordinates; the other way round it starts under the
                // navigation bar and the square lands below the tap.
                CameraPreviewView(session: camera.session, onTap: focus)
                    .overlay { FocusSquareView(mark: $focusMark) }
                    .ignoresSafeArea()
                ShotFlash(trigger: shotCount)
            }
            .safeAreaInset(edge: .bottom) {
                CameraControlsBar(
                    isFlashOn: state.isFlashOn,
                    hasFlash: camera.hasFlash,
                    isCapturing: state.isCapturing,
                    isBusy: state.isBusy || state.cameraStatus != CameraStatus.ready,
                    look: ShutterLook(state.shutterMood),
                    hint: HintKind(state.statusHint),
                    queueAhead: Int(state.queueAhead),
                    isHintShown: state.isHintShown,
                    refusedTicket: Int(state.refusedShotTicket),
                    shotCount: shotCount,
                    onPickPhoto: component.onPickPhotoClicked,
                    onShutter: component.onShutterClicked,
                    onFlash: component.onFlashClicked,
                    onStatusHint: component.onStatusHintClicked
                )
            }
        } else {
            CameraUnavailableView(
                status: state.cameraStatus,
                recent: state.recent,
                isBusy: state.isBusy,
                onOpenSettings: component.onOpenSettingsClicked,
                onPickPhoto: component.onPickPhotoClicked,
                onRecentTap: { component.onRecentScanClicked(scanId: $0) },
                onAllScans: component.onAllScansClicked
            )
        }
    }

    private func isViewfinderShown(_ state: ScanHomeState) -> Bool {
        state.cameraStatus == CameraStatus.starting || state.cameraStatus == CameraStatus.ready
    }

    private func toastMessage(_ state: ScanHomeState) -> String? {
        state.toast == ScanHomeToast.photoOpenFailed ? String(localized: "scan_error_photo_open") : nil
    }
}

// MARK: - Platform glue: camera session, capture and the photo picker

private extension ScanHomeView {

    func startCameraIfNeeded(force: Bool = false) {
        let state = observableState.value
        guard isVisible, state.isCameraWanted else { return }
        cameraStartTask?.cancel()
        if state.cameraStatus == CameraStatus.starting || force {
            cameraStartTask = Task {
                let availability = await CameraAccess.resolve(camera: camera)
                guard !Task.isCancelled, isVisible, observableState.value.isCameraWanted else { return }
                component.onCameraAvailabilityReported(availability: availability)
            }
        } else if state.cameraStatus == CameraStatus.ready {
            cameraStartTask = Task { _ = await camera.start() }
        } else if (state.cameraStatus == CameraStatus.denied || state.cameraStatus == CameraStatus.permanentlyDenied),
                  AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            // Returning from Settings resumes the component with its old refusal state.
            // Read an existing grant only; this path must never show a permission prompt.
            cameraStartTask = Task {
                let availability: CameraAvailability = await camera.start() ? .ready : .unavailable
                guard !Task.isCancelled, isVisible, observableState.value.isCameraWanted else { return }
                component.onCameraAvailabilityReported(availability: availability)
            }
        }
    }

    func stopCamera() {
        cameraStartTask?.cancel()
        cameraStartTask = nil
        captureTask?.cancel()
        captureTask = nil
        let hadCapture = captureOperationID != nil
        captureOperationID = nil
        focusMark = nil
        camera.stop()
        if hadCapture, observableState.value.isCapturing { component.onCaptureFailed() }
    }

    func capturePhoto() {
        guard isVisible, observableState.value.isCameraWanted, captureOperationID == nil else { return }
        let operationID = UUID()
        captureOperationID = operationID
        let flashOn = observableState.value.isFlashOn
        captureTask = Task {
            let data = await camera.capture(flashOn: flashOn)
            guard isCurrentCapture(operationID) else { return }
            let path: String?
            if let data { path = await prepare(data: data) } else { path = nil }
            guard isCurrentCapture(operationID) else {
                if let path { try? FileManager.default.removeItem(atPath: path) }
                return
            }
            captureOperationID = nil
            captureTask = nil
            if let path {
                component.onPhotoCaptured(photoPath: path)
            } else {
                component.onCaptureFailed()
            }
        }
    }

    func isCurrentCapture(_ operationID: UUID) -> Bool {
        !Task.isCancelled && isVisible && captureOperationID == operationID
    }

    func focus(at viewPoint: CGPoint, devicePoint: CGPoint) {
        guard isVisible, observableState.value.isCameraWanted else { return }
        camera.focus(atDevicePoint: devicePoint)
        focusCount += 1
        focusMark = FocusMark(id: focusCount, point: viewPoint)
    }

    func beginPicking() {
        guard isVisible, pickerOperationID == nil else { return }
        let operationID = UUID()
        pickerOperationID = operationID
        pickerPresentationID = operationID
    }

    func pickerFinished(_ operationID: UUID, provider: NSItemProvider?) {
        guard isVisible, pickerOperationID == operationID, observableState.value.isPicking else { return }
        pickerPresentationID = nil
        guard let provider else {
            pickerOperationID = nil
            component.onPhotoPicked(photoPath: nil)
            return
        }
        pickerTask = Task {
            let data = await PhotoLibraryImageRequest().load(from: provider)
            guard isCurrentPick(operationID) else { return }
            let path: String?
            if let data { path = await prepare(data: data) } else { path = nil }
            guard isCurrentPick(operationID) else {
                if let path { try? FileManager.default.removeItem(atPath: path) }
                return
            }
            pickerOperationID = nil
            pickerTask = nil
            if let path {
                component.onPhotoPicked(photoPath: path)
            } else {
                component.onPhotoPickFailed()
            }
        }
    }

    func isCurrentPick(_ operationID: UUID) -> Bool {
        !Task.isCancelled && isVisible && pickerOperationID == operationID && observableState.value.isPicking
    }

    func cancelPicking() {
        let hadOperation = pickerOperationID != nil
        pickerOperationID = nil
        pickerPresentationID = nil
        pickerTask?.cancel()
        pickerTask = nil
        if hadOperation, observableState.value.isPicking { component.onPhotoPicked(photoPath: nil) }
    }

    func prepare(data: Data) async -> String? {
        await Task.detached(priority: .userInitiated) {
            PhotoPreparer.prepare(data: data)
        }.value
    }
}
