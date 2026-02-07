import SwiftUI
import StoreKit

/// Paywall screen presented when the user hits the free analysis limit.
/// Shows product price, feature list, and purchase/restore buttons.
struct PaywallView: View {

    // MARK: - Properties

    @State private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                Text(NSLocalizedString("paywall_title", comment: "Paywall title"))
                    .font(.largeTitle.bold())

                Text(NSLocalizedString("paywall_subtitle", comment: "Paywall subtitle"))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "chart.xyaxis.line", text: "paywall_feature_unlimited")
                    FeatureRow(icon: "arrow.left.arrow.right", text: "paywall_feature_comparison")
                    FeatureRow(icon: "message.fill", text: "paywall_feature_coaching")
                    FeatureRow(icon: "square.and.arrow.up", text: "paywall_feature_export")
                }
                .padding(.vertical)

                Spacer()

                // Purchase button
                if let product = storeManager.products.first {
                    Button {
                        Task {
                            _ = try? await storeManager.purchase(product)
                            if storeManager.hasLifetimePurchase {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "paywall_purchase_button",
                                    comment: "Purchase button"
                                ),
                                product.displayPrice
                            )
                        )
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(storeManager.isLoading)
                } else if storeManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(NSLocalizedString("paywall_product_unavailable", comment: "Product unavailable"))
                        .foregroundColor(.secondary)
                        .padding()
                }

                // Restore
                Button(NSLocalizedString("paywall_restore", comment: "Restore purchases")) {
                    Task {
                        await storeManager.restorePurchases()
                        if storeManager.hasLifetimePurchase {
                            dismiss()
                        }
                    }
                }
                .disabled(storeManager.isLoading)

                // Terms
                HStack(spacing: 8) {
                    Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                    Text("•")
                    Link("Terms", destination: URL(string: "https://example.com/terms")!)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .task {
                await storeManager.loadProducts()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FeatureRow

/// A single feature row in the paywall feature list.
struct FeatureRow: View {

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(NSLocalizedString(text, comment: ""))
                .font(.body)
        }
    }
}
