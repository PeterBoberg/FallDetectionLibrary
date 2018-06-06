//
// Created by Peter Boberg on 2018-06-05.
// Copyright (c) 2018 Frost AB. All rights reserved.
//

import Foundation
import RxSwift
@testable import FallDetectionLib

class TestUtils {

    static let preImpactEndTime = 9
    static let posImpactEndTime = 18
    static let lowerMotionlessThreshold = 0.5
    static let upperMotionlessThreshold = 1.8
    static let impactThreshold = 4.0

    static let ringBufferFrequency = 5
    static let ringBufferCapacity = 20

    static func exampleExtractor() -> FDFeatureExtractor {
        let extractor = FDFeatureExtractorImpl(withBlock: {
            var config = FeatureExtractorConfig()
            config.preImpactEndTime = preImpactEndTime
            config.postImpactEndTime = posImpactEndTime
            config.loweMotionLessThreshold = lowerMotionlessThreshold
            config.upperMotionLessThreshold = upperMotionlessThreshold
            config.impactThreshold = impactThreshold
            return config
        })

        return extractor
    }

    class func exampleEngine() -> MockClassificationEngine {
        return MockClassificationEngine()
    }

    static func exampleProvider() -> MockAccelerationProvider {
        return MockAccelerationProvider()
    }

    static func exampleFallDetectorDelegate() -> MockFallDetectorDelegate {
        return MockFallDetectorDelegate()
    }

    /*
   Set up a mock up ring buffer containing
   - 0 peaks prior to impact
   - 1 valley prior to impact end time
   - The valley should have a value of 0.2 and a duration of 3 samples
   - The impact peak should have a value of 7 and a duration of 3 samples
   . The actual impact peak should have a value of 7 and a duration of 3 samples
   */
    static func exampleRingBuffer() -> FDRingBuffer {

        var ringBufferGivenByStateMachine = FDRingBuffer(capacity: ringBufferCapacity, frequency: ringBufferFrequency)
        ringBufferGivenByStateMachine.add(element: 1)
        ringBufferGivenByStateMachine.add(element: 1)
        ringBufferGivenByStateMachine.add(element: 0.4) //                           |
        ringBufferGivenByStateMachine.add(element: 0.2) // Longest valley value [4]  | Longest valley dur.
        ringBufferGivenByStateMachine.add(element: 0.4) //                           | (3 samples long)
        ringBufferGivenByStateMachine.add(element: 1)
        ringBufferGivenByStateMachine.add(element: 1) // Impact start [6]
        ringBufferGivenByStateMachine.add(element: 2)
        ringBufferGivenByStateMachine.add(element: 5) // Pre impact end time [8]     |                  |
        ringBufferGivenByStateMachine.add(element: 7) // Impact Peak value [9]       | Impact peak dur. |
        ringBufferGivenByStateMachine.add(element: 5) //                             | (3 samples long) [
        ringBufferGivenByStateMachine.add(element: 2) //                                                | Impact dur.
        ringBufferGivenByStateMachine.add(element: 1) //                                                | (9 samples long)
        ringBufferGivenByStateMachine.add(element: 2) //                                                |
        ringBufferGivenByStateMachine.add(element: 1) //                                                |
        ringBufferGivenByStateMachine.add(element: 2) // Impact end [15]                                |
        ringBufferGivenByStateMachine.add(element: 1)
        ringBufferGivenByStateMachine.add(element: 1)
        ringBufferGivenByStateMachine.add(element: 1) // Post impact end time [18]
        ringBufferGivenByStateMachine.add(element: 1)

        return ringBufferGivenByStateMachine
    }

}

class MockAccelerationProvider: FDAccelerationProvider {

    var accelerometerUpdateInterval: Double = 0
    private(set) var accelerometerData: Observable<Double>
    private let accelerometerSubject = PublishSubject<Double>()

    var isRunning = false
    var mostAccurateLocationCalled = false

    init() {
        self.accelerometerUpdateInterval = 0.02
        self.accelerometerData = accelerometerSubject.asObservable()
    }

    func startAccelerometer() {
        self.isRunning = true
    }

    func stopAccelerometer() {
        self.isRunning = false
    }

    func getMostAccurateLocation(_ closure: @escaping (Double, Double) -> ()) {
        mostAccurateLocationCalled = true
    }

    func addMockSample(_ sample: Double) {
        self.accelerometerSubject.onNext(sample)
    }
}

class MockClassificationEngine: FDClassificationEngine {

    func classify(userMotion: FDUserMotion) -> ClassificationType? {
        return .fall
    }
}

class MockFallDetectorDelegate: FallDetectorDelegate {

    var classifiedType: ClassificationType?

    func userMotionClassified(_: FDFallDetector, motion: FDUserMotion, ofType type: ClassificationType) {
        self.classifiedType = type
    }
}