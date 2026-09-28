/// What a widget needs to load a catalogue reference image: the API origin the
/// relative `reference` path resolves against, and the Bearer header the
/// image endpoint requires. Produced by the repository, carried in the state.
class ReferenceAccess {
  final String baseUrl;
  final Map<String, String> headers;

  const ReferenceAccess({required this.baseUrl, required this.headers});

  String? resolve(String? reference) {
    if (reference == null || reference.isEmpty) return null;
    if (reference.startsWith('http')) return reference;
    return '$baseUrl$reference';
  }
}
