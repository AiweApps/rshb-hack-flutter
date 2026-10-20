import SharedLogic

class ObservableValue<T: AnyObject>: ObservableObject {
    @Published var value: T

    private var collector: Collector<T>?

    init(_ value: Value<T>) {
        self.value = value.value

        let collector = Collector<T>(value: value) { [weak self] newValue in
            DispatchQueue.main.async {
                self?.value = newValue
            }
        }
        self.collector = collector
        collector.start()
    }

    deinit {
        collector?.stop()
    }
}
