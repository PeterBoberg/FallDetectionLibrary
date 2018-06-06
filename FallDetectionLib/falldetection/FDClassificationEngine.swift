//
// Created by Peter Boberg on 2018-04-27.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation
import CoreML


protocol FDClassificationEngine {
    func classify(userMotion: FDUserMotion) -> ClassificationType?
}


class FDClassificationEngineImpl: FDClassificationEngine {

    static let shared = FDClassificationEngineImpl()

    private let model: MLModel

    private init() {

        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "Falls", ofType: "mlmodelc")!)
        self.model = try! MLModel(contentsOf: url)
    }

    func classify(userMotion: FDUserMotion) -> ClassificationType? {
        let inputs = try! MLMultiArray(shape: [8], dataType: .double)
        inputs[0] = NSNumber(value: userMotion.averageAccelerationVariation)
        inputs[1] = NSNumber(value: userMotion.impactDuration)
        inputs[2] = NSNumber(value: userMotion.impactPeakValue)
        inputs[3] = NSNumber(value: userMotion.impactPeakDuration)
        inputs[4] = NSNumber(value: userMotion.longestValleyValue)
        inputs[5] = NSNumber(value: userMotion.longestValleyDuration)
        inputs[6] = NSNumber(value: userMotion.numberOfPeaksPriorToImpact)
        inputs[7] = NSNumber(value: userMotion.numberOfValleysPriorToImpact)

        let options = MLPredictionOptions()
        options.usesCPUOnly = true

        do {
            let outputOptional = try self.model.prediction(from: FallsInput(features: inputs), options: options).featureValue(for: "output_classes")

            guard let output = outputOptional else {
                return nil
            }

            guard let fallPredict = output.multiArrayValue?[0],
                  let jumpPredict = output.multiArrayValue?[1],
                  let runWalkPredict = output.multiArrayValue?[2] else { return nil }

            

            let swiftArray = [Double(fallPredict), Double(jumpPredict), Double(runWalkPredict)]
            guard let maxValue = swiftArray.max() else { return nil }
            guard let classificationIndex = swiftArray.index(of: maxValue) else { return nil }

            return ClassificationType.classificationTypeBy(index: classificationIndex)
        } catch {
            return nil
        }
    }
}
