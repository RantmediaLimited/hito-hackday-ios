//
//  ViewController.swift
//  Hot in the Office
//
//  Created by James on 28/07/2017.
//  Copyright © 2017 Rantmedia. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	struct HistoricTemperature {
		let date: Date
		let temperature: Double
	}
	
	let dateFormatter = DateFormatter()
	
	@IBOutlet weak var temperatureLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	var databaseReference: DatabaseReference!
	var temperatureHandle: DatabaseHandle?
	
	var currentTemperature: Double = 0.0 {
		didSet {
			print("temp: \(currentTemperature)")
			temperatureLabel.text = String(format: "%.1f°C", currentTemperature)
		}
	}
	
	var temperatureHistory = [HistoricTemperature]()
	
	deinit {
		if let temperatureHandle = temperatureHandle {
			databaseReference.removeObserver(withHandle: temperatureHandle)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		
		databaseReference = Database.database().reference()
		temperatureHandle = databaseReference.observe(.value) { [unowned self] snapshot in
			let temperatureDict = snapshot.value as? [String: AnyObject] ?? [:]
			self.currentTemperature = (temperatureDict["current_temperature"] as? Double) ?? 0.0
			let history = temperatureDict["temperature_history"] as? [String: AnyObject] ?? [:]
			self.temperatureHistory.removeAll()
			for (key, value) in history {
				let date = Date(timeIntervalSince1970: TimeInterval(key) ?? 0.0)
				let temperature = (value as? [String: AnyObject] ?? [:])["temperature"] as? Double ?? 0.0
				let historicTempterature = HistoricTemperature(date: date, temperature: temperature)
				self.temperatureHistory.append(historicTempterature)
			}
			
			self.temperatureHistory = self.temperatureHistory.sorted { $0.date > $1.date}
			self.update()
		}
	}
	
	func update() {
		print("History: \(temperatureHistory)")
		tableView.reloadData()
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return temperatureHistory.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
		let historicTemperature = temperatureHistory[indexPath.row]
		cell.textLabel?.text = dateFormatter.string(from: historicTemperature.date)
		cell.detailTextLabel?.text = String(format: "%.1f°C", historicTemperature.temperature)
		cell.selectionStyle = .none
		return cell
	}
}

