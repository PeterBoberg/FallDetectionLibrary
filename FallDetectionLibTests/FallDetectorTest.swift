//
//  FallDetectorTest.swift
//  FallDetectionLibTests
//
//  Created by Peter Boberg on 2018-06-05.
//  Copyright © 2018 Frost AB. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import FallDetectionLib

class FallDetectorTest: QuickSpec {
    override func spec() {
        super.spec()

        let mockAccelerationProvider = TestUtils.exampleProvider()
        let mockFeatureExtractor = TestUtils.exampleExtractor()
        let mockRingBuffer = TestUtils.exampleRingBuffer()
        let mockClassificationEngine = TestUtils.exampleEngine()

        let fallDetector = FDFallDetector(
                accelerationProvider: mockAccelerationProvider,
                classificationEngine: mockClassificationEngine,
                featureExtractor: mockFeatureExtractor,
                ringBuffer: mockRingBuffer
        )
        describe("The FallDetector", {

            beforeEach({
                fallDetector.reset()
            })

            it("Should start accelerometer updates when told so", closure: {
                fallDetector.detectionEnabled.value = true
                expect(mockAccelerationProvider.isRunning).to(beTrue())

            })

            it("Should stop accelerometer updates when told so", closure: {
                fallDetector.detectionEnabled.value = false
                expect(mockAccelerationProvider.isRunning).to(beFalse())
            })

            it("Should get the most accurate location", closure: {
                fallDetector.getMostAccurateLocation({ lat, long in

                })
                expect(mockAccelerationProvider.mostAccurateLocationCalled).to(be(true))
            })

            it("Should start in a normal state", closure: {
                expect(fallDetector.state).to(equal(FDFallDetector.State.normal))
            })

            context("When a sudden impact peak comes without a prior free fall", {
                it("Should remain in normal state", closure: {
                    mockAccelerationProvider.addMockSample(7.0) // Sudden impact without prior fall
                    expect(fallDetector.state).to(equal(FDFallDetector.State.normal))
                })
            })

            context("When a free fall occurs", {
                it("Should move to a the free fall state", closure: {
                    mockAccelerationProvider.addMockSample(0.2)
                    expect(fallDetector.state).to(equal(FDFallDetector.State.falling))
                })
            })

            context("When in the free fall state", {

                context("and acceleration goes back to within motionless interval", {
                    it("Should move to the post fall state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        expect(fallDetector.state).to(equal(FDFallDetector.State.postFalling))
                    })
                })

                context("and an impact peak occurs", {
                    it("Should move to to the impact state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        expect(fallDetector.state).to(equal(FDFallDetector.State.impact))
                    })
                })
            })

            context("When in the post falling  state", {

                context("and a new free fall occurs", {
                    it("Should go back to the free fall state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        expect(fallDetector.state).to(equal(FDFallDetector.State.falling))
                    })
                })

                context("and an impact peak occurs", {
                    it("should move to impact state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        expect(fallDetector.state).to(equal(FDFallDetector.State.impact))
                    })
                })

                context("and neither free fall or impacts occur", {
                    it("should go back to normal state after 0.1 seconds", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        Thread.sleep(forTimeInterval: 0.1)
                        mockAccelerationProvider.addMockSample(1.0) //

                        expect(fallDetector.state).to(equal(FDFallDetector.State.normal))
                    })
                })
            })

            context("When in the impact state", {

                context("and impact peaks continues to come", {
                    it("Should remain in impact state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        expect(fallDetector.state).to(equal(FDFallDetector.State.impact))

                    })
                })

                context("and no new impact peaks has come for 2 seconds", {
                    it("Should move to the motionless", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        Thread.sleep(forTimeInterval: 2.0)
                        mockAccelerationProvider.addMockSample(1.0) // Motionless
                        expect(fallDetector.state).to(equal(FDFallDetector.State.motionLess))
                    })
                })
            })

            context("When in the motionless state", {

                context("and a free fall occurs", {
                    it("should move to the free fall state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        Thread.sleep(forTimeInterval: 2.0)
                        mockAccelerationProvider.addMockSample(1.0) // Motionless
                        mockAccelerationProvider.addMockSample(0.2) // Falling again
                        expect(fallDetector.state).to(equal(FDFallDetector.State.falling))
                    })
                })

                context("and movement occurs within 2 seconds", {
                    it("should move to the normal state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        Thread.sleep(forTimeInterval: 2.0)
                        mockAccelerationProvider.addMockSample(1.0) // Motionless
                        mockAccelerationProvider.addMockSample(2.0) // Movement
                        expect(fallDetector.state).to(equal(FDFallDetector.State.normal))
                    })
                })

                context("And no movement occurs within 2 seconds", {
                    it("should move to the fall detected state", closure: {
                        mockAccelerationProvider.addMockSample(0.2) // Falling
                        mockAccelerationProvider.addMockSample(1.0) // Post falling
                        mockAccelerationProvider.addMockSample(7.0) // Impact
                        Thread.sleep(forTimeInterval: 2.0)
                        mockAccelerationProvider.addMockSample(1.0) // Motionless
                        Thread.sleep(forTimeInterval: 2.0)
                        mockAccelerationProvider.addMockSample(1.0) // Fall detected
                        expect(fallDetector.state).to(equal(FDFallDetector.State.fallDetected))

                    })
                })
            })
        })

        it("should call its delegate when a fall is classified", closure: {
            let mockDelegate = TestUtils.exampleFallDetectorDelegate()
            fallDetector.delegate = mockDelegate

            mockAccelerationProvider.addMockSample(0.2) // Falling
            mockAccelerationProvider.addMockSample(1.0) // Post falling
            mockAccelerationProvider.addMockSample(7.0) // Impact
            Thread.sleep(forTimeInterval: 2.0)
            mockAccelerationProvider.addMockSample(1.0) // Motionless
            Thread.sleep(forTimeInterval: 2.0)
            mockAccelerationProvider.addMockSample(1.0) // Fall detected
            mockAccelerationProvider.addMockSample(1.0) // Fall detected

            expect(mockDelegate.classifiedType).toEventuallyNot(beNil())
        })
    }
}
