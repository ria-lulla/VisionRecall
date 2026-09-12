@preconcurrency import CoreLocation
import Foundation

/// The compact, local-only location signal consumed by `ContextEngine`.
/// Implementations never expose or persist a location history.
@MainActor
protocol LocationContextProvider: AnyObject {
    var isAtHome: Bool { get }
    var isDepartingContext: Bool { get }
    var homeLocation: HomeLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var onContextChange: (() -> Void)? { get set }

    /// Begins the system location authorization flow. Call this only after the app
    /// has shown its own rationale.
    func requestWhenInUseAuthorization()
    /// Makes the phone's current location the home geofence center.
    func setHomeToCurrentLocation()
    func clearHomeLocation()
}

/// A coarse home coordinate used only to recreate the active geofence in memory.
struct HomeLocation: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

@MainActor
final class CoreLocationContextProvider: NSObject, LocationContextProvider {
    private enum Constants {
        static let homeRegionIdentifier = "VisionRecall.home"
        static let homeRadius: CLLocationDistance = 150
    }

    private let manager: CLLocationManager
    private let defaults: UserDefaults
    private(set) var isAtHome = false
    private(set) var isDepartingContext = false
    private(set) var homeLocation: HomeLocation?
    var onContextChange: (() -> Void)?

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    init(defaults: UserDefaults = .standard) {
        manager = CLLocationManager()
        self.defaults = defaults
        if defaults.object(forKey: "VisionRecall.homeLatitude") != nil,
           defaults.object(forKey: "VisionRecall.homeLongitude") != nil {
            homeLocation = HomeLocation(
                latitude: defaults.double(forKey: "VisionRecall.homeLatitude"),
                longitude: defaults.double(forKey: "VisionRecall.homeLongitude")
            )
        }
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways,
           let homeLocation {
            configureHomeRegion(at: CLLocationCoordinate2D(latitude: homeLocation.latitude, longitude: homeLocation.longitude))
        }
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func setHomeToCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.requestLocation()
    }

    func clearHomeLocation() {
        manager.monitoredRegions
            .filter { $0.identifier == Constants.homeRegionIdentifier }
            .forEach(manager.stopMonitoring(for:))
        homeLocation = nil
        defaults.removeObject(forKey: "VisionRecall.homeLatitude")
        defaults.removeObject(forKey: "VisionRecall.homeLongitude")
        update(isAtHome: false, isDepartingContext: false)
    }

    private func configureHomeRegion(at coordinate: CLLocationCoordinate2D) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        let radius = min(Constants.homeRadius, manager.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: Constants.homeRegionIdentifier
        )
        manager.monitoredRegions
            .filter { $0.identifier == Constants.homeRegionIdentifier }
            .forEach(manager.stopMonitoring(for:))
        manager.startMonitoring(for: region)
        manager.requestState(for: region)
    }

    private func setHomeLocation(_ location: CLLocation) {
        homeLocation = HomeLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        defaults.set(location.coordinate.latitude, forKey: "VisionRecall.homeLatitude")
        defaults.set(location.coordinate.longitude, forKey: "VisionRecall.homeLongitude")
        configureHomeRegion(at: location.coordinate)
        update(isAtHome: true, isDepartingContext: false)
        // The home coordinate itself changed even when the derived booleans did not.
        onContextChange?()
    }

    private func update(isAtHome: Bool, isDepartingContext: Bool) {
        guard self.isAtHome != isAtHome || self.isDepartingContext != isDepartingContext else { return }
        self.isAtHome = isAtHome
        self.isDepartingContext = isDepartingContext
        onContextChange?()
    }
}

extension CoreLocationContextProvider: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onContextChange?()
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            return
        }
        if let homeLocation {
            configureHomeRegion(at: CLLocationCoordinate2D(latitude: homeLocation.latitude, longitude: homeLocation.longitude))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if homeLocation == nil {
            setHomeLocation(location)
        } else if let region = manager.monitoredRegions.first(where: { $0.identifier == Constants.homeRegionIdentifier }) as? CLCircularRegion {
            update(isAtHome: region.contains(location.coordinate), isDepartingContext: isDepartingContext)
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard region.identifier == Constants.homeRegionIdentifier else { return }
        switch state {
        case .inside:
            update(isAtHome: true, isDepartingContext: false)
        case .outside:
            update(isAtHome: false, isDepartingContext: false)
        case .unknown:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == Constants.homeRegionIdentifier else { return }
        update(isAtHome: true, isDepartingContext: false)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == Constants.homeRegionIdentifier else { return }
        // An exit event, rather than a continuous coordinate, is the departure signal.
        update(isAtHome: false, isDepartingContext: true)
    }
}

/// Test-only location provider. Tests drive transitions directly without Core Location.
@MainActor
final class MockLocationContextProvider: LocationContextProvider {
    private(set) var isAtHome: Bool
    private(set) var isDepartingContext: Bool
    private(set) var homeLocation: HomeLocation?
    var authorizationStatus: CLAuthorizationStatus
    var onContextChange: (() -> Void)?

    init(
        isAtHome: Bool = false,
        isDepartingContext: Bool = false,
        homeLocation: HomeLocation? = nil,
        authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    ) {
        self.isAtHome = isAtHome
        self.isDepartingContext = isDepartingContext
        self.homeLocation = homeLocation
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() { authorizationStatus = .authorizedWhenInUse }
    func setHomeToCurrentLocation() { }
    func clearHomeLocation() { setContext(isAtHome: false, isDepartingContext: false) }

    func setContext(isAtHome: Bool, isDepartingContext: Bool) {
        self.isAtHome = isAtHome
        self.isDepartingContext = isDepartingContext
        onContextChange?()
    }
}
