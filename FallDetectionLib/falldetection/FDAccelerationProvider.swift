//
// Created by Peter Boberg on 2018-05-31.
// Copyright (c) 2018 Frost AB. All rights reserved.
//

import Foundation
import RxSwift
import CoreMotion
import CoreLocation

protocol FDAccelerationProvider: class {
    var accelerometerUpdateInterval: Double { get set }
    var accelerometerData: Observable<Double> { get }
    func startAccelerometer()
    func stopAccelerometer()
    func getMostAccurateLocation(_: @escaping (Double, Double) -> ())
}

class FDAccelerometerProviderImpl: NSObject, FDAccelerationProvider {

    // Internal properties
    static let shared = FDAccelerometerProviderImpl()

    var accelerometerUpdateInterval: Double {
        get {
            return self.motionManager.accelerometerUpdateInterval
        }
        set {
            self.motionManager.accelerometerUpdateInterval = newValue
        }
    }

    var accelerometerData: Observable<Double> {
        return self.accelerationSubject.asObservable()
    }

    // Private properties
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let acceleratorMonitorQueue = OperationQueue()
    private let accelerationSubject = PublishSubject<Double>()
    private let maxLocationAccuracyTimeOut = 5.0
    private var isMeasuringLocationForAlarm = false

    override private init() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.motionManager.accelerometerUpdateInterval = FDConstants.updateInterval
        super.init()
        self.locationManager.delegate = self
    }

    func startAccelerometer() {
        self.locationManager.startUpdatingLocation()
        self.motionManager.startAccelerometerUpdates(to: self.acceleratorMonitorQueue, withHandler: { [weak self] (data, error) in
            if let data = data {
                let userVector = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))
                self?.accelerationSubject.onNext(userVector)
            }
        })
    }

    func stopAccelerometer() {
        self.locationManager.stopUpdatingLocation()
        self.motionManager.stopDeviceMotionUpdates()
    }

    func getMostAccurateLocation(_ completion: @escaping (Double, Double) -> ()) {
        self.isMeasuringLocationForAlarm = true
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        Timer.scheduledTimer(withTimeInterval: self.maxLocationAccuracyTimeOut, repeats: false, block: { [weak self] timer in
            guard let location = self?.locationManager.location else { return }
            DispatchQueue.main.async(execute: {

                completion(location.coordinate.latitude, location.coordinate.longitude)
                self?.isMeasuringLocationForAlarm = false
            })
        })
    }
}

extension FDAccelerometerProviderImpl: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !self.isMeasuringLocationForAlarm {
            // Does nothing for the most time
            switch locationManager.activityType {
                case .automotiveNavigation:
                    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                default:
                    manager.desiredAccuracy = kCLLocationAccuracyKilometer
            }
        }
    }
}



