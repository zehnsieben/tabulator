import Cocoa

class UserDefaultsEvents: NSObject {
    private static var policyObserver = UserDefaultsEvents()
    private static var isObserving = false

    static func observe() {
        return
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        handleEvent(keyPath)
    }

    private func handleEvent(_ keyPath: String?) {
        return
    }

    private func buttonIdToUpdate() -> Int {
        return 0
    }
}
