import Foundation
import CoreLocation
import Contacts
import EventKit
import Combine

class DeviceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = DeviceManager()
    
    // Publishers for UI toggles
    @Published var isLocationAuthorized = false
    @Published var isContactsAuthorized = false
    @Published var isCalendarAuthorized = false
    
    private let locationManager = CLLocationManager()
    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()
    
    // Store current location
    @Published var currentLocation: CLLocation?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        checkInitialPermissions()
    }
    
    private func checkInitialPermissions() {
        // Location
        let locStatus = locationManager.authorizationStatus
        isLocationAuthorized = (locStatus == .authorizedWhenInUse || locStatus == .authorizedAlways)
        
        // Contacts
        let contactStatus = CNContactStore.authorizationStatus(for: .contacts)
        isContactsAuthorized = (contactStatus == .authorized)
        
        // Calendar
        let calStatus = EKEventStore.authorizationStatus(for: .event)
        isCalendarAuthorized = (calStatus == .authorized)
    }
    
    // MARK: - Location
    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
            if self.isLocationAuthorized {
                self.locationManager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.currentLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    // MARK: - Contacts
    func requestContactsAccess(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.isContactsAuthorized = granted
                completion(granted)
            }
        }
    }
    
    func fetchContacts() -> [CNContact] {
        guard isContactsAuthorized else { return [] }
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts: [CNContact] = []
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
        return contacts
    }
    
    // MARK: - Calendar
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.isCalendarAuthorized = granted
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.isCalendarAuthorized = granted
                    completion(granted)
                }
            }
        }
    }
    
    func fetchUpcomingEvents() -> [EKEvent] {
        guard isCalendarAuthorized else { return [] }
        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        return eventStore.events(matching: predicate)
    }
    
    // MARK: - API for Backend (Qarin)
    /// This function acts as the bridge. When the backend agent requests device context, this returns a serialized payload.
    func buildDeviceContextPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
        
        if isLocationAuthorized, let loc = currentLocation {
            payload["location"] = ["lat": loc.coordinate.latitude, "lon": loc.coordinate.longitude]
        } else {
            payload["location"] = "Access Denied / Unavailable"
        }
        
        if isCalendarAuthorized {
            let events = fetchUpcomingEvents().prefix(5).map { "\($0.title ?? "Event") at \($0.startDate ?? Date())" }
            payload["upcoming_events"] = events
        }
        
        return payload
    }
}
