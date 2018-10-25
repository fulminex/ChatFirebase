//
//  CreateUserTableViewController.swift
//  ChatFirebase
//
//  Created by Angel Herrera Medina on 10/24/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit

class CreateUserTableViewController: UITableViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @IBAction func createNewUserButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func changeProfileImage(_ sender: UIButton) {
        
    }
    
}
