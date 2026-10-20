import SwiftUI
import SharedLogic

struct AssistantMessageView: View {
    @State private var expandedProductIds: Set<String> = []
    @State private var expandedDinnerIds: Set<String> = []
    @State private var isTextExpanded = false
    @State private var fullTextHeight: CGFloat = 0
    @State private var shownTextHeight: CGFloat = 0
    let message: AssistantMessage
    let referenceAccess: ReferenceAccess?
    let selectedWineIdentity: AssistantWineIdentity?
    let savedWineIdentities: Set<AssistantWineIdentity>
    let selectedDinnerOptionId: String?
    let canSelectDinner: Bool
    let onWineSelect: (AssistantWine) -> Void
    let onWineFavorite: (AssistantWine) -> Void
    let onWineCompare: (AssistantWine) -> Void
    let onDinnerSelect: (String) -> Void
    let onReplacementRequest: (String, String) -> Void
    let onReplacementCandidateSelect: (String, String, String) -> Void
    let onRetry: () -> Void
    let onLink: (String) -> Void
    let onPhotoTap: (AssistantPhoto, [AssistantPhoto]) -> Void
    var canRetryMessage: Bool = true
    var canUseProducts: Bool = true
    var onOpenRetailSite: (() -> Void)? = nil
    /// The reply has a structured basket below it, so its prose may fold to a short lead.
    var foldsText = false

    private func purchaseQuantityText(_ product: AssistantProduct) -> String {
        guard product.hasKnownPurchaseQuantity, let amount = product.purchaseLotQuantity,
              let unit = product.purchaseLotUnit else { return String(localized: "assistant_product_unknown_quantity") }
        let quantity = amount.doubleValue.formatted(.number.precision(.fractionLength(0...6)))
        if Int(product.quantity) == 1 {
            return String(format: String(localized: "assistant_product_purchase_lot_single"), quantity, unit)
        }
        return String(format: String(localized: "assistant_product_purchase_lot"), Int(product.quantity), quantity, unit)
    }

    private func unitPriceText(_ product: AssistantProduct, price: KotlinLong) -> String {
        let key = product.priceBasis == "piece" ? "assistant_product_price_piece" :
            (product.priceBasis == "weight" ? "assistant_product_price_kg" : "assistant_product_price_unknown_basis")
        return String(format: String(localized: String.LocalizationValue(key)), AssistantPrice.text(price))
    }

    var body: some View {
        Group {
            if message.kind == AssistantMessageKind.userText {
                userBubble
            } else if message.kind == AssistantMessageKind.userPhotos {
                photoAlbum
            } else if message.kind == AssistantMessageKind.wineResults {
                wineResults
            } else if message.kind == AssistantMessageKind.dinnerOptions {
                dinnerOptions
            } else if message.kind == AssistantMessageKind.products {
                products
            } else if message.kind == AssistantMessageKind.status {
                status
            } else if message.kind == AssistantMessageKind.error {
                error
            } else if foldsText {
                foldableAssistantText
            } else {
                assistantText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 44)
            Text(message.text)
                .font(.body)
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.paper2, in: UnevenRoundedRectangle(
                    topLeadingRadius: 20, bottomLeadingRadius: 20,
                    bottomTrailingRadius: 6, topTrailingRadius: 20
                ))
        }
    }

    private var photoAlbum: some View {
        HStack {
            Spacer(minLength: 24)
            VStack(alignment: .trailing, spacing: 8) {
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink2)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(message.photos, id: \.id) { photo in
                            Button { onPhotoTap(photo, message.photos) } label: {
                                LocalPhotoView(path: photo.path, maxPixel: 320) {
                                    Rectangle().fill(AppTheme.paper2)
                                }
                                .frame(width: 100, height: 132)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "assistant_view_photo"))
                        }
                    }
                }
                // A horizontal scroller has no intrinsic vertical limit in a lazy chat row.
                // Small albums also need their actual width, so the leading spacer can align them right.
                .frame(
                    width: message.photos.count <= 2
                        ? CGFloat(message.photos.count * 100 + max(0, message.photos.count - 1) * 6)
                        : nil,
                    height: 132
                )
            }
        }
    }

    private var assistantText: some View {
        Text(message.text)
            .font(.body)
            .foregroundStyle(AppTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 2)
    }

    // The full text is measured hidden behind the folded one; the toggle shows only when lines are cut.
    private var foldableAssistantText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.text)
                .font(.body)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(isTextExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
                .background(alignment: .topLeading) {
                    Text(message.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullTextHeight = $0 }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shownTextHeight = $0 }
                .padding(.horizontal, 2)
            if isTextExpanded || fullTextHeight > shownTextHeight + 1 {
                Button { isTextExpanded.toggle() } label: {
                    HStack(spacing: 4) {
                        Text(String(localized: isTextExpanded ? "compare_hide_description" : "compare_show_description"))
                        AppIcon(systemName: isTextExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.regular))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .font(.footnote)
                .foregroundStyle(AppTheme.ink2)
            }
        }
    }

    private var status: some View {
        HStack(spacing: 8) {
            AppIcon(systemName: "checkmark.circle")
                .foregroundStyle(AppTheme.ok)
            Text(message.text)
                .foregroundStyle(AppTheme.ink2)
        }
        .font(.footnote)
    }

    private var error: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(message.errorCode.map(assistantErrorMessage) ?? String(localized: "assistant_error_generic"),
                  appSymbol: "exclamationmark.circle")
                .font(.footnote)
                .foregroundStyle(AppTheme.bad)
                .fixedSize(horizontal: false, vertical: true)
            if canRetryMessage {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { retailRecoveryAction; retryAction }
                        .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: 0) { retailRecoveryAction; retryAction }
                }
                .buttonStyle(.plain)
                .font(.footnote.weight(.medium))
            }
        }
        .padding(12)
        .appMatteCard(cornerRadius: 16)
    }

    @ViewBuilder
    private var retailRecoveryAction: some View {
        if message.errorCode == AssistantUiError.retailAccessRequired, let onOpenRetailSite {
            Button(String(localized: "retail_device_open"), action: onOpenRetailSite)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(AppTheme.wine)
        }
    }

    private var retryAction: some View {
        Button(String(localized: message.errorCode == AssistantUiError.retailAccessRequired
            ? "assistant_retry_after_access" : "assistant_retry"), action: onRetry)
            .frame(minWidth: 44, minHeight: 44)
            .foregroundStyle(AppTheme.ink2)
    }

    private var wineResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !message.text.isEmpty { assistantText }
            if message.comparisonContext {
                Text(String(localized: "assistant_v3_from_comparison"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 2)
            }
            ForEach(message.wines, id: \.presentationIdentity) { wine in
                AssistantWineCardView(
                    wine: wine,
                    referenceAccess: referenceAccess,
                    isSaved: savedWineIdentities.contains(wine.presentationIdentity),
                    isSelected: selectedWineIdentity == wine.presentationIdentity,
                    onSelect: { onWineSelect(wine) },
                    onFavorite: { onWineFavorite(wine) },
                    onCompare: { onWineCompare(wine) },
                    onLink: onLink,
                    isComparisonContext: message.comparisonContext,
                    onSourcePhoto: sourcePhoto(for: wine).map { photo in
                        { onPhotoTap(photo, [photo]) }
                    }
                )
            }
        }
    }

    private func sourcePhoto(for wine: AssistantWine) -> AssistantPhoto? {
        guard let id = wine.photoId, !id.isEmpty,
              let path = wine.photoPath, !path.isEmpty else { return nil }
        return AssistantPhoto(id: id, path: path, name: wine.title)
    }

    private var dinnerOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !message.text.isEmpty { assistantText }
            sourceNote
            ForEach(message.dinners, id: \.id) { dinner in
                let isSelected = dinner.remoteOptionId != nil && dinner.remoteOptionId == selectedDinnerOptionId
                let expanded = expandedDinnerIds.contains(dinner.id)
                VStack(alignment: .leading, spacing: 8) {
                    Text(dinner.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    // Price is the server's verified purchase total, never an ingredient estimate.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { dinnerTime(dinner); dinnerPrice(dinner) }
                        VStack(alignment: .leading, spacing: 4) { dinnerTime(dinner); dinnerPrice(dinner) }
                    }
                    Text(dinner.explanation)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let caveat = dinner.caveat, !caveat.isEmpty {
                        Label(caveat, appSymbol: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            dinnerChoice(dinner, selected: isSelected)
                            Spacer(minLength: 0)
                            dinnerDisclosure(dinner, expanded: expanded)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            dinnerChoice(dinner, selected: isSelected)
                            dinnerDisclosure(dinner, expanded: expanded)
                        }
                    }
                    if expanded {
                        ForEach(dinner.products.indices, id: \.self) { index in
                            let product = dinner.products[index]
                            HStack(alignment: .top, spacing: 10) {
                                productThumbnail(product)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.ink)
                                    ViewThatFits(in: .horizontal) {
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            dinnerProductPrice(product)
                                            productPurchaseQuantity(product)
                                            dinnerRecipeQuantity(product)
                                        }
                                        .fixedSize(horizontal: true, vertical: false)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                                dinnerProductPrice(product)
                                                productPurchaseQuantity(product)
                                            }
                                            .fixedSize(horizontal: true, vertical: false)
                                            dinnerRecipeQuantity(product)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            dinnerProductPrice(product)
                                            productPurchaseQuantity(product)
                                            dinnerRecipeQuantity(product)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(12)
                .appMatteCard(cornerRadius: 16)
            }
        }
    }

    @ViewBuilder
    private func dinnerTime(_ dinner: AssistantDinner) -> some View {
        if let minutes = dinner.preparationMinutes {
            Label(String(format: String(localized: "assistant_minutes_format"), Int(truncating: minutes)), appSymbol: "clock")
                .font(.footnote)
                .foregroundStyle(AppTheme.ink2)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func dinnerPrice(_ dinner: AssistantDinner) -> some View {
        Text(dinner.displayTotalKopeks.map(AssistantPrice.text) ?? String(localized: "assistant_product_unknown_total"))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func dinnerProductPrice(_ product: AssistantProduct) -> some View {
        if let price = product.displayLineTotalKopeks {
            Text(AssistantPrice.text(price))
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.ink)
        } else {
            Text(String(localized: "assistant_product_unknown_total"))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
    }

    @ViewBuilder
    private func dinnerRecipeQuantity(_ product: AssistantProduct) -> some View {
        if let recipe = product.recipeQuantity, !recipe.isEmpty {
            Text(String(format: String(localized: "assistant_recipe_quantity_format"), recipe))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private func dinnerChoice(_ dinner: AssistantDinner, selected: Bool) -> some View {
        Button { onDinnerSelect(dinner.id) } label: {
            HStack(spacing: 4) {
                if selected {
                    AppIcon(systemName: "checkmark").font(.footnote.weight(.regular))
                }
                Text(String(localized: selected ? "assistant_dinner_selected" : "assistant_ios_select_dinner"))
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.footnote.weight(.medium))
        .foregroundStyle(selected ? AppTheme.ink2 : AppTheme.wine)
        .disabled(!canSelectDinner || selected)
    }

    private func dinnerDisclosure(_ dinner: AssistantDinner, expanded: Bool) -> some View {
        Button { toggle(dinner.id, in: &expandedDinnerIds) } label: {
            HStack(spacing: 4) {
                Text(String(localized: expanded ? "compare_hide_description" : "assistant_dinner_products"))
                AppIcon(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.regular))
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(AppTheme.ink2)
    }

    private var products: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.replacementForProductId != nil {
                Text(String(localized: "assistant_replacement_candidates"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .padding(.bottom, 4)
            }
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.bottom, 8)
            }
            // Keep the total and provenance before the rows, so long carts do not hide them.
            if !message.products.isEmpty, let total = message.displayTotalKopeks {
                HStack {
                    Text(String(localized: "assistant_products_total"))
                    Spacer(minLength: 8)
                    Text(AssistantPrice.text(total)).fixedSize()
                }
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 6)
            } else if isShoppingList {
                Text(String(localized: "assistant_product_unknown_total"))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.bottom, 6)
            }
            sourceNote.padding(.bottom, 8)
            if message.products.isEmpty {
                Label(String(localized: "assistant_products_empty"), appSymbol: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
            } else {
                ForEach(message.products, id: \.id) { product in
                    productRow(product)
                    if product.id != message.products.last?.id {
                        Divider().overlay(AppTheme.rule.opacity(0.6))
                    }
                }
            }
        }
        .padding(12)
        .appMatteCard(cornerRadius: 16)
    }

    private var isShoppingList: Bool {
        message.sourceMessageId != nil && message.replacementForProductId == nil
    }

    private func productRow(_ product: AssistantProduct) -> some View {
        let expanded = expandedProductIds.contains(product.id)
        let isCandidate = message.replacementForProductId != nil
        let hasDetails = (isShoppingList && product.unitPriceKopeks != nil) ||
            hasDistinctPack(product) ||
            product.recipeQuantity?.isEmpty == false || product.url?.isEmpty == false
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 10) {
                productThumbnail(product)
                VStack(alignment: .leading, spacing: 0) {
                    Text(product.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) {
                            productFactsLine(product)
                            Spacer(minLength: 0)
                            productReplacementAction(product, isCandidate: isCandidate)
                            productDetailsAction(product, expanded: expanded, hasDetails: hasDetails)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            productFacts(product)
                            productActions(product, isCandidate: isCandidate, expanded: expanded, hasDetails: hasDetails)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if expanded {
                if isShoppingList, let price = product.unitPriceKopeks {
                    Text(unitPriceText(product, price: price))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.ink2)
                }
                if hasDistinctPack(product), let pack = product.pack {
                    Text(pack).font(.footnote).foregroundStyle(AppTheme.muted)
                }
                if let recipe = product.recipeQuantity, !recipe.isEmpty {
                    Text(String(format: String(localized: "assistant_recipe_quantity_format"), recipe))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
                if let url = product.url, !url.isEmpty {
                    Button { onLink(url) } label: {
                        Label(String(localized: "assistant_open_product"), appSymbol: "arrow.up.right")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink2)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func productFactsLine(_ product: AssistantProduct) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if isShoppingList {
                productPurchasePrice(product)
                productPurchaseQuantity(product)
            } else {
                productUnitPrice(product)
            }
            productAvailability(product)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func productFacts(_ product: AssistantProduct) -> some View {
        ViewThatFits(in: .horizontal) {
            productFactsLine(product)
            VStack(alignment: .leading, spacing: 2) {
                if isShoppingList {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        productPurchasePrice(product)
                        productPurchaseQuantity(product)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                } else {
                    productUnitPrice(product)
                }
                productAvailability(product)
            }
            VStack(alignment: .leading, spacing: 2) {
                if isShoppingList {
                    productPurchasePrice(product)
                    productPurchaseQuantity(product)
                } else {
                    productUnitPrice(product)
                }
                productAvailability(product)
            }
        }
    }

    private func productActions(_ product: AssistantProduct, isCandidate: Bool, expanded: Bool, hasDetails: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                productReplacementAction(product, isCandidate: isCandidate)
                Spacer(minLength: 0)
                productDetailsAction(product, expanded: expanded, hasDetails: hasDetails)
            }
            VStack(alignment: .leading, spacing: 0) {
                productReplacementAction(product, isCandidate: isCandidate)
                productDetailsAction(product, expanded: expanded, hasDetails: hasDetails)
            }
        }
    }

    @ViewBuilder
    private func productReplacementAction(_ product: AssistantProduct, isCandidate: Bool) -> some View {
        if isShoppingList || isCandidate {
            Button {
                if isCandidate { onReplacementCandidateSelect(message.id, message.replacementForProductId ?? "", product.id) }
                else { onReplacementRequest(message.id, product.id) }
            } label: {
                Text(String(localized: isCandidate ? "assistant_choose_replacement" : "assistant_replace_product"))
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.wine)
            .disabled(!canUseProducts)
        }
    }

    @ViewBuilder
    private func productDetailsAction(_ product: AssistantProduct, expanded: Bool, hasDetails: Bool) -> some View {
        if hasDetails {
            Button { toggle(product.id, in: &expandedProductIds) } label: {
                AppIcon(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.footnote.weight(.regular))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.ink2)
            .accessibilityLabel(String(localized: expanded ? "compare_hide_description" : "compare_show_description"))
        }
    }

    // A pack equal to the lot unit only repeats the quantity line ("1 шт").
    private func hasDistinctPack(_ product: AssistantProduct) -> Bool {
        guard product.priceBasis != "unknown", let pack = product.pack, !pack.isEmpty else { return false }
        guard isShoppingList, product.hasKnownPurchaseQuantity, product.purchaseLotQuantity != nil,
              let unit = product.purchaseLotUnit else { return true }
        return pack != unit
    }

    private func productUnitPrice(_ product: AssistantProduct) -> some View {
        Text(product.unitPriceKopeks.map { unitPriceText(product, price: $0) } ?? String(localized: "common_no_data"))
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.ink)
    }

    private func productAvailability(_ product: AssistantProduct) -> some View {
        Text(availabilityText(product))
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
    }

    private func productPurchasePrice(_ product: AssistantProduct) -> some View {
        Text(product.displayLineTotalKopeks.map(AssistantPrice.text) ?? String(localized: "assistant_product_unknown_total"))
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.ink)
    }

    private func productPurchaseQuantity(_ product: AssistantProduct) -> some View {
        Text(purchaseQuantityText(product))
            .font(.footnote)
            .foregroundStyle(AppTheme.ink2)
    }

    @ViewBuilder
    private func productThumbnail(_ product: AssistantProduct) -> some View {
        if let rawURL = product.imageUrl, let url = URL(string: rawURL) {
            // Public retailer CDN: never attach application API authorization headers.
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFit()
                        .padding(3)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
        }
    }

    @ViewBuilder
    private var sourceNote: some View {
        if let source = message.source {
            VStack(alignment: .leading, spacing: 2) {
                Text(sourceLabel(source))
                if source == "saved_snapshot", let checkedAt = message.checkedAt {
                    Text(String(format: String(localized: "assistant_products_checked_at"), formattedCheckedAt(checkedAt)))
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
        }
    }

    private func availabilityText(_ product: AssistantProduct) -> String {
        switch product.availability {
        case "many": return String(localized: "assistant_availability_many")
        case "few": return String(localized: "assistant_availability_few")
        case "none": return String(localized: "assistant_availability_none")
        default: return String(localized: "assistant_availability_unknown")
        }
    }

    private func toggle(_ id: String, in values: inout Set<String>) {
        if values.contains(id) { values.remove(id) } else { values.insert(id) }
    }

    private func sourceLabel(_ source: String) -> String {
        if source == "live_catalog" || source == "perekrestok_webview" {
            return String(localized: "assistant_products_source_live")
        }
        if source == "session_context" { return String(localized: "assistant_products_source_session") }
        return String(localized: "assistant_products_source_snapshot")
    }

    private func formattedCheckedAt(_ value: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: value) ?? ISO8601DateFormatter().date(from: value) else {
            return String(value.prefix(10))
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private enum AssistantPrice {
    static func text(_ kopeks: KotlinLong) -> String {
        let value = Decimal(kopeks.int64Value) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }
}
