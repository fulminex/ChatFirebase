//
//  ChatListCollectionViewController.swift
//  ChatFirebase
//
//  Created by Angel Herrera Medina on 10/24/18.
//  Copyright © 2018 Angel Herrera Medina. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatListCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var ref: DatabaseReference!
    var usersRef: DatabaseReference!
    var channelListRef: DatabaseReference!
    var channelListRefHandle: DatabaseHandle!
    
    var displayedChannels: [DisplayedChannel] = []
    
    var spinner: UIView!
    
    private let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        usersRef = ref.child("users")
        channelListRef = usersRef.child(Auth.auth().currentUser!.uid).child("channelList")
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        navigationItem.title = "Chats"
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        
        collectionView?.register(FriendCell.self, forCellWithReuseIdentifier: cellId)
        
        let createChatButtonItem = UIBarButtonItem(image: UIImage(named: "PlusIcon"), style: .plain, target: self, action: #selector(createChat))
        let logoutButtonItem = UIBarButtonItem(image: UIImage(named: "LogoutIcon"), style: .plain, target: self, action: #selector(logout))
        self.navigationItem.rightBarButtonItem = createChatButtonItem
        self.navigationItem.leftBarButtonItem = logoutButtonItem
        
        spinner = UIViewController.displaySpinner(onView: self.view)
        
        observeChannelsChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    @objc func logout() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            return
        }
        channelListRef.removeObserver(withHandle: channelListRefHandle)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createChat() {
        let alert = UIAlertController(title: "Aviso", message: "Ingresa el correo del usuario con quien quieras chatear", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            guard let email = textField?.text, !email.isEmpty, email.contains("@")  else {
                let alert = UIAlertController(title: "Aviso", message: "Ingresa un correo válido", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            guard !self.displayedChannels.contains(where: {$0.user.email == email}) else {
                let alert = UIAlertController(title: "Aviso", message: "Ya tienes un chat creado con ese usuario, escoge uno nuevo", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            self.usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let users = snapshot.value as? [String : AnyObject] else { return }
                var isUserExists = false
                users.forEach({ (key, value) in
                    guard let user = value as? [String : AnyObject] else { return }
                    guard email == user["correo"] as! String else { return }
                    isUserExists = true
                    let newChannelId = UUID().uuidString
                    self.ref.child("channels/\(newChannelId)").setValue("")
                    self.ref.child("users/\(Auth.auth().currentUser!.uid)/channelList/\(newChannelId)").setValue(key)
                    self.ref.child("users/\(key)/channelList/\(newChannelId)").setValue(Auth.auth().currentUser!.uid)
                })
                if !isUserExists {
                    let alert = UIAlertController(title: "Aviso", message: "Usuario no encontrado", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func observeChannelsChanges() {
        channelListRefHandle = channelListRef.observe(.childAdded) { (snapshot) in
            self.fetchChannels()
        }
    }
    
    @objc func fetchChannels() {
        self.usersRef.child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let currentUser = snapshot.value as? [String : AnyObject] else { return }
            guard let channelsList = currentUser["channelList"] as? [String : AnyObject] else { return }
            channelsList.forEach({ (key, value) in
                self.usersRef.child("\(value)").observeSingleEvent(of: .value, with: { (snap) in
                    guard let user = snap.value as? [String : AnyObject] else { return }
                    let displayedChannel = DisplayedChannel(
                        uid: key,
                        user: User(
                            uid: value as! String,
                            email: user["correo"] as! String,
                            name: user["nombre"] as! String,
                            gender: user["genero"] as! String,
                            profileImageRaw: user["profileImageURL"] as! String
                    ))
                    UIViewController.removeSpinner(spinner: self.spinner)
                    guard !self.displayedChannels.contains(where: {$0.uid == displayedChannel.uid}) else { return }
                    self.displayedChannels.append(displayedChannel)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                })
            })
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedChannels.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath as IndexPath) as! FriendCell
        let friend = self.displayedChannels[indexPath.row].user
        cell.nameLabel.text = friend.name
        //TODO: Cambiar el email por el último mensaje
        cell.messageLabel.text = friend.email
        cell.profileImageView.kf.indicatorType = .activity
        cell.profileImageView.kf.setImage(with: URL(string: friend.profileImageRaw))
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ChatVC = ChatController(collectionViewLayout: UICollectionViewFlowLayout())
        let channel = displayedChannels[indexPath.row]
        ChatVC.channelUID = channel.uid
        ChatVC.friendName = channel.user.name
        self.navigationController?.pushViewController(ChatVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
}

class FriendCell: BaseCell {
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Usuario de Prueba"
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Your friend's message and something else..."
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "12:05 pm"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    
    let hasReadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override func setupViews() {
        
        addSubview(profileImageView)
        addSubview(dividerLineView)
        
        setupContainerView()
        
        profileImageView.image = UIImage(named: "UserIcon")
        hasReadImageView.image = UIImage(named: "UserIcon")
        
        addConstraintsWithFormat(format: "H:|-12-[v0(68)]", views: profileImageView)
        addConstraintsWithFormat(format: "V:[v0(68)]", views: profileImageView)
        
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat(format: "H:|-82-[v0]|", views: dividerLineView)
        addConstraintsWithFormat(format: "V:[v0(1)]|", views: dividerLineView)
    }
    
    private func setupContainerView() {
        let containerView = UIView()
        addSubview(containerView)
        
        addConstraintsWithFormat(format: "H:|-90-[v0]|", views: containerView)
        addConstraintsWithFormat(format: "V:[v0(50)]", views: containerView)
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(hasReadImageView)
        
        containerView.addConstraintsWithFormat(format: "H:|[v0][v1(80)]-12-|", views: nameLabel, timeLabel)
        
        containerView.addConstraintsWithFormat(format: "V:|[v0][v1(24)]|", views: nameLabel, messageLabel)
        
        containerView.addConstraintsWithFormat(format: "H:|[v0]-8-[v1(20)]-12-|", views: messageLabel, hasReadImageView)
        
        containerView.addConstraintsWithFormat(format: "V:|[v0(24)]", views: timeLabel)
        
        containerView.addConstraintsWithFormat(format: "V:[v0(20)]|", views: hasReadImageView)
    }
}

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = UIColor.blue
    }
}
