//
// Created by Peter Boberg on 2018-04-13.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation


public typealias MilliSeconds = Int

public class FDCriticalPoint {

    public var value: Double
    public var time: MilliSeconds
    public var duration: MilliSeconds // In milliseconds
    public var pointType: PointType

    public init(value: Double, time: MilliSeconds, duration: MilliSeconds, pointType: PointType) {
        self.value = value
        self.time = time
        self.duration = duration
        self.pointType = pointType
    }

}

public enum PointType: String {
    case peak = "PEAK"
    case valley = "VALLEY"
}
