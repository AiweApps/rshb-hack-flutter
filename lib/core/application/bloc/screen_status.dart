/// Coarse status of a screen, meant to live inside a bloc state.
///
/// Lets the UI switch between a loader, the content and an error placeholder
/// without every state re-inventing its own `isLoading` / `hasError` flags.
enum ScreenStatus { loading, content, error }
