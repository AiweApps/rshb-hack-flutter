import SwiftUI
import SharedLogic

struct ScannerBackendSection: View {
    let backend: ScannerBackendState
    let onSelected: (ScannerBackend) -> Void
    let onDownload: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Section {
            Picker(String(localized: "settings_scanner_backend"), selection: Binding(
                get: { backend.selected }, set: onSelected
            )) {
                Text(String(localized: "scanner_backend_server")).tag(ScannerBackend.server)
                Text(String(localized: "scanner_backend_local")).tag(ScannerBackend.local)
                    .disabled(!backend.localAvailable)
            }
            if backend.localModel.isBusy {
                HStack {
                    ProgressView()
                    Text(NSLocalizedString("local_model_" + backend.localModel.phase, comment: "Model package stage"))
                }
                if backend.localModel.totalBytes > 0 && backend.localModel.phase != "verifying" {
                    ProgressView(value: Double(backend.localModel.receivedBytes), total: Double(backend.localModel.totalBytes))
                    Text(ByteCountFormatter.string(fromByteCount: backend.localModel.receivedBytes, countStyle: .file) + " / " +
                         ByteCountFormatter.string(fromByteCount: backend.localModel.totalBytes, countStyle: .file))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button(String(localized: "local_model_cancel"), action: onCancel)
            } else if !backend.localAvailable {
                Button(action: onDownload) {
                    Label(downloadTitle, appSymbol: "arrow.down.circle")
                }
                if let error = backend.localModel.error, error != "cancelled" {
                    Text(String(localized: error == "storage_full" ? "local_model_no_space" : "local_model_download_error"))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Label(String(localized: "local_model_ready"), appSymbol: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "settings_scanner_backend"))
        } footer: {
            Text(String(localized: backend.selected == .local && !backend.localAvailable ? "local_model_required_note" :
                (backend.selected == .local ? "scanner_backend_local_note" : "scanner_backend_server_note")))
        }
    }

    private var downloadTitle: String {
        let title = String(localized: "local_model_download")
        guard backend.localModel.totalBytes > 0 else { return title }
        return title + " · " + ByteCountFormatter.string(fromByteCount: backend.localModel.totalBytes, countStyle: .file)
    }
}
