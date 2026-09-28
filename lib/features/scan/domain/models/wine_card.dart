import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';

part 'wine_card.freezed.dart';
part 'wine_card.g.dart';

/// One catalogue card as the recognition API returns it (`Catalog.card()`).
///
/// Mirrors the backend one to one and is also what the history stores, so it
/// is both DTO and domain model. [title] is always present (the slug when the
/// name is unknown); everything else may be missing from the catalogue row.
@freezed
abstract class WineCard with _$WineCard {
  const factory WineCard({
    required String slug,
    required String title,
    @JsonKey(name: 'in_catalog') @Default(true) bool inCatalog,
    String? name,
    String? producer,
    String? category,
    String? region,
    String? grapes,
    @JsonKey(name: 'page_url') String? pageUrl,
    @JsonKey(name: 'page_source') String? pageSource,
    @JsonKey(name: 'page_in_site_snapshot') bool? pageInSiteSnapshot,

    /// Relative path of the reference thumbnail (`/api/reference/<slug>.jpg`),
    /// resolved against the API origin by the repository.
    String? reference,
  }) = _WineCard;

  const WineCard._();

  factory WineCard.fromJson(Map<String, dynamic> json) =>
      _$WineCardFromJson(json);

  /// Only catalogue pages are offered as a link, the same rule as the web UI.
  String? get catalogueUrl {
    final url = pageUrl;
    if (url == null || !url.startsWith(LinkConstants.vinoSvoeWinesPrefix)) {
      return null;
    }
    return url;
  }

  /// "category · region · grapes", skipping what is missing.
  String get metaLine => [
    category,
    region,
    grapes,
  ].nonNulls.where((s) => s.isNotEmpty).join(' · ');
}
