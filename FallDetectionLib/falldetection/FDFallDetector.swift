//
// Created by Peter Boberg on 2018-04-09.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import Dispatch
import RxSwift

public class FDFallDetector: NSObject {

    // MARK: - Public properties
    public weak var delegate: FallDetectorDelegate?
    public let detectionEnabled = Variable<Bool>(false)
    public private(set) var state: State = .normal

    // MARK: - Private properties
    private let accelerationProvider: FDAccelerationProvider
    private let classificationEngine: FDClassificationEngine
    private let featureExtractor: FDFeatureExtractor
    private var ringBuffer: FDRingBuffer
    private var timer: Timer?

    private var latestStateTransition = Date().timeIntervalSince1970
    private var fallDetectionReported = false
    private let bag = DisposeBag()

    override init() {
        self.accelerationProvider = FDAccelerometerProviderImpl.shared
        self.classificationEngine = FDClassificationEngineImpl.shared
        self.ringBuffer = FDRingBuffer(capacity: FDConstants.ringBufferCapacity(), frequency: FDConstants.frequency())

        self.featureExtractor = FDFeatureExtractorImpl(withBlock: {
            var config = FeatureExtractorConfig()
            config.impactThreshold = FDConstants.impactThreshold
            config.upperMotionLessThreshold = FDConstants.upperMotionlessThreshold
            config.loweMotionLessThreshold = FDConstants.lowerMotionlessThreshold
            config.preImpactEndTime = FDConstants.preImpactEndTime() // 4 seconds
            config.postImpactEndTime = FDConstants.postImpactEndTime() // 4 + 2 seconds
            return config
        })
        super.init()
        self.setupObservers()
    }

    init(accelerationProvider: FDAccelerationProvider, classificationEngine: FDClassificationEngine,
         featureExtractor: FDFeatureExtractor, ringBuffer: FDRingBuffer) {

        self.accelerationProvider = accelerationProvider
        self.classificationEngine = classificationEngine
        self.featureExtractor = featureExtractor
        self.ringBuffer = ringBuffer
        super.init()
        self.setupObservers()
    }

    public func initialize() {
        let _ = self.classificationEngine.classify(userMotion: FDUserMotion.emptyMotion())
    }

    public func reset() {
        self.fallDetectionReported = false
        self.state = .normal
    }

    public enum State {
        case normal
        case falling
        case postFalling
        case impact
        case motionLess
        case fallDetected
    }

    public func getMostAccurateLocation(_ completion: @escaping (Double, Double) -> ()) {
        self.accelerationProvider.getMostAccurateLocation(completion)
    }
}

// MARK: - Private Methods
extension FDFallDetector {

    private func setupObservers() {
        self.detectionEnabled
                .asObservable()
                .skip(1)
                .subscribe(onNext: { [weak self] (enable) in
                    guard let `self` = self else { return }
                    enable ? self.accelerationProvider.startAccelerometer() : self.accelerationProvider.stopAccelerometer()
                }).disposed(by: self.bag)

        self.accelerationProvider.accelerometerData
                .subscribe(onNext: { [weak self] userVector in
                    guard let `self` = self else { return }
                    self.ringBuffer.add(element: userVector)

                    switch self.state {
                        case .normal:
                            self.handleNormalState(userVector)
                        case .falling:
                            self.handleFallingState(userVector)
                        case .postFalling:
                            self.handlePostFallingState(userVector)
                        case .impact:
                            self.handleImpactState(userVector)
                        case .motionLess:
                            self.handleStillState(userVector)
                        case .fallDetected:
                            self.handleFallDetected(userVector)
                    }

                })
                .disposed(by: self.bag)

    }

    private func handleNormalState(_ vector: Double) {
        if vector < FDConstants.lowerMotionlessThreshold {
            self.transit(toState: .falling)
        }
    }

    private func handleFallingState(_ vector: Double) {
        if vector >= FDConstants.impactThreshold {
            self.transit(toState: .impact)
        }
        else if vector >= FDConstants.lowerMotionlessThreshold {
            self.transit(toState: .postFalling)
        }
    }

    private func handlePostFallingState(_ vector: Double) {
        if vector < FDConstants.lowerMotionlessThreshold {
            self.transit(toState: .falling)
        }

        else if vector >= FDConstants.impactThreshold {
            self.transit(toState: .impact)
        }

        else if timeSinceLastStateTransition() >= 0.1 {
            self.transit(toState: .normal)
        }
    }

    private func handleImpactState(_ vector: Double) {

        if vector >= FDConstants.impactThreshold {
            self.transit(toState: .impact)
        }

        if timeSinceLastStateTransition() >= 2 {
            self.transit(toState: .motionLess)
        }
    }

    private func handleStillState(_ vector: Double) {
        if vector < FDConstants.lowerMotionlessThreshold {
            self.transit(toState: .falling)
        }

        else if vector >= FDConstants.upperMotionlessThreshold {
            self.transit(toState: .normal)
        }

        else if timeSinceLastStateTransition() >= 2 {
            self.transit(toState: .fallDetected)
        }
    }

    private func handleFallDetected(_ vector: Double) {

        if !fallDetectionReported {
            fallDetectionReported = true
            let userMotion = self.featureExtractor.extract(fromBuffer: self.ringBuffer)
            guard let classificationType = self.classificationEngine.classify(userMotion: userMotion) else { return }
            DispatchQueue.main.async(execute: {
                self.delegate?.userMotionClassified(self, motion: userMotion, ofType: classificationType)
            })
        }
    }

    private func transit(toState: State) {
        self.state = toState
        self.latestStateTransition = Date().timeIntervalSince1970
    }

    private func timeSinceLastStateTransition() -> Double {
        return Date().timeIntervalSince1970 - self.latestStateTransition
    }
}

public protocol FallDetectorDelegate: class {
    func userMotionClassified(_: FDFallDetector, motion: FDUserMotion, ofType: ClassificationType)
}

