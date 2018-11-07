//
//  CreateUserTableViewController.swift
//  ChatFirebase
//
//  Created by Angel Herrera Medina on 10/24/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit

class CreateUserTableViewController: UITableViewController , UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Crear Nuevo Usuario"
        let cancelBarButtonItem = UIBarButtonItem(image: UIImage(named: "CancelIcon"), style: .plain, target: self, action: #selector(cancelButtonTapped))
        self.navigationController?.navigationBar.tintColor  = #colorLiteral(red: 0.9411764706, green: 0.4352941176, blue: 0.1882352941, alpha: 1)
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func createNewUserButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func changeProfileImage(_ sender: UIButton) {
        
    }
    
}
