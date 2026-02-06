import SwiftUI

/// Reusable metric display card showing an icon, title, value, and optional unit.
/// Designed for compact grid layout in the result metrics panel.
struct MetricCard: View {

    // MARK: - Properties

    /// SF Symbol name for the metric icon.
    let icon: String

    /// Localized title describing the metric.
    let title: String

    /// The formatted metric value.
    let value: String

    /// Optional unit string displayed after the value.
    var unit: String? = nil

    /// Optional trend indicator: positive, negative, or neutral.
    var trend: MetricTrend? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let trend {
                    trendIndicator(trend)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Trend Indicator

    @ViewBuilder
    private func trendIndicator(_ trend: MetricTrend) -> some View {
        switch trend {
        case .positive:
            Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundStyle(.green)

        case .negative:
            Image(systemName: "arrow.down.right")
                .font(.caption2)
                .foregroundStyle(.red)

        case .neutral:
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Metric Trend

/// Indicates the direction of change for a metric value.
enum MetricTrend {
    case positive
    case negative
    case neutral
}
