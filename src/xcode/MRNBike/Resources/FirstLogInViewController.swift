//
//  FirstLogInViewController.swift
//  MRNBike
//
//  Created by 1 on 04.05.17.
//  Copyright © 2017 Marc Bormeth. All rights reserved.
//

import UIKit

class FirstLogInViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var userEmailTextField: UITextField!
    @IBOutlet weak var userPasswordTextField: UITextField!
    @IBOutlet weak var messageLabelTextField: UILabel!
    @IBOutlet private var helpView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    // Default user
    let defaultUserName = "Ziad"
    let defaultPassword = "123"
    
    var defaults = UserDefaults.standard
    var passwordWasStored: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userEmailTextField.delegate = self
        self.userPasswordTextField.delegate = self
        
        if defaults.object(forKey: "userName") != nil {
            passwordWasStored = true
        }
        rememberSwitch.isOn = passwordWasStored
        
        if passwordWasStored {
            if let userName = defaults.object(forKey: "userName") as? String {
                userEmailTextField.text = userName
            }
            if let password = defaults.object(forKey: "userPassword") as? String {
                userPasswordTextField.text = password
            }
        }
        
        // Change title color and font
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.init(name: "Montserrat-Regular", size: 20)!, NSForegroundColorAttributeName : UIColor.black]
        
        // Setting default values for Login button incase of Remembering Password is on or off.
        if !rememberSwitch.isOn{
            loginButton.isEnabled = false
            loginButton.alpha = 0.5
        }
        else {
            loginButton.isEnabled = true
            loginButton.alpha = 1.0
        }
        // Setting Fields to trigger any Changes
        userEmailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        userPasswordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    // Login to the app
    @IBAction func onPressedLogin(_ sender: UIButton) {
        let passwordAlert = UIAlertController(title: "Alert", message: "Message", preferredStyle: .alert)
        
        // cachse default user
        if rememberSwitch.isOn {
            if let email = userEmailTextField.text {
                defaults.set(email, forKey: "userName")
            }
            if let password = userPasswordTextField.text {
                defaults.set(password, forKey: "userPassword")
            }
        }
        else  {
            defaults.removeObject(forKey: "userName")
            defaults.removeObject(forKey: "userPassword")
        }
        
        // validate user inputs 
        if (userEmailTextField.text == defaultUserName && userPasswordTextField.text == defaultPassword) {
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "Home")
            self.present(controller, animated: true, completion: nil)
        } else {
            if userPasswordTextField.text != defaultPassword && userEmailTextField.text == defaultUserName {
                passwordAlert.title = "Password wrong"
                passwordAlert.message = "Please fill in your password"
                passwordAlert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: nil))
                self.present(passwordAlert, animated: true, completion: nil)
            } else {
                passwordAlert.title = "User doesn't exist"
                passwordAlert.message = "Please check a correctness of your email!"
                passwordAlert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: nil))
                self.present(passwordAlert, animated: true, completion: nil)
            }
        }
    }
    
    // UITextFieldDelegate For Enablind/Disabling Login Button
    
    func textFieldDidChange(_ textField: UITextField) {
        loginButton.isEnabled = (userEmailTextField.text != "") && (userPasswordTextField.text != "")
        if loginButton.isEnabled {
            loginButton.alpha = 1.0
        } else {
            loginButton.alpha = 0.5
        }
    }
    
    
    // MARK: Actions
    
    //Open a help message
    @IBAction func openHelpMessage(_ sender: UIButton) {
        self.helpView.isHidden = !self.helpView.isHidden
    }
    
    // Close keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}
