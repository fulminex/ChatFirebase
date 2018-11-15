//
//  ChatViewController.swift
//  ChatFirebase
//
//  Created by Angel Herrera Medina on 10/25/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatController: UICollectionViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

    var channelUID: String!
    var friendName: String!
    
    var ref: DatabaseReference!
    var usersRef: DatabaseReference!
    var channelRef: DatabaseReference!
    var channelRefHandle: DatabaseHandle!
    
    private let cellId = "cellId"
    
    var messages: [Message] = []
    
    let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        return textField
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enviar", for: .normal)
        let titleColor = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "CameraIcon"), for: .normal)
        button.addTarget(self, action: #selector(cameraButtonPressed), for: .touchUpInside)
        return button
    }()
    
    @objc  func cameraButtonPressed() {
        let alert = UIAlertController(title: "Aviso", message: "Elige desde donde deseas agregar una foto", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Abrir cámara", style: .default, handler: { (action) in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Abrir librería de fotos", style: .default, handler: { (action) in
            self.openPhotoLibrary()
        }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @objc func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .camera
            myPickerController.allowsEditing = false
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func handleSend() {
        guard !(inputTextField.text?.isEmpty ?? false) else { return }
        self.channelRef.childByAutoId().setValue(
            [
                "text"          : inputTextField.text!,
                "senderUID"     : Auth.auth().currentUser!.uid,
                "timeInterval"  : Date().timeIntervalSince1970,
                "type"          : "text"
            ]
        )
        inputTextField.text = nil
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let newImage = image.resizeImageWith(newSize: CGSize(width: 250, height: 250))
        let data = newImage.jpegData(compressionQuality: 0.9)!
        
        let messageImagePath = "channels/\(self.channelUID!)/\(UUID().uuidString).jpg"
        
        let messageImage = Storage.storage().reference().child(messageImagePath)
        _ = messageImage.putData(data, metadata: nil) { (metadata, error) in
            guard error == nil else {
                print("Error uploading image")
                return
            }
            messageImage.downloadURL { url, error in
                if error != nil {
                    print("Error downloading image url")
                } else {
                    print(url!)
                    self.channelRef.childByAutoId().setValue(
                        [
                            "text"          : url?.absoluteString,
                            "senderUID"     : Auth.auth().currentUser!.uid,
                            "timeInterval"  : Date().timeIntervalSince1970,
                            "type"          : "image"
                        ]
                    )
                }
            }
        }
        dismiss(animated:true, completion: nil)
    }
    
    var bottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        self.title = self.friendName
        
        self.navigationController?.navigationBar.tintColor = UIColor(red: 225/255, green: 118/255, blue: 57/255, alpha: 1)
        
        tabBarController?.tabBar.isHidden = true
        
        collectionView?.backgroundColor = UIColor.white
        
        collectionView?.register(ChatLogMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(messageInputContainerView)
        view.addConstraintsWithFormat(format: "H:|[v0]|", views: messageInputContainerView)
        view.addConstraintsWithFormat(format: "V:[v0(48)]", views: messageInputContainerView)
        
        bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        setupInputComponents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        ref = Database.database().reference()
        usersRef = ref.child("users")
        channelRef = ref.child("channels").child(channelUID)
        
        observeMessages()
    }
    
    func observeMessages() {
        channelRefHandle = channelRef.observe(.childAdded) { (snapshot) in
            let messageUID = snapshot.key
            guard let message = snapshot.value as? [String : AnyObject] else { return }
            self.usersRef.child(message["senderUID"] as! String).observeSingleEvent(of: .value, with: { (snap) in
                guard let user = snap.value as? [String : AnyObject] else { return }
                
                var imageWidth: Double?
                var imageHeight: Double?
                
                let url = URL(string: message["text"] as! String)
                let type = MessageType(rawValue: message["type"] as! String)!
                
                switch type {
                case .image:
                    if let imageSource = CGImageSourceCreateWithURL(url! as CFURL, nil) {
                        if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                            let pixelImageWidth = imageProperties[kCGImagePropertyPixelWidth] as? Double
                            let pixelImageHeight = imageProperties[kCGImagePropertyPixelHeight] as? Double
                            imageWidth = pixelImageWidth! / 3.0
                            imageHeight = pixelImageHeight! / 3.0
                        }
                    }
                case .text:
                    imageWidth = nil
                    imageHeight = nil
                }
                
                let message = Message(
                    uid: messageUID,
                    text: message["text"] as! String,
                    sender: User(
                        uid: message["senderUID"] as! String,
                        email: user["correo"] as! String,
                        name: user["nombre"] as! String,
                        gender: user["genero"] as! String,
                        profileImageRaw: user["profileImageURL"] as! String
                    ),
                    timeInterval: message["timeInterval"] as! Double,
                    type: type,
                    imageWidth: imageWidth,
                    imageHeight: imageHeight
                )
                self.messages.append(message)
                self.messages = self.messages.sorted(by: { (m1, m2) -> Bool in
                    let date1 = Date(timeIntervalSince1970: m1.timeInterval)
                    let date2 = Date(timeIntervalSince1970: m2.timeInterval)
                    return date1.compare(date2) == .orderedAscending
                })
                if let item = self.messages.firstIndex(where: { $0.uid == message.uid }) {
                    let receivingIndexPath = IndexPath(item: item, section: 0)
                    self.collectionView?.insertItems(at: [receivingIndexPath])
                    self.collectionView.scrollToItem(at: IndexPath(item: self.messages.count - 1, section: 0), at: .bottom, animated: true)
                }
            })
        }
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
            print(keyboardFrame ?? "No se pudo obtener le Rect del Keyboard")
            
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            
            bottomConstraint?.constant = isKeyboardShowing ? -keyboardFrame!.height : 0
            
            UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                
                self.view.layoutIfNeeded()
                
            }, completion: { (completed) in
                
                if isKeyboardShowing {
                    print(self.messages.count - 1)
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                
            })
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        inputTextField.endEditing(true)
    }
    
    private func setupInputComponents() {
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        messageInputContainerView.addSubview(inputTextField)
        messageInputContainerView.addSubview(sendButton)
        messageInputContainerView.addSubview(topBorderView)
        messageInputContainerView.addSubview(cameraButton)

        messageInputContainerView.addConstraintsWithFormat(format: "H:|[v0(60)]-8-[v1][v2(60)]|", views: cameraButton, inputTextField, sendButton)
        
        messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]|", views: cameraButton)
        messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]|", views: inputTextField)
        messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0]|", views: sendButton)
        
        messageInputContainerView.addConstraintsWithFormat(format: "H:|[v0]|", views: topBorderView)
        messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0(0.5)]", views: topBorderView)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //Añadir la imagen a la celda
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatLogMessageCell
        
        let message = messages[indexPath.item]
        
        cell.profileImageView.kf.indicatorType = .activity
        cell.profileImageView.kf.setImage(with: URL(string: message.sender.profileImageRaw))
        cell.backgroundColor = .white
        
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: message.text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
        
        switch message.type {
        case .text:
            if message.sender.uid != Auth.auth().currentUser!.uid {
                cell.messageTextView.text = message.text
                cell.messageTextView.frame = CGRect(x: 48 + 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
                
                cell.textBubbleView.frame = CGRect(x: 48 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 16, height: estimatedFrame.height + 20 + 6)
                
                cell.profileImageView.isHidden = false
                
                cell.bubbleImageView.image = ChatLogMessageCell.grayBubbleImage
                cell.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
                cell.messageTextView.textColor = UIColor.black
            } else {
                cell.messageTextView.text = message.text
                cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 16 - 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
                
                cell.textBubbleView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 16 - 8 - 16 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 10, height: estimatedFrame.height + 20 + 6)
                
                cell.profileImageView.isHidden = true
                
                cell.bubbleImageView.image = ChatLogMessageCell.blueBubbleImage
                cell.bubbleImageView.tintColor = UIColor(red: 225/255, green: 118/255, blue: 57/255, alpha: 1)
                cell.messageTextView.textColor = UIColor.white
            }
        case .image:
            if message.sender.uid != Auth.auth().currentUser!.uid {
                cell.messageTextView.text = ""
                cell.textBubbleView.frame = CGRect(x: 48, y: -4, width: message.imageWidth!, height: message.imageHeight!)
                
                cell.profileImageView.isHidden = false
                cell.bubbleImageView.kf.indicatorType = .activity
                cell.bubbleImageView.kf.setImage(with: URL(string: message.text))
            } else {
                cell.messageTextView.text = ""
                cell.profileImageView.isHidden = true
                cell.bubbleImageView.kf.indicatorType = .activity
                cell.bubbleImageView.kf.setImage(with: URL(string: message.text))
                
                cell.textBubbleView.frame = CGRect(x: Double(self.view.frame.width) - message.imageWidth! - 20, y: -4, width: message.imageWidth!, height: message.imageHeight!)
            }
        }
        return cell
    }
    
    //Ajustar el tamaño de la celda para las imágenes 
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = messages[indexPath.item]
        let messageText = message.text
        
        switch message.type {
        case .text:
            let size = CGSize(width: 250, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
            
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 20)
        case .image:
            let screenWidth = Double(view.frame.width)
            let height = message.imageHeight ?? 200
            return CGSize(width: screenWidth, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
    
}

class ChatLogMessageCell: BaseCell {
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.text = "Sample message"
        textView.backgroundColor = UIColor.clear
        textView.isEditable = false
        return textView
    }()
    
    let textBubbleView: UIView = {
        let view = UIView()
//        view.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    static let grayBubbleImage = UIImage(named: "bubble_gray")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    static let blueBubbleImage = UIImage(named: "bubble_blue")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    
    let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ChatLogMessageCell.grayBubbleImage
        imageView.tintColor = UIColor(white: 0.90, alpha: 1)
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(textBubbleView)
        addSubview(messageTextView)
        
        addSubview(profileImageView)
        addConstraintsWithFormat(format: "H:|-8-[v0(30)]", views: profileImageView)
        addConstraintsWithFormat(format: "V:[v0(30)]|", views: profileImageView)
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addConstraintsWithFormat(format: "H:|[v0]|", views: bubbleImageView)
        textBubbleView.addConstraintsWithFormat(format: "V:|[v0]|", views: bubbleImageView)
    }
    
}
