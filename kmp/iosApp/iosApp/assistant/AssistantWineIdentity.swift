import SharedLogic

/// One recognized bottle, even when several bottles resolve to the same catalogue wine.
struct AssistantWineIdentity: Hashable {
    let photoId: String?
    let instanceId: String?
    let slug: String

    init(_ wine: AssistantWine) {
        photoId = wine.photoId
        instanceId = wine.instanceId
        slug = wine.slug
    }
}

extension AssistantWine {
    var presentationIdentity: AssistantWineIdentity { AssistantWineIdentity(self) }
}
