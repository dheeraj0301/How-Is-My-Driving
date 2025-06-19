//
//  DrivingScoreManager.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation
import CoreMotion
import Combine // For using timers and publishers if needed for debouncing etc.

// Enum to represent the state of a driving trip
enum TripState: String, Codable {
    case idle // App is open, no trip active (or after app launch before anything)
    case active // Trip is currently being recorded
    case paused // Trip was active, but is now paused
    case stopped // Trip has been explicitly stopped by the user (ready for summary or new trip)
}

class DrivingScoreManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties for UI
    @Published var currentScore: Int = 100
    @Published var currentSpeedMPH: Double = 0 // Speed in MPH for display
    @Published var postedSpeedLimitMPH: Double = 30 // Speed limit in MPH
    @Published var drivingEvents: [DrivingEvent] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var tripState: TripState = .idle
    @Published var tripStatusMessage: String = "Ready to drive."

    // Permissions
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var motionPermissionStatus: CMAuthorizationStatus = .notDetermined // General Motion & Fitness Activity status
    @Published var isMotionActivityAvailable: Bool = true // For general Motion & Fitness

    // MARK: - Internal Properties
    private var locationManager: CLLocationManager?
    private let motionManager = CMMotionManager() // For accelerometer and gyroscope data
    private let motionActivityManager = CMMotionActivityManager() // Re-added for permission requests
    private var smoothDrivingTimer: Timer?
    private var prolongedSpeedingTimer: Timer?
    private var lastLocation: CLLocation?
    private var lastSpeedCheckTime: Date?


    // Thresholds for event detection (these would need tuning)
    private let harshAccelerationThreshold: Double = 2.5 // m/s^2 (forward Gs, positive Y on device if upright)
    private let harshBrakingThreshold: Double = -3.0    // m/s^2 (backward Gs, negative Y on device if upright)
    private let aggressiveTurnThreshold: Double = 0.4  // Lateral G's (approx. using Z-axis rotation rate for simplicity)
    private let speedingThresholdMPH: Double = 10      // MPH over limit to be considered speeding
    private let prolongedSpeedingDuration: TimeInterval = 10.0 // seconds

    // Constants
    private let mphConversionFactor: Double = 2.23694 // m/s to mph

    override init() {
        super.init()
        loadUserProfile()
        loadScoreAndEvents()
        setupLocationManager()
        checkMotionAvailability() // Checks general motion activity and specific sensor availability
        loadTripState()
        updateTripStatusMessage()
    }

    // MARK: - Trip Lifecycle Management
    func startTrip() {
        guard tripState == .idle || tripState == .stopped else {
            print("Trip cannot be started from current state: \(tripState)")
            return
        }
        
        currentScore = 100
        drivingEvents.removeAll()
        currentSpeedMPH = 0
        lastLocation = nil
        addEvent(type: .tripStart, points: 0)
        
        tripState = .active
        updateTripStatusMessage()
        saveTripState()
        
        startLocationUpdates()
        startMotionUpdates() // For accelerometer and gyro
        startSmoothDrivingTimer()
        print("Trip Started. Score reset. Location and Motion updates started.")
    }

    func pauseTrip() {
        guard tripState == .active else {
            print("Trip cannot be paused from current state: \(tripState)")
            return
        }
        tripState = .paused
        addEvent(type: .tripPause, points: 0)
        updateTripStatusMessage()
        saveTripState()
        
        locationManager?.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        invalidateSmoothDrivingTimer()
        invalidateProlongedSpeedingTimer()
        print("Trip Paused. Location and Motion updates stopped.")
    }

    func resumeTrip() {
        guard tripState == .paused else {
            print("Trip cannot be resumed from current state: \(tripState)")
            return
        }
        tripState = .active
        addEvent(type: .tripResume, points: 0)
        updateTripStatusMessage()
        saveTripState()
        
        startLocationUpdates()
        startMotionUpdates()
        startSmoothDrivingTimer()
        print("Trip Resumed. Location and Motion updates restarted.")
    }

    func stopTrip() {
        guard tripState == .active || tripState == .paused else {
            print("Trip cannot be stopped from current state: \(tripState)")
            return
        }
        
        addEvent(type: .tripEnd, points: 0)
        let finalScore = currentScore
        tripState = .stopped
        updateTripStatusMessage(score: finalScore)
        saveTripState()
        
        locationManager?.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        invalidateSmoothDrivingTimer()
        invalidateProlongedSpeedingTimer()
        
        saveScoreAndEvents()
        print("Trip Stopped. Final Score: \(finalScore). Location and Motion updates stopped.")
    }
    
    func resetCurrentTripDataAndScore() {
        currentScore = 100
        drivingEvents.removeAll()
        currentSpeedMPH = 0
        lastLocation = nil
        saveScoreAndEvents()
        // If a trip was active/paused, it's good to also set it to stopped or idle.
        if tripState == .active || tripState == .paused {
            tripState = .stopped // Or .idle, depending on desired flow
            addEvent(type: .tripEnd, points: 0) // Log that the "reset" effectively ended the previous session
            updateTripStatusMessage(score: currentScore)
            saveTripState()
        }
        print("Current trip data and score have been reset.")
    }

    private func updateTripStatusMessage(score: Int? = nil) {
        switch tripState {
        case .idle:
            tripStatusMessage = "Press 'Start Trip' to begin monitoring."
        case .active:
            tripStatusMessage = "Trip in progress..."
        case .paused:
            tripStatusMessage = "Trip paused. Press 'Resume' or 'Stop'."
        case .stopped:
            let scoreToDisplay = score ?? currentScore // Use provided score or current if nil
            tripStatusMessage = "Trip ended. Final Score: \(scoreToDisplay). Ready for new trip."
        }
    }

    // MARK: - Scoring Logic
    func addEvent(type: DrivingEvent.EventType, points: Int, magnitude: Double? = nil, duration: TimeInterval? = nil) {
        let informationalEvents: [DrivingEvent.EventType] = [.tripStart, .tripEnd, .tripPause, .tripResume]
        
        // Allow informational events regardless of trip state for logging purposes.
        // For other events, only log if the trip is active.
        if !informationalEvents.contains(type) && tripState != .active {
            print("Event \(type.rawValue) ignored: Trip not active.")
            return
        }

        let event = DrivingEvent(type: type, points: points, timestamp: Date(), magnitude: magnitude, duration: duration)
        drivingEvents.insert(event, at: 0)
        
        let scoreAffectingEvents: [DrivingEvent.EventType] = [
            .harshBraking, .rapidAcceleration, .aggressiveLeftTurn, .aggressiveRightTurn,
            .aggressiveSpeeding, .prolongedSpeeding, .suddenLaneChange, .phoneUsage,
            .smoothDriving, .adherenceToSpeedLimit, .gentleManeuver, .efficientAcceleration
        ]
        if scoreAffectingEvents.contains(type) {
            currentScore += points
            currentScore = max(0, min(100, currentScore))
        }
        
        saveScoreAndEvents()
        print("Event: \(event.description), New Score: \(currentScore)")
    }

    // MARK: - User Profile Management
    func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }

    private func loadUserProfile() {
        if let savedProfile = UserDefaults.standard.data(forKey: "userProfile") {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
                userProfile = decodedProfile; return
            }
        }
        userProfile = UserProfile()
    }

    // MARK: - Persistence for Score, Events, and Trip State
    private func saveScoreAndEvents() {
        UserDefaults.standard.set(currentScore, forKey: "currentScore")
        if let encodedEvents = try? JSONEncoder().encode(drivingEvents) {
            UserDefaults.standard.set(encodedEvents, forKey: "drivingEvents")
        }
    }

    private func loadScoreAndEvents() {
        currentScore = UserDefaults.standard.integer(forKey: "currentScore")
        if currentScore == 0 && UserDefaults.standard.object(forKey: "currentScore") == nil {
            currentScore = 100
        }

        if let savedEvents = UserDefaults.standard.data(forKey: "drivingEvents") {
            if let decodedEvents = try? JSONDecoder().decode([DrivingEvent].self, from: savedEvents) {
                drivingEvents = decodedEvents
            }
        }
    }

    private func saveTripState() {
        UserDefaults.standard.set(tripState.rawValue, forKey: "currentTripState")
    }

    private func loadTripState() {
        if let rawState = UserDefaults.standard.string(forKey: "currentTripState"),
           let loadedState = TripState(rawValue: rawState) {
            tripState = loadedState
            if tripState == .active || tripState == .paused {
                print("App restarted during an active/paused trip. Setting trip state to stopped.")
                tripState = .stopped
                // Optionally add an event to signify this auto-stop
                // addEvent(type: .tripEnd, points: 0, magnitude: nil, duration: nil) // This might add duplicate tripEnd if already saved
                saveTripState() // Save the new 'stopped' state
                 // Score and events from the interrupted trip should already be loaded by loadScoreAndEvents()
            }
        } else {
            tripState = .idle
        }
        updateTripStatusMessage(score: tripState == .stopped ? currentScore : nil)
    }

    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.showsBackgroundLocationIndicator = true
        locationPermissionStatus = CLLocationManager.authorizationStatus()
    }

    func startLocationUpdates() {
        guard tripState == .active else { return }
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled.")
            // TODO: Update UI to inform user (e.g., via a published property or alert)
            return
        }

        if locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways {
            locationManager?.startUpdatingLocation()
            print("Location updates started.")
        } else if locationPermissionStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else {
            print("Location permission not granted: \(locationPermissionStatus.description)")
            // TODO: Update UI, guide to settings
        }
    }

    // MARK: - Motion Management (Accelerometer & Gyroscope)
    private func startMotionUpdates() {
        guard tripState == .active else { return }
        
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available.")
            // Consider updating a more specific flag if needed for UI
            return
        }
        guard motionManager.isGyroAvailable else {
            print("Gyroscope not available.")
            return
        }

        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz
        motionManager.gyroUpdateInterval = 0.1       // 10 Hz

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (accelerometerData, error) in
            guard let self = self, self.tripState == .active, let data = accelerometerData else { return }
            if error == nil {
                self.processAccelerometerData(data.acceleration)
            } else {
                print("Accelerometer Error: \(error!.localizedDescription)")
            }
        }
        
        motionManager.startGyroUpdates(to: .main) { [weak self] (gyroData, error) in
            guard let self = self, self.tripState == .active, let data = gyroData else { return }
            if error == nil {
                self.processGyroData(data.rotationRate)
            } else {
                print("Gyro Error: \(error!.localizedDescription)")
            }
        }
        print("Motion (Accelerometer & Gyro) updates started.")
    }
    
    private func processAccelerometerData(_ acceleration: CMAcceleration) {
        // Simplified: Y-axis for acceleration/braking assuming portrait phone orientation.
        // A robust solution needs device attitude to get car's frame of reference.
        let longitudinalAcceleration = acceleration.y
        
        if longitudinalAcceleration > harshAccelerationThreshold {
            addEvent(type: .rapidAcceleration, points: -4, magnitude: longitudinalAcceleration)
        }
        
        if longitudinalAcceleration < harshBrakingThreshold {
            addEvent(type: .harshBraking, points: -5, magnitude: longitudinalAcceleration)
        }
    }

    private func processGyroData(_ rotationRate: CMRotationRate) {
        // Simplified: Z-axis for turns (yaw rate). Robust solution needs attitude.
        let yawRate = rotationRate.z
        
        if abs(yawRate) > aggressiveTurnThreshold {
            if yawRate > 0 { // Convention: Positive for left turn (can vary)
                addEvent(type: .aggressiveLeftTurn, points: -3, magnitude: yawRate)
            } else { // Negative for right turn
                addEvent(type: .aggressiveRightTurn, points: -3, magnitude: yawRate)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
            if self.locationPermissionStatus == .authorizedWhenInUse || self.locationPermissionStatus == .authorizedAlways {
                if self.tripState == .active {
                    self.startLocationUpdates()
                }
            } else {
                 if self.tripState == .active || self.tripState == .paused {
                    print("Location permission revoked/denied during an active/paused trip. Pausing trip.")
                    self.locationManager?.stopUpdatingLocation()
                    if self.tripState == .active { self.pauseTrip() }
                 }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard tripState == .active, let location = locations.last else { return }
        lastLocation = location
        
        let speedMS = location.speed >= 0 ? location.speed : 0
        currentSpeedMPH = speedMS * mphConversionFactor
        
        checkSpeeding(currentSpeed: currentSpeedMPH, speedLimit: postedSpeedLimitMPH)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
        if (error as NSError).code == CLError.denied.rawValue {
            DispatchQueue.main.async {
                self.locationPermissionStatus = .denied
                 if self.tripState == .active || self.tripState == .paused {
                    print("Location services denied by user during trip. Pausing trip.")
                    if self.tripState == .active { self.pauseTrip() }
                }
            }
        }
    }
    
    // MARK: - Event Detection Helpers
    private func checkSpeeding(currentSpeed: Double, speedLimit: Double) {
        guard speedLimit > 0 else { return }

        if currentSpeed > (speedLimit + speedingThresholdMPH) {
            if prolongedSpeedingTimer == nil {
                addEvent(type: .aggressiveSpeeding, points: -2, magnitude: currentSpeed - speedLimit)
                
                prolongedSpeedingTimer = Timer.scheduledTimer(withTimeInterval: prolongedSpeedingDuration, repeats: false) { [weak self] _ in
                    guard let self = self, self.tripState == .active else {
                        self?.invalidateProlongedSpeedingTimer()
                        return
                    }
                    if self.currentSpeedMPH > (self.postedSpeedLimitMPH + self.speedingThresholdMPH) {
                        self.addEvent(type: .prolongedSpeeding, points: -5, magnitude: self.currentSpeedMPH - self.postedSpeedLimitMPH, duration: self.prolongedSpeedingDuration)
                    }
                    self.invalidateProlongedSpeedingTimer()
                }
            }
        } else {
            invalidateProlongedSpeedingTimer()
        }
    }

    // MARK: - Smooth Driving Timer & Logic
     private func startSmoothDrivingTimer() {
        guard tripState == .active else { return }
        invalidateSmoothDrivingTimer()
        smoothDrivingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self, self.tripState == .active else {
                self?.invalidateSmoothDrivingTimer()
                return
            }
            let recentNegativeEvents = self.drivingEvents.filter {
                $0.timestamp > Date().addingTimeInterval(-15) && $0.points < 0
            }
            if recentNegativeEvents.isEmpty && self.currentSpeedMPH > 5 {
                self.addEvent(type: .smoothDriving, points: +1)
            }
        }
    }

    private func invalidateSmoothDrivingTimer() {
        smoothDrivingTimer?.invalidate()
        smoothDrivingTimer = nil
    }
    
    private func invalidateProlongedSpeedingTimer() {
        prolongedSpeedingTimer?.invalidate()
        prolongedSpeedingTimer = nil
    }

    // MARK: - Permissions
    private func checkMotionAvailability() {
        // Check for general Motion & Fitness Activity availability
        self.isMotionActivityAvailable = CMMotionActivityManager.isActivityAvailable()
        
        // Also check if specific sensors (accelerometer, gyro) are available via CMMotionManager
        let sensorsAvailable = motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable
        
        if !self.isMotionActivityAvailable || !sensorsAvailable {
            print("Motion activity or specific sensors (Accel/Gyro) not available on this device.")
            // If general motion activity is not available, set status to restricted.
            // Individual sensor checks (isAccelerometerAvailable) don't have separate auth statuses.
            if !self.isMotionActivityAvailable {
                 self.motionPermissionStatus = .restricted
            }
        } else {
            // Get the authorization status for CMMotionActivityManager (Motion & Fitness)
            self.motionPermissionStatus = CMMotionActivityManager.authorizationStatus()
        }
         print("Motion Availability Check: General Activity Available: \(self.isMotionActivityAvailable), Sensors (Accel/Gyro) Available: \(sensorsAvailable), Motion Permission Status: \(self.motionPermissionStatus.customDescription)")
    }


    func requestLocationPermission() {
        if locationPermissionStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
            // Optionally, guide user to settings
            print("Location permission was denied or restricted. Guide user to settings.")
        }
    }
    
    // This method requests permission for CMMotionActivityManager (Motion & Fitness)
    // which is a higher-level API than direct CMMotionManager sensor access.
    // Direct sensor access (accelerometer, gyro) usually doesn't require a separate explicit prompt
    // beyond the app's general capabilities, but their data might be restricted if Motion & Fitness is denied.
    func requestMotionPermission() {
        guard isMotionActivityAvailable else {
            print("Motion activity not available, cannot request permission.")
            // UI should reflect that this feature is unavailable.
            return
        }

        if motionPermissionStatus == .notDetermined {
            // Querying CMMotionActivityManager can trigger the system prompt for Motion & Fitness.
            self.motionActivityManager.queryActivityStarting(from: Date(timeIntervalSinceNow: -3600), to: Date(), to: .main) { [weak self] (activities, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error as NSError? {
                        print("Motion Activity Query Error for permission request: \(error.localizedDescription)")
                        // Update status based on error or re-check
                        self.motionPermissionStatus = CMMotionActivityManager.authorizationStatus()
                    } else {
                        // If no error and activities are returned (even if nil/empty), permission was likely granted or already determined.
                        self.motionPermissionStatus = CMMotionActivityManager.authorizationStatus() // Re-check to be sure
                        if self.motionPermissionStatus == .notDetermined { // If still not determined after query (unlikely but possible)
                            print("Motion permission still not determined after query.")
                        } else if self.motionPermissionStatus == .authorized {
                             print("Motion & Fitness permission granted.")
                        }
                    }
                    self.objectWillChange.send() // Ensure UI updates if status changes
                }
            }
        } else if motionPermissionStatus == .denied || motionPermissionStatus == .restricted {
            print("Motion & Fitness permission was denied or restricted. Guide user to settings.")
            // Optionally, guide user to settings
        }
    }

    func updatePermissionStatus() { // Call on app foreground or view appear
        locationPermissionStatus = CLLocationManager.authorizationStatus()
        checkMotionAvailability() // Re-check sensor availability and general motion permission
        self.objectWillChange.send() // Manually notify observers if statuses changed
    }
}


