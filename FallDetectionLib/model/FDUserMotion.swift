//
// Created by Peter Boberg on 2018-04-06.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation

public class FDUserMotion {

    public var date: Date = Date()
    public var valleys: [FDCriticalPoint] = []
    public var peaks: [FDCriticalPoint] = []
    public var impactStart: MilliSeconds = 0
    public var impactEnd: MilliSeconds = 0

    public var averageAccelerationVariation: Double = 0.0
    public var impactDuration: MilliSeconds = 0

    public var impactPeakValue: Double = 0.0
    public var impactPeakDuration: MilliSeconds = 0

    public var longestValleyValue: Double = 0.0
    public var longestValleyDuration: MilliSeconds = 0

    public var numberOfPeaksPriorToImpact: Int = 0
    public var numberOfValleysPriorToImpact: Int = 0

    public var data: [Double] = []

    public var classificationType: ClassificationType = .notDefined

    public static func emptyMotion() -> FDUserMotion {
        return FDUserMotion()
    }
}

public enum ClassificationType: String {
    case fall = "FALL"
    case jump = "JUMP"
    case runOrWalk = "RUN_OR_WALK"
    case notDefined = "Not yet defined"

    public static func classificationTypeBy(index: Int) -> ClassificationType {
        switch index {
            case 0:
                return .fall
            case 1:
                return .jump
            case 2:
                return .runOrWalk
            default:
                return .notDefined
        }
    }
}
