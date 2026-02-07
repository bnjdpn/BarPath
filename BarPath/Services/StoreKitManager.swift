import StoreKit
import Security
import Foundation

/// Manages in-app purchases with StoreKit 2.
/// Handles lifetime purchase, trial period, and analysis count gating.
@Observable
@MainActor
final class StoreKitManager {

    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - Properties

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false

    private let productID = "app.barpath.lifetime"
    private let trialDays = 7

    // MARK: - Computed Properties

    /// Returns true if the user has purchased the lifetime access product.
    var hasLifetimePurchase: Bool {
        purchasedProductIDs.contains(productID)
    }

    /// Returns true if the user is currently within the trial period.
    var isInTrial: Bool {
        guard let trialStartDate = getTrialStartDate() else {
            // First launch, start trial
            setTrialStartDate(Date())
            return true
        }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0
        return daysSinceStart < trialDays
    }

    /// Returns true if the user can use the app (purchased or in trial).
    var canUseApp: Bool {
        hasLifetimePurchase || isInTrial
    }

    /// Number of analyses performed (free limit: 3).
    var analysisCount: Int {
        UserDefaults.standard.integer(forKey: "analysisCount")
    }

    /// Returns true if the user can perform another analysis.
    var canAnalyze: Bool {
        hasLifetimePurchase || analysisCount < 3
    }

    // MARK: - Initialization

    private init() {
        Task {
            await updatePurchasedProducts()
        }
    }

    // MARK: - Public Methods

    /// Increments the analysis count after a successful analysis.
    func incrementAnalysisCount() {
        let current = analysisCount
        UserDefaults.standard.set(current + 1, forKey: "analysisCount")
    }

    /// Loads available products from the App Store.
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [productID])
        } catch {
            products = []
        }
    }

    /// Purchases the specified product.
    ///
    /// - Parameter product: The product to purchase.
    /// - Returns: True if the purchase was successful, false otherwise.
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Restores previous purchases.
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    // MARK: - Private Methods

    /// Updates the set of purchased product IDs from current entitlements.
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    /// Verifies a transaction result.
    ///
    /// - Parameter result: The verification result to check.
    /// - Returns: The verified transaction.
    /// - Throws: StoreError.failedVerification if verification fails.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Keychain Trial Management

    /// Retrieves the trial start date from the Keychain.
    ///
    /// - Returns: The trial start date, or nil if not set.
    func getTrialStartDate() -> Date? {
        guard let data = KeychainHelper.read(key: "trialStartDate"),
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }
        return date
    }

    /// Saves the trial start date to the Keychain.
    ///
    /// - Parameter date: The date to save.
    private func setTrialStartDate(_ date: Date) {
        guard let data = try? JSONEncoder().encode(date) else { return }
        KeychainHelper.save(key: "trialStartDate", data: data)
    }
}

// MARK: - StoreError

/// Errors that can occur during StoreKit operations.
enum StoreError: Error {
    case failedVerification
}

// MARK: - KeychainHelper

/// Simple Keychain helper for secure storage.
struct KeychainHelper {

    /// Saves data to the Keychain.
    ///
    /// - Parameters:
    ///   - key: The key to store the data under.
    ///   - data: The data to store.
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Reads data from the Keychain.
    ///
    /// - Parameter key: The key to retrieve data for.
    /// - Returns: The data if found, nil otherwise.
    static func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
