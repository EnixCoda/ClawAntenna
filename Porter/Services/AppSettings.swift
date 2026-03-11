import Foundation
import SwiftUI

@Observable
final class AppSettings {
    private static let supabaseURLKey = "supabaseURL"
    private static let trackingEnabledKey = "isTrackingEnabled"
    private static let lastUploadDateKey = "lastUploadDate"
    private static let keychainAPIKeyName = "supabaseServiceRoleKey"

    var supabaseURL: String {
        didSet { UserDefaults.standard.set(supabaseURL, forKey: Self.supabaseURLKey) }
    }

    var isTrackingEnabled: Bool {
        didSet { UserDefaults.standard.set(isTrackingEnabled, forKey: Self.trackingEnabledKey) }
    }

    var lastUploadDate: Date? {
        didSet { UserDefaults.standard.set(lastUploadDate, forKey: Self.lastUploadDateKey) }
    }

    var supabaseAPIKey: String {
        get { KeychainHelper.load(key: Self.keychainAPIKeyName) ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.delete(key: Self.keychainAPIKeyName)
            } else {
                KeychainHelper.save(key: Self.keychainAPIKeyName, value: newValue)
            }
        }
    }

    /// Whether the Supabase endpoint is fully configured.
    var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAPIKey.isEmpty
    }

    init() {
        self.supabaseURL = UserDefaults.standard.string(forKey: Self.supabaseURLKey) ?? ""
        self.isTrackingEnabled = UserDefaults.standard.bool(forKey: Self.trackingEnabledKey)
        self.lastUploadDate = UserDefaults.standard.object(forKey: Self.lastUploadDateKey) as? Date
    }
}
