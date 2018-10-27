//
//  LoginTableViewController.swift
//  ChatFirebase
//
//  Created by Angel Herrera Medina on 10/24/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit
import Firebase

class LoginTableViewController: UITableViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Ingresar"
        let cancelBarButtonItem = UIBarButtonItem(image: UIImage(named: "CancelIcon"), style: .plain, target: self, action: #selector(cancelButtonTapped))
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, email.contains("@"), email.split(separator: "@").count == 2 else {
            let alert = UIAlertController(title: "Aviso", message: "Ingresa un correo válido.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        guard let password = passwordTextField.text, password.count > 6 else {
            let alert = UIAlertController(title: "Aviso", message: "Ingresa una contraseña mayor a 6 caracteres.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            guard error == nil else {
                let alert = UIAlertController(title: "Aviso", message: "Correo y/o contraseña incorrectos.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            let firebaseAuth = Auth.auth()
            guard firebaseAuth.currentUser != nil else {
                print("No hay ningun usuario conectado")
                return
            }
            print("usuario logeado exitosamente")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}
