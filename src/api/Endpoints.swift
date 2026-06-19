import Foundation

enum Endpoints {
    static let domain = Bundle.main.object(forInfoDictionaryKey: "Domain") as! String
    static let apiDomain = Bundle.main.object(forInfoDictionaryKey: "ApiDomain") as! String
    static let website = ""
}
