//
//  Message.swift
//  ChatFirebase
//
//  Created by ulima on 10/25/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit

struct Message {
    let uid: String
    let text: String
    let sender: User
    let timeInterval: Double
    let type: MessageType
    let imageWidth: Double?
    let imageHeight: Double?
}

struct User {
    let uid: String
    let email: String
    let name: String
    let gender: String
    let profileImageRaw: String
}

struct Channel {
    let uid: String
    let user: User
}

enum MessageType: String {
    case text = "text"
    case image = "image"
}
