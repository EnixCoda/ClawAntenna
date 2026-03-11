import Foundation

/// Common interface for SwiftData records that can be uploaded to Supabase.
///
/// All record models conform to this protocol so that the UploadService
/// can handle them generically.
protocol Uploadable: AnyObject {
    /// The Supabase table this record uploads to (e.g., "locations", "pedometer").
    static var supabaseTable: String { get }

    var id: UUID { get }
    var uploadStatus: String { get set }
    var uploadAttempts: Int { get set }
    var lastUploadAttempt: Date? { get set }

    /// Converts the record to the JSON dictionary format expected by Supabase REST API.
    func toSupabaseJSON() -> [String: Any]
}

extension Uploadable {
    var status: UploadStatus {
        get { UploadStatus(rawValue: uploadStatus) ?? .pending }
        set { uploadStatus = newValue.rawValue }
    }
}
