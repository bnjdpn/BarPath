import Foundation
import CoreVideo
@testable import BarPath

final class MockPoseDetectionService: PoseDetecting, @unchecked Sendable {
    var pointsToReturn: [BarPathPoint] = []
    var currentIndex = 0
    var detectCallCount = 0
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockPoseDetection", code: -1)

    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) async throws -> BarPathPoint? {
        detectCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        guard currentIndex < pointsToReturn.count else { return nil }
        let point = pointsToReturn[currentIndex]
        currentIndex += 1
        return point
    }

    func reset() {
        currentIndex = 0
        detectCallCount = 0
        shouldThrowError = false
    }
}
