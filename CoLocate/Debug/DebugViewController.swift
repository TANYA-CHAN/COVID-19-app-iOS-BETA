//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit


class DebugViewController: UITableViewController {

    @IBOutlet weak var allowedDataSharingSwitch: UISwitch!
    @IBOutlet weak var interceptRequestsSwitch: UISwitch!
    @IBOutlet weak var newOnboardingSwitch: UISwitch!

    let persistance = Persistance.shared
    let contactEventRecorder = PlistContactEventRecorder.shared
    
    override func viewDidLoad() {
        allowedDataSharingSwitch.isOn = persistance.allowedDataSharing
        newOnboardingSwitch.isOn = persistance.newOnboarding

        #if DEBUG
            interceptRequestsSwitch.isOn = InterceptingSession.interceptNextRequest
            newOnboardingSwitch.isEnabled = true
        #else
            newOnboardingSwitch.isEnabled = false
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            persistance.clear()
            show(title: "Cleared", message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")

        case (0, 1):
            let alertController = UIAlertController(title: "Set diagnosis", message: nil, preferredStyle: .actionSheet)
            for diagnosis in Diagnosis.allCases {
                alertController.addAction(UIAlertAction(title: "\(diagnosis)", style: .default) { _ in
                    Persistance.shared.diagnosis = diagnosis
                    self.show(title: "Cleared", message: "Diagnosis data has been set. Please stop and re-start the application.")
                })
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alertController, animated: true, completion: nil)

        case (0, 2):
            break

        case (1, 0):
            contactEventRecorder.record(ContactEvent(sonarId: UUID(), timestamp: Date(), rssiValues: [42, 17, -2], duration: 42))
            contactEventRecorder.record(ContactEvent(sonarId: UUID(), timestamp: Date(), rssiValues: [17, -2, 42], duration: 17))
            contactEventRecorder.record(ContactEvent(sonarId: UUID(), timestamp: Date(), rssiValues: [-2, 42, 17], duration: 2))
            show(title: "Events Recorded", message: "Dummy contact events have been recorded locally (but not sent to the server.)")
            
        case (1, 1):
            contactEventRecorder.reset()
            show(title: "Cleared", message: "All contact events cleared.")
            
        case (2, 0):
            do {
                guard let registration = persistance.registration else {
                    throw NSError()
                }
                let delay = 15
                let request = TestPushRequest(key: registration.secretKey, sonarId: registration.id, delay: delay)
                URLSession.shared.execute(request, queue: .main) { result in
                    switch result {
                    case .success:
                        self.show(title: "Push scheduled", message: "Scheduled push with \(delay) second delay")
                    case .failure(let error):
                        self.show(title: "Failed", message: "Failed scheduling push: \(error)")
                    }
                }
            } catch {
                show(title: "Failed", message: "Couldn't get sonarId, has this device completed registration?")
            }

        case (3, 0), (4, 0):
            break

        case (5, 0):
            do {
                let fileManager = FileManager()
                let documentsFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let viewController = UIActivityViewController(activityItems: [documentsFolder], applicationActivities: nil)
                present(viewController, animated: true, completion: nil)
            } catch {
                let viewController = UIAlertController(title: "No data to share yet", message: nil, preferredStyle: .alert)
                viewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(viewController, animated: true, completion: nil)
            }

        default:
            fatalError()
        }
    }

    private func show(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func allowedDataSharingChanged(_ sender: UISwitch) {
        persistance.allowedDataSharing = sender.isOn
    }

    @IBAction func interceptRegistrationRequestsChanged(_ sender: UISwitch) {
        #if DEBUG
        InterceptingSession.interceptNextRequest = sender.isOn
        #else
        let alert = UIAlertController(title: "Unavailable", message: "This dangerous action is only available in debug builds.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        sender.isOn = false
        #endif
    }

    @IBAction func newOnboardingChanged(_ sender: UISwitch) {
        persistance.newOnboarding = sender.isOn
    }

}

class TestPushRequest: SecureRequest, Request {
    
    typealias ResponseType = Void
                    
    let method: HTTPMethod
    
    let path: String
    
    init(key: Data, sonarId: UUID, delay: Int = 0) {
        let data = Data()
        method = .post(data: data)
        path = "/api/debug/notification/residents/\(sonarId.uuidString)?delay=\(delay)"
        
        super.init(key, data, [:])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
}
