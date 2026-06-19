import Foundation

struct RemoteLicenseClient: LicenseAPI {
    let baseUrl: String
    let keychain: Keychain

    init(baseUrl: String, keychain: Keychain) {
        self.baseUrl = baseUrl
        self.keychain = keychain
    }

    func activate(_ licenseKey: String, completion: @escaping (Result<ActivateResult, Error>) -> Void) {
        completion(.success(ActivateResult(instanceId: "local", variantId: "local", customerEmail: nil)))
    }

    func validate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<ValidateResult, Error>) -> Void) {
        completion(.success(ValidateResult(valid: true, variantId: "local")))
    }

    func deactivate(_ licenseKey: String, instanceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
