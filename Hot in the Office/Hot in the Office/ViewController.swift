//
//  ViewController.swift
//  Hot in the Office
//
//  Created by James on 28/07/2017.
//  Copyright © 2017 Rantmedia. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

	@IBOutlet weak var temperatureLabel: UILabel!
	
	var databaseReference: DatabaseReference!
	var temperatureHandle: DatabaseHandle?
	
	var currentTemperature: Double = 0.0 {
		didSet {
			print("temp: \(currentTemperature)")
			temperatureLabel.text = String(format: "%.1f°C", currentTemperature)
		}
	}
	
	deinit {
		if let temperatureHandle = temperatureHandle {
			databaseReference.removeObserver(withHandle: temperatureHandle)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		databaseReference = Database.database().reference()
		temperatureHandle = databaseReference.observe(.value) { [unowned self] snapshot in
			let temperatureDict = snapshot.value as? [String: AnyObject] ?? [:]
			self.currentTemperature = (temperatureDict["current_temperature"] as? Double) ?? 0.0
		}
	}
}

