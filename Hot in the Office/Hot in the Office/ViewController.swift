//
//  ViewController.swift
//  Hot in the Office
//
//  Created by James on 28/07/2017.
//  Copyright © 2017 Rantmedia. All rights reserved.
//

import UIKit
import Firebase

extension UIColor {
	convenience init(hex: Int) {
		let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
		let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
		let blue = CGFloat((hex & 0xFF)) / 255.0
		self.init(red: red, green: green, blue: blue, alpha: 1)
	}
	
	@nonobjc class var red: UIColor {
		return UIColor(hex: 0xFF613D)
	}
	
	@nonobjc class var darkOrange: UIColor {
		return UIColor(hex: 0xFF9449)
	}
	
	@nonobjc class var orange: UIColor {
		return UIColor(hex: 0xFFC864)
	}
	
	@nonobjc class var yellow: UIColor {
		return UIColor(hex: 0xFFE980)
	}
	
	@nonobjc class var cyan: UIColor {
		return UIColor(hex: 0x8CEFFF)
	}
	
	@nonobjc class var teal: UIColor {
		return UIColor(hex: 0x1EBAFF)
	}
	
	@nonobjc class var lightBlue: UIColor {
		return UIColor(hex: 0x147EE5)
	}
	
	@nonobjc class var darkBlue: UIColor {
		return UIColor(hex: 0x0444E3)
	}
}

class ViewController: UIViewController, UIScrollViewDelegate {

	struct HistoricTemperature {
		let date: Date
		let temperature: Double
	}
	
	let dateFormatter = DateFormatter()
	let numberFormatter = NumberFormatter()
	
	@IBOutlet weak var temperatureLabel: UILabel!
	@IBOutlet weak var innerBackgroundView: UIView!
	@IBOutlet weak var middleBackgroundView: UIView!
	@IBOutlet weak var outerBackgroundView: UIView!
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var scrollViewBackground: UIView!
	@IBOutlet weak var historyScrollView: UIScrollView!
	@IBOutlet weak var historyStackView: UIStackView!
	
	var databaseReference: DatabaseReference!
	var temperatureHandle: DatabaseHandle?
	
	var currentTemperature: Double = 0.0
	
	var gradientLayer = CAGradientLayer()
	var scrollViewGradientLayer = CAGradientLayer()
	
	var temperatureHistory = [HistoricTemperature]()
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	deinit {
		if let temperatureHandle = temperatureHandle {
			databaseReference.removeObserver(withHandle: temperatureHandle)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Initialise some of the UI
		gradientLayer.colors = [UIColor.darkBlue.cgColor, UIColor.lightBlue.cgColor]
		gradientLayer.startPoint = CGPoint(x: 1, y: 0)
		gradientLayer.endPoint = CGPoint(x: 0, y: 2.0)
		view.layer.insertSublayer(gradientLayer, at: 0)
		
		scrollViewGradientLayer.colors = [UIColor.white.withAlphaComponent(0.15).cgColor, UIColor.clear.cgColor]
		scrollViewGradientLayer.startPoint = CGPoint(x: 0, y: 0)
		scrollViewGradientLayer.endPoint = CGPoint(x: 0, y: 1)
		scrollViewBackground.layer.insertSublayer(scrollViewGradientLayer, at: 0)
		
		// DateFormatters and NumberFormatters are expensive to create, so create them now and cache for later use
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .short
		
		numberFormatter.numberStyle = .decimal
		numberFormatter.minimumFractionDigits = 0
		numberFormatter.maximumFractionDigits = 1
	
		// get a reference to the database
		databaseReference = Database.database().reference()
		// get an observer handler to watch for value changed events and respond to them with the provided closure
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
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Set up some pretty UI
		gradientLayer.frame = view.layer.bounds
		scrollViewGradientLayer.frame = scrollViewBackground.layer.bounds
		
		historyScrollView.contentInset = UIEdgeInsets(top: 0, left: (historyScrollView.bounds.size.width - 92) / 2, bottom: 0, right: (historyScrollView.bounds.size.width - 92) / 2)
		
		innerBackgroundView.layer.cornerRadius = innerBackgroundView.frame.size.width / 2
		innerBackgroundView.layer.masksToBounds = true
		
		middleBackgroundView.layer.cornerRadius = middleBackgroundView.frame.size.width / 2
		middleBackgroundView.layer.masksToBounds = true
		
		outerBackgroundView.layer.cornerRadius = outerBackgroundView.frame.size.width / 2
		outerBackgroundView.layer.masksToBounds = true
	}
	
	/// Called each time the Firebase database receives a value change event
	func update() {
		temperatureLabel.text = (numberFormatter.string(from: currentTemperature as NSNumber) ?? "") + "°"
		
		switch currentTemperature {
		case ...0.5:
			gradientLayer.colors = [UIColor.darkBlue.cgColor, UIColor.lightBlue.cgColor]
			messageLabel.text = "Is the boiler broken?!"
		case 0.6...10.5:
			gradientLayer.colors = [UIColor.lightBlue.cgColor, UIColor.teal.cgColor]
			messageLabel.text = "It's a bit cooold."
		case 10.6...15.5:
			gradientLayer.colors = [UIColor.teal.cgColor, UIColor.cyan.cgColor]
			messageLabel.text = "It's a bit nippy in here."
		case 15.6...20.5:
			gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.yellow.cgColor]
			messageLabel.text = "Not quite t-shirt weather yet..."
		case 20.6...25.5:
			gradientLayer.colors = [UIColor.yellow.cgColor, UIColor.orange.cgColor]
			messageLabel.text = "Time to wear shorts and get the fans on."
		case 25.6...30.5:
			gradientLayer.colors = [UIColor.orange.cgColor, UIColor.darkOrange.cgColor]
			messageLabel.text = "It's getting hot in here!"
		case 30.6... :
			gradientLayer.colors = [UIColor.darkOrange.cgColor, UIColor.orange.cgColor]
			messageLabel.text = "Too hot. Can't work. Need ice cream."
		default:
			gradientLayer.colors = [UIColor.darkOrange.cgColor, UIColor.orange.cgColor]
		}
		
		historyStackView.arrangedSubviews.forEach { subview in 
			historyStackView.removeArrangedSubview(subview)
			subview.removeFromSuperview()
		}
		
		for historicTemperature in temperatureHistory {
			let view = UIView()
			view.translatesAutoresizingMaskIntoConstraints = false
			view.backgroundColor = .clear
			historyStackView.addArrangedSubview(view)
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(92)]", options: [], metrics: nil, views: ["view": view]))
			
			let temperatureLabel = UILabel()
			temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
			temperatureLabel.text = (numberFormatter.string(from: historicTemperature.temperature as NSNumber) ?? "") + "°"
			temperatureLabel.textColor = .white
			temperatureLabel.font = UIFont.systemFont(ofSize: 20)
			temperatureLabel.textAlignment = .center
			view.addSubview(temperatureLabel)
			NSLayoutConstraint.activate([
				NSLayoutConstraint(item: temperatureLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: temperatureLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: temperatureLabel, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
			])
			
			let timeLabel = UILabel()
			timeLabel.translatesAutoresizingMaskIntoConstraints = false
			timeLabel.text = dateFormatter.string(from: historicTemperature.date)
			timeLabel.textColor = .white
			timeLabel.font = UIFont.systemFont(ofSize: 16)
			timeLabel.textAlignment = .center
			view.addSubview(timeLabel)
			NSLayoutConstraint.activate([
				NSLayoutConstraint(item: timeLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: timeLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: timeLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
			])
		}
	}
	
}

