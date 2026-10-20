import SwiftUI
import SharedLogic

extension View {

    /// Presents whatever a component put into its Decompose slot as a sheet.
    ///
    /// Deliberately generic: it knows about "there is a modal or there isn't", never about
    /// which modals exist. Each screen keeps its own `Modal` hierarchy and maps it in
    /// `content`, so adding a modal never touches this file.
    ///
    /// The slot is the source of truth. `onDismiss` reports only the gestures SwiftUI owns —
    /// the downward swipe and a tap outside — because a modal closed by the component itself
    /// disappears when the slot empties. Calling it once more in that case is harmless:
    /// dismissing an already-empty slot is a no-op.
    @ViewBuilder
    func appModalSheet<Modal: AnyObject, ModalContent: View>(
        modal: Modal?,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping (Modal) -> ModalContent
    ) -> some View {
        self.sheet(
            isPresented: Binding(
                get: { modal != nil },
                set: { isPresented in
                    if !isPresented {
                        onDismiss()
                    }
                }
            )
        ) {
            if let modal {
                content(modal)
            }
        }
    }
}

extension View {

    /// The full-screen twin of `appModalSheet`, for a modal that owns the whole screen and
    /// takes drags of its own: a sheet's pull-down recognizer would swallow those.
    ///
    /// A full-screen cover has no swipe-down dismissal, so `onDismiss` here only reports a
    /// dismissal SwiftUI itself started; the component closes the modal through the slot.
    @ViewBuilder
    func appFullScreenModal<Modal: AnyObject, ModalContent: View>(
        modal: Modal?,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping (Modal) -> ModalContent
    ) -> some View {
        self.fullScreenCover(
            isPresented: Binding(
                get: { modal != nil },
                set: { isPresented in
                    if !isPresented {
                        onDismiss()
                    }
                }
            )
        ) {
            if let modal {
                content(modal)
            }
        }
    }
}
