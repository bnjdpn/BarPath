import SwiftUI

/// The color mode used to render the bar path overlay.
enum OverlayColorMode {
    /// Color varies from green (slow) to red (fast) based on velocity.
    case velocity
    /// Fixed single color.
    case fixed
    /// Eccentric phase in blue, concentric phase in orange.
    case phase
}

/// SwiftUI view that draws the bar path as a Canvas overlay on top of the video player.
/// Supports velocity-based coloring, phase coloring, and rep highlighting.
struct BarPathOverlayView: View {

    // MARK: - Properties

    /// The points to draw (may be a subset if a specific rep is selected).
    let points: [BarPathPoint]

    /// All points in the analysis (used for velocity range normalization).
    let allPoints: [BarPathPoint]

    /// The rep segments for phase-based coloring.
    let reps: [RepSegment]

    /// The currently selected rep index, or nil for all.
    let selectedRep: Int?

    /// The coloring strategy for the path.
    let colorMode: OverlayColorMode

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            guard points.count >= 2 else { return }

            let velocities = BarPathAnalyzer.calculateVelocities(points)
            let maxVelocity = velocities.max() ?? 1.0
            let minVelocity = velocities.min() ?? 0.0

            // Draw path segments
            for i in 1..<points.count {
                let from = scaledPoint(points[i - 1], in: size)
                let to = scaledPoint(points[i], in: size)

                let color = segmentColor(
                    index: i,
                    velocity: velocities[i],
                    minVelocity: minVelocity,
                    maxVelocity: maxVelocity
                )

                var path = Path()
                path.move(to: from)
                path.addLine(to: to)

                context.stroke(
                    path,
                    with: .color(color),
                    lineWidth: 3
                )
            }

            // Draw dots at each tracked point
            for (index, point) in points.enumerated() {
                let center = scaledPoint(point, in: size)
                let dotRadius = CGFloat(2 + point.confidence * 3)

                let dotColor = segmentColor(
                    index: index,
                    velocity: velocities[index],
                    minVelocity: minVelocity,
                    maxVelocity: maxVelocity
                )

                let dotRect = CGRect(
                    x: center.x - dotRadius,
                    y: center.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )

                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(dotColor.opacity(0.8))
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    /// Converts a normalized bar path point to a screen-space CGPoint.
    private func scaledPoint(_ point: BarPathPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: point.y * size.height
        )
    }

    /// Determines the color for a path segment based on the active color mode.
    private func segmentColor(
        index: Int,
        velocity: Double,
        minVelocity: Double,
        maxVelocity: Double
    ) -> Color {
        switch colorMode {
        case .velocity:
            return velocityColor(
                velocity: velocity,
                min: minVelocity,
                max: maxVelocity
            )

        case .fixed:
            return .cyan

        case .phase:
            return phaseColor(forIndex: index)
        }
    }

    /// Maps a velocity value to a color on a green-to-red gradient.
    private func velocityColor(velocity: Double, min: Double, max: Double) -> Color {
        let range = max - min
        guard range > 0 else { return .green }

        let normalized = (velocity - min) / range

        // Green (slow) -> Yellow (medium) -> Red (fast)
        if normalized < 0.5 {
            let t = normalized * 2
            return Color(
                red: t,
                green: 1.0,
                blue: 0.0
            )
        } else {
            let t = (normalized - 0.5) * 2
            return Color(
                red: 1.0,
                green: 1.0 - t,
                blue: 0.0
            )
        }
    }

    /// Determines phase-based color: blue for eccentric, orange for concentric.
    private func phaseColor(forIndex index: Int) -> Color {
        guard !reps.isEmpty else { return .cyan }

        // Map the display point index back to the global point index.
        let globalIndex: Int
        if let selectedRep, selectedRep < reps.count {
            globalIndex = reps[selectedRep].startIndex + index
        } else {
            globalIndex = index
        }

        // Find which rep this index belongs to.
        for rep in reps {
            if globalIndex >= rep.startIndex && globalIndex <= rep.endIndex {
                // Before concentric start = eccentric (blue), after = concentric (orange).
                if globalIndex < rep.concentricStartIndex {
                    return .blue
                } else {
                    return .orange
                }
            }
        }

        return .gray.opacity(0.5)
    }
}
