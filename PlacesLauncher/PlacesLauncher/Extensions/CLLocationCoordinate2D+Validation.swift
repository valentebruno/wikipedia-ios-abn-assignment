import CoreLocation

extension CLLocationCoordinate2D {
    var isInValidRange: Bool {
        CLLocationCoordinate2DIsValid(self) &&
            latitude >= -90 && latitude <= 90 &&
            longitude >= -180 && longitude <= 180
    }
}
