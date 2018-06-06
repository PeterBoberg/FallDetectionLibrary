//
// Created by Peter Boberg on 2018-04-12.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation
import UIKit



protocol FDFeatureExtractor {

    init(withBlock: () -> FeatureExtractorConfig)
    func extract(fromBuffer: FDRingBuffer) -> FDUserMotion
}

class FDFeatureExtractorImpl: FDFeatureExtractor {

    private let config: FeatureExtractorConfig

    required init(withBlock config: () -> FeatureExtractorConfig) {
        self.config = config()
    }

    func extract(fromBuffer buffer: FDRingBuffer) -> FDUserMotion {
        let fall = FDUserMotion()
        fall.date = Date()
        let samples = buffer.retrieve()

        // Find all peaks and valleys crossing the top and bottom thresholds
        var step = 0
        while step <= self.config.postImpactEndTime {
            if samples[step] > self.config.impactThreshold {
                fall.peaks.append(findExtremePoint(ofType: .peak, fromIndex: &step, inBuffer: buffer, withThreshold: self.config.impactThreshold))
            }
            else if samples[step] < self.config.loweMotionLessThreshold {
                fall.valleys.append(findExtremePoint(ofType: .valley, fromIndex: &step, inBuffer: buffer, withThreshold: self.config.loweMotionLessThreshold))
            }
            step += 1
        }

        // if an impact peak is found, calculate impact start, end and duration. Impact peak should always be there
        if let impactPeak = fall.peaks.last {

            // Calculate impact start index
            var impactStartIdx = Int((Double(impactPeak.time) / 1000.0) * Double(buffer.frequency))
            while samples[impactStartIdx] > self.config.upperMotionLessThreshold {
                impactStartIdx -= 1
            }

            // Calculate impact end index
            var impactEndTimeIdx = self.config.postImpactEndTime
            var possibleImpactEndValue = samples[impactEndTimeIdx]
            while possibleImpactEndValue > self.config.loweMotionLessThreshold &&
                          possibleImpactEndValue < self.config.upperMotionLessThreshold &&
                          impactEndTimeIdx >= impactStartIdx {
                possibleImpactEndValue = samples[impactEndTimeIdx]
                impactEndTimeIdx -= 1
            }


            impactEndTimeIdx += 1

            // accumulate acceleration variation between impact start index and impact end index
            var accumulatedAccelerationVariation = 0.0
            var counter = impactStartIdx
            var loopCounter = 0
            while counter < impactEndTimeIdx {
                accumulatedAccelerationVariation += abs(samples[counter + 1] - samples[counter])
                counter += 1
                loopCounter += 1
                
            }

             let impactTimeIndices = Double(impactEndTimeIdx - impactStartIdx)
            fall.averageAccelerationVariation = accumulatedAccelerationVariation / (impactTimeIndices == 0.0 ? 1.0 : impactTimeIndices)

            // Find number of peaks prior to impact peak
            fall.numberOfPeaksPriorToImpact = fall.peaks.count - 1

            // If valleys are found
            if let firstValley = fall.valleys.first {

                // Find longest valley and number of valleys prior to impact peak
                var counter = 0
                var longestValley = firstValley
                var numberOfValleys = 0
                while counter < fall.valleys.count && fall.valleys[counter].time < impactPeak.time {
                    if fall.valleys[counter].duration > longestValley.duration {
                        longestValley = fall.valleys[counter]
                    }
                    numberOfValleys += 1
                    counter += 1
                }

                fall.numberOfValleysPriorToImpact = numberOfValleys
                fall.longestValleyDuration = longestValley.duration
                fall.longestValleyValue = longestValley.value
            }
            else {
                fall.numberOfValleysPriorToImpact = 0
                fall.longestValleyValue = 1.0
                fall.longestValleyDuration = 0
            }

            // Calculate impact start, end and duration in milliseconds
            let impactStart = (Double(impactStartIdx) / Double(buffer.frequency)) * 1000
            let impactEnd = (Double(impactEndTimeIdx) / Double(buffer.frequency)) * 1000
            let impactDuration = impactEnd - impactStart

            fall.impactStart = Int(impactStart)
            fall.impactEnd = Int(impactEnd)
            fall.impactDuration = Int(impactDuration)
            fall.impactPeakValue = impactPeak.value
            fall.impactPeakDuration = Int(impactPeak.duration)
        }

        fall.data = samples
        return fall
    }

    private func findExtremePoint(ofType type: PointType, fromIndex index: inout Int, inBuffer buffer: FDRingBuffer, withThreshold threshold: Double) -> FDCriticalPoint {
        let valueInBounds: (Double) -> Bool = type == .peak ? { $0 > threshold } : { $0 < threshold }
        let pointComparator: (Double, Double) -> Bool = type == .peak ? { $0 > $1 } : { $0 < $1 }

        let samples = buffer.retrieve()
        let durationStart = index
        var sampleCount = 0
        var timeIdx = index
        var currentExtremePointValue = samples[index]
        var currentPointValue = samples[index]

        while valueInBounds(currentPointValue) {
            if pointComparator(currentPointValue, currentExtremePointValue) {
                currentExtremePointValue = currentPointValue
                timeIdx = index
            }
            sampleCount += 1
            index += 1
            currentPointValue = samples[index]
        }

        let duration = (Double(sampleCount) / Double(buffer.frequency)) * 1000.0 // Milliseconds
        let time = (Double(timeIdx) / Double(buffer.frequency)) * 1000

        return FDCriticalPoint(value: currentExtremePointValue, time: Int(time), duration: Int(duration), pointType: type)
    }
}

struct FeatureExtractorConfig {
    var loweMotionLessThreshold: Double = 0.0
    var upperMotionLessThreshold: Double = 0.0
    var impactThreshold: Double = 0.0
    var preImpactEndTime: Samples = 0
    var postImpactEndTime: Samples = 0
}

enum Feature {
    case peakTime
    case impactEnd
    case impactStart
    case AAMV
    case impactDurationIndex
    case maximumPeakIndex
    case minimumValleyIndex
    case peakDurationIndex
}
