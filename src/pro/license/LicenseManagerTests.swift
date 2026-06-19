import XCTest

final class LicenseManagerTests: XCTestCase {
    var clock: MockClock!
    var keychain: MockKeychain!
    var api: MockLicenseAPI!
    var defaults: UserDefaults!
    var suiteName: String!
    var manager: LicenseManager!

    override func setUp() {
        super.setUp()
        suiteName = "test-license-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        clock = MockClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        keychain = MockKeychain()
        api = MockLicenseAPI()
        manager = LicenseManager(clock: clock, keychain: keychain, api: api, defaults: defaults)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testInitializeAlwaysMakesProAvailableWithoutNetwork() {
        manager.initialize()
        XCTAssertEqual(manager.state, .pro)
        XCTAssertTrue(manager.isProAvailable)
        XCTAssertFalse(manager.isProLocked)
        XCTAssertTrue(api.activateCalls.isEmpty)
        XCTAssertTrue(api.validateCalls.isEmpty)
        XCTAssertTrue(api.deactivateCalls.isEmpty)
    }

    func testExpiredTrialDataIsIgnored() {
        defaults.set(clock.now.addingTimeInterval(-365 * 86400).timeIntervalSince1970, forKey: "trialStartDate")
        manager.initialize()
        XCTAssertEqual(manager.state, .pro)
        XCTAssertFalse(manager.isProLocked)
    }

    func testInvalidCachedLicenseDataIsIgnored() {
        keychain.setValue("OLD-KEY", account: LicenseManager.keychainKeyAccount)
        defaults.set(false, forKey: "lastValidationResult")
        manager.initialize()
        XCTAssertEqual(manager.state, .pro)
        XCTAssertFalse(manager.isProLocked)
    }

    func testActivateIsLocalAndDoesNotCallApi() {
        let exp = expectation(description: "activate")
        manager.activate("ANY-KEY") { result in
            if case .failure(let error) = result { XCTFail("expected local success, got \(error)") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(manager.state, .pro)
        XCTAssertTrue(api.activateCalls.isEmpty)
    }

    func testDeactivateKeepsFeaturesAvailableAndDoesNotCallApi() {
        keychain.setValue("OLD-KEY", account: LicenseManager.keychainKeyAccount)
        keychain.setValue("old-instance", account: LicenseManager.keychainInstanceAccount)
        let exp = expectation(description: "deactivate")
        manager.deactivate { result in
            if case .failure(let error) = result { XCTFail("expected local success, got \(error)") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(manager.state, .pro)
        XCTAssertNil(keychain.value(account: LicenseManager.keychainKeyAccount))
        XCTAssertNil(keychain.value(account: LicenseManager.keychainInstanceAccount))
        XCTAssertTrue(api.deactivateCalls.isEmpty)
    }

    func testRevalidationIsNoop() {
        manager.revalidateWithServer()
        XCTAssertEqual(manager.state, .pro)
        XCTAssertTrue(api.validateCalls.isEmpty)
    }
}

final class MockClock: Clock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

final class MockKeychain: Keychain {
    private var values: [String: String] = [:]

    func value(account: String) -> String? {
        values[account]
    }

    @discardableResult
    func setValue(_ value: String, account: String) -> OSStatus {
        values[account] = value
        return errSecSuccess
    }

    @discardableResult
    func remove(account: String) -> OSStatus {
        values.removeValue(forKey: account)
        return errSecSuccess
    }
}

final class MockLicenseAPI: LicenseAPI {
    var activateCalls: [String] = []
    var validateCalls: [(String, String)] = []
    var deactivateCalls: [(String, String)] = []

    func activate(_ licenseKey: String, completion: @escaping (Result<ActivateResult, Error>) -> Void) {
        activateCalls.append(licenseKey)
        completion(.failure(LicenseAPIError.noData))
    }

    func validate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<ValidateResult, Error>) -> Void) {
        validateCalls.append((licenseKey, instanceId))
        completion(.failure(LicenseAPIError.noData))
    }

    func deactivate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        deactivateCalls.append((licenseKey, instanceId))
        completion(.failure(LicenseAPIError.noData))
    }
}
