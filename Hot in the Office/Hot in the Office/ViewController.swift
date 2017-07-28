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

	var dbRef: DatabaseReference!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		dbRef = Database.database().reference()
	}

}

