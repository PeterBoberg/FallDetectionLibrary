//
//  ConstantsTest.swift
//  FallDetectionLibTests
//
//  Created by Peter Boberg on 2018-06-06.
//  Copyright © 2018 Frost AB. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import FallDetectionLib

class ConstantsTest: QuickSpec {

    override func spec() {
        super.spec()

        describe("The constants", {

            it("Impact threshold should be equal to 4.0 g", closure: {
                expect(FDConstants.impactThreshold).to(equal(4.0))
            })

            it("Upper motionless threshold shoule be equal to 1.8 g", closure: {
                expect(FDConstants.upperMotionlessThreshold).to(equal(1.8))
            })

            it("Lower motionless threshold should be equal to 0.3g", closure: {
                expect(FDConstants.lowerMotionlessThreshold).to(equal(0.3))
            })

            it("Buffer time should be equal to 8.0 seconds", closure: {
                expect(FDConstants.bufferTime).to(equal(8.0))
            })

            it("Accelerometer update interval should be equal to 1 / 50  = 0.02 sec", closure: {
                expect(FDConstants.updateInterval).to(equal(0.02))
            })

            it("Frequency should be equal to 50 Hertz", closure: {
                expect(FDConstants.frequency()).to(equal(50))
            })

            it("Ring buffer capacity should be equal to 8 sec * 50 hertz = 400 samples", closure: {
                expect(FDConstants.ringBufferCapacity()).to(equal(400))
            })

            it("Pre impact end time should be equal to ring buffer capacity / 2 = 200 samples", closure: {
                expect(FDConstants.preImpactEndTime()).to(equal(200))
            })

            it("Post impact end time should be equal to (3 / 4) * ring buffer capacity  = 300 samples", closure: {
                expect(FDConstants.postImpactEndTime()).to(equal(300))
            })
        })

    }
}
