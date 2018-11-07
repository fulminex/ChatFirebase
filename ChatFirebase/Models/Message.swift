//
//  Message.swift
//  ChatFirebase
//
//  Created by ulima on 10/25/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit

struct Message {
    let text: String
    let user: User
    let isSender: Bool
}

struct User {
    let name: String
    let profileImage: UIImage
}


//Añadir enum de MessageType aquí
