//
// Created by Peter Boberg on 2018-06-04.
// Copyright (c) 2018 Frost AB. All rights reserved.
//

import Foundation

struct FDConstants {
    static let impactThreshold = 4.0
    static let upperMotionlessThreshold = 1.8
    static let lowerMotionlessThreshold = 0.3
    static let bufferTime = 8.0
    static let updateInterval = 0.02

    static func frequency() -> Hertz {
        return Int(1 / updateInterval)
    }

    static func ringBufferCapacity() -> Samples {
        return Int(bufferTime * Double(frequency()))
    }

    static func preImpactEndTime() -> Samples {
        return ringBufferCapacity() / 2
    }

    static func postImpactEndTime() -> Samples {
        return Int((3 / 4) * Double(ringBufferCapacity()))
    }

}
