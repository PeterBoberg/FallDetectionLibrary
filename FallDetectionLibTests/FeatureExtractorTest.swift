//
// Created by Peter Boberg on 2018-05-30.
// Copyright (c) 2018 Frost AB. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import FallDetectionLib

class FeatureExtractorTest: QuickSpec {

    override func spec() {
        super.spec()



        let ringBufferGivenByStateMachine: FDRingBuffer = TestUtils.exampleRingBuffer()
        let ringBufferFrequency = TestUtils.ringBufferFrequency

        let extractor = FDFeatureExtractorImpl(withBlock: {
            var config = FeatureExtractorConfig()
            config.preImpactEndTime = TestUtils.preImpactEndTime
            config.postImpactEndTime = TestUtils.posImpactEndTime
            config.loweMotionLessThreshold = TestUtils.lowerMotionlessThreshold
            config.upperMotionLessThreshold = TestUtils.upperMotionlessThreshold
            config.impactThreshold = TestUtils.impactThreshold
            return config
        })


        let motion = extractor.extract(fromBuffer: TestUtils.exampleRingBuffer())

        describe("A Feature Extractor", closure: {

            context("when given a ring buffer collected from the state machine", {

                it("Should be able to to find the impact peak", closure: {
                    expect(motion.peaks.first).toNot(beNil())
                })

                it("Should be able to compute the number peaks prior to impact", closure: {
                    expect(motion.numberOfPeaksPriorToImpact).to(equal(0))
                })

                it("Should calculate the number of valleys prior to impact", closure: {
                    expect(motion.numberOfValleysPriorToImpact).to(equal(1))
                })

                it("Should calculate the correct values for the impact peak", closure: {
                    // When
                    let expectedImpactPeakValue = 7.0 // See TestUtils for reference
                    let expectedImpactPeakDuration = self.convertToMillisByDividing(this: 3, withThat: ringBufferFrequency)

                    // Then
                    expect(motion.impactPeakValue).to(equal(expectedImpactPeakValue))
                    expect(motion.impactPeakDuration).to(equal(expectedImpactPeakDuration))
                })

                it("Should calculate the correct values for the longest valley", closure: {
                    // When
                    let expectedValleyValue = 0.2 // See TestUtils for reference
                    let expectedValleyDuration = self.convertToMillisByDividing(this: 3, withThat: ringBufferFrequency)

                    // Then
                    expect(motion.longestValleyValue).to(equal(expectedValleyValue))
                    expect(motion.longestValleyDuration).to(equal(Int(expectedValleyDuration)))

                })

                it("Should calculate the impact start time and end time", closure: {
                    // When
                    let expectedImpactStart = self.convertToMillisByDividing(this: 6, withThat: ringBufferFrequency)
                    let expectedImpactEnd = self.convertToMillisByDividing(this: 15, withThat: ringBufferFrequency)

                    // Then
                    expect(motion.impactStart).to(equal(expectedImpactStart))
                    expect(motion.impactEnd).to(equal(expectedImpactEnd))
                })

                it("Should calculate the duration of the impact", closure: {
                    // When
                    let expectedImpactStart = self.convertToMillisByDividing(this: 6, withThat: ringBufferFrequency)
                    let expectedImpactEnd = self.convertToMillisByDividing(this: 15, withThat: ringBufferFrequency)
                    let expectedDuration = expectedImpactEnd - expectedImpactStart

                    // Then
                    expect(motion.impactDuration).to(equal(expectedDuration))

                })

                it("Should calculate the average acceleration variation", closure: {

                    // When
                    var expectedAAV = 0.0
                    let data = ringBufferGivenByStateMachine.retrieve()
                    let start = 6
                    var counter = start
                    let stop = 15
                    while counter < stop {
                        expectedAAV += abs(data[counter + 1] - data[counter])
                        counter += 1
                    }

                    expectedAAV /= Double(stop - start)

                    // Then
                    expect(motion.averageAccelerationVariation).to(equal(expectedAAV))
                })
            })
        })
    }

    private func convertToMillisByDividing(this: Int, withThat that: Int) -> Int {
        return Int((Double(this) / Double(that)) * 1000)
    }
}

