import UIKit

class CreateProfileController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate
{
    
    
    @IBOutlet weak var surnameDescription: UILabel!
    @IBOutlet weak var firstnameDescription: UILabel!
    @IBOutlet weak var emailDescription: UILabel!
    @IBOutlet weak var passwodDescription: UILabel!
    @IBOutlet weak var repeatPasswordDescription: UILabel!
    @IBOutlet weak var activityShareDescription: UILabel!
    @IBOutlet weak var agreementTermCondition: UILabel!
    @IBOutlet weak var personalInfoLabel: UILabel!
    @IBOutlet weak var weight: UILabel!
    @IBOutlet weak var wheelSize: UILabel!
    
    
    @IBOutlet private(set) var surnameLabel: UITextField!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet private(set) var emailLabel: UITextField!
    @IBOutlet private(set) var passwordLabel: UITextField!
    @IBOutlet private(set) var confirmPasswordLabel: UITextField!
    @IBOutlet private(set) var shareSwitch: UISwitch!
    @IBOutlet private(set) var weightSlider: UISlider!
 
    
    @IBOutlet private(set) var wheelSizeSlider: UISlider!

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var imagePickerButton: UIButton!
    
    @IBOutlet var TemSwitch: UISwitch!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set text
        self.title = NSLocalizedString("createProfile", comment: "")
        surnameDescription.text = NSLocalizedString("surnameLabel", comment: "")
        firstnameDescription.text = NSLocalizedString("firstnameLabel", comment: "")
        emailDescription.text = NSLocalizedString("emailLabel", comment: "")
        passwodDescription.text = NSLocalizedString("passwordLabel", comment: "")
        repeatPasswordDescription.text = NSLocalizedString("repeatPasswordLabel", comment: "")
        activityShareDescription.text = NSLocalizedString("shareInfoLabel", comment: "")
        agreementTermCondition.text = NSLocalizedString("agreeTermCondition", comment: "")
        personalInfoLabel.text = NSLocalizedString("personalInfoLabel", comment: "")
        weight.text = NSLocalizedString("weightLabel", comment: "")
        wheelSize.text = NSLocalizedString("wheelSizeLabel", comment: "")
        
        surnameLabel.placeholder = NSLocalizedString("surnameLabel", comment: "")
        firstNameLabel.placeholder = NSLocalizedString("firstnameLabel", comment: "")
        emailLabel.placeholder = NSLocalizedString("emailExample", comment: "")
        passwordLabel.placeholder = NSLocalizedString("passwordLabel", comment: "")
        confirmPasswordLabel.placeholder = NSLocalizedString("repeatPasswordLabel", comment: "")
        
        imagePicker.delegate = self
        
        // delegate for hiding keyboard
        surnameLabel.delegate = self
        firstNameLabel.delegate = self
        emailLabel.delegate = self
        passwordLabel.delegate = self
        confirmPasswordLabel.delegate = self
        
        //Hide Keyboard Extension
        self.hideKeyboardWhenTappedAround()
        
        // Change title color and font
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.init(name: "Montserrat-Regular", size: 20)!, NSForegroundColorAttributeName : UIColor.black]
        navBar.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName : UIFont.init(name: "Montserrat-Regular", size: 17)!], for: .normal)
        
        //Set defaults
        currentWeightLabel.text = "\(Int(weightSlider.value)) " + " kg"
        currentWeightLabel.sizeToFit()
        currentWheelSize.text = "\(Int(wheelSizeSlider.value)) " + " Inches"
        currentWheelSize.sizeToFit()
        
        //Set done button disabled
        doneButton.isEnabled = false
        
        //Bind textfields and TemSwitch to validator
        surnameLabel.addTarget(self, action:#selector(CreateProfileController.checkInput), for:UIControlEvents.editingChanged)
        firstNameLabel.addTarget(self, action:#selector(CreateProfileController.checkInput), for:UIControlEvents.editingChanged)
        emailLabel.addTarget(self, action:#selector(CreateProfileController.checkInput), for:UIControlEvents.editingChanged)
        passwordLabel.addTarget(self, action:#selector(CreateProfileController.checkInput), for:UIControlEvents.editingChanged)
        confirmPasswordLabel.addTarget(self, action:#selector(CreateProfileController.checkInput), for:UIControlEvents.editingChanged)
        TemSwitch.addTarget(self, action: #selector(CreateProfileController.checkInput), for: UIControlEvents.valueChanged)
    }

    
    // Slider value changes
    @IBOutlet private(set) var currentWeightLabel: UILabel!
    
    @IBAction func weightSliderValueChanged(_ sender: UISlider) {
        let currentWeight = Int (sender.value)
        currentWeightLabel.text = "\(currentWeight) " + " kg"
        currentWeightLabel.sizeToFit()
    }

    @IBOutlet private(set) var currentWheelSize: UILabel!
    
    @IBAction func wheelSliderValueChanged(_ sender: UISlider) {
        let currentWheel = Int (sender.value)
        currentWheelSize.text = "\(currentWheel) " + " Inches"
        currentWheelSize.sizeToFit()
    }

    @IBAction func doneOnPressed(_ sender: UIBarButtonItem) {
        let user = User()
        
        //Show alert that passwords are not similar
        if(passwordLabel.text != confirmPasswordLabel.text) {
            self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("passwordMismatchDialogTitle", comment: ""), message: NSLocalizedString("passwordMicmatchDialogMsg", comment: "")), animated: true, completion: nil)
            doneButton.isEnabled = false
            return
        }
        
        user.accountPassword = passwordLabel.text
        
        user.accountSurname = surnameLabel.text
        user.accountFirstName = firstNameLabel.text
        user.accountName = emailLabel.text
        user.accountShareInfo = shareSwitch.isOn
        user.accountUserWeight = weightSlider.value
        user.accountUserWheelSize = wheelSizeSlider.value
        if let tmpPhoto = photoImageView.image {
            user.accountProfilePicture = UIImageJPEGRepresentation(tmpPhoto, 1.0)  // get image data
        }
        
        //Save email and password in KeyChain
        KeychainService.saveEmail(token: emailLabel.text! as NSString)
        KeychainService.savePassword(token: passwordLabel.text! as NSString)
        
        let uploadData : [String: Any] = ["email" : KeychainService.loadEmail()!, "password" : KeychainService.loadPassword()!, "firstname" : firstNameLabel.text!, "lastname" : surnameLabel.text!, "allowShare" : shareSwitch.isOn, "wheelsize" : wheelSizeSlider.value, "weight" : weightSlider.value]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: uploadData)
        
        ClientService.postUser(scriptName: "user/createUser.xsjs", userData: jsonData) { (httpCode, error) in
            print(error as Any)
            print(httpCode as Any)
            if error == nil {
                
                let code = httpCode!
                
                switch code {
                case 201: //User created
                    UserDefaults.standard.set(user.accountSurname, forKey: StorageKeys.nameKey)
                    UserDefaults.standard.set(user.accountFirstName, forKey: StorageKeys.firstnameKey)
                    UserDefaults.standard.set(user.accountShareInfo, forKey: StorageKeys.shareKey)
                    UserDefaults.standard.set(user.accountUserWeight, forKey: StorageKeys.weightKey)
                    UserDefaults.standard.set(user.accountUserWheelSize, forKey: StorageKeys.wheelKey)
                    UserDefaults.standard.set(user.accountProfilePicture, forKey: StorageKeys.imageKey)
                    
                    let storyboard = UIStoryboard(name: "Home", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "Home")
                    self.present(controller, animated: true, completion: nil)
                    
                    self.view.endEditing(true)
                    self.close()
                    break
                case 409: //User already exists
                    self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("userExistsDialogTitle", comment: ""), message: NSLocalizedString("userExistsDialogMsg", comment: "")), animated: true, completion: nil)
                    self.doneButton.isEnabled = false
                    break
                default:
                    //For http error codes: 0 or 400
                    self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                    self.doneButton.isEnabled = false
                    return
                }
            }
            else
            {
                //An error occured in the app
                self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                self.doneButton.isEnabled = false
            }
        }
    }

    @IBAction func openTerm(_ sender: Any) {
        if TemSwitch.isOn == true {
        let storyboard = UIStoryboard(name: "StartPage", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Term")
        self.present(controller, animated: true, completion: nil)
        }
        
    }


    @IBAction func imageButtonPressed(_ sender: UIButton) {
        print("image is going to be picked!")
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    //Check if email, password, firstname and lastname are syntacticylly valid and TermSwitch is on
    func checkInput() {
        
        var valid = false
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z.-_]+@[A-Z0-9a-z.-_]+\\.[A-Za-z]{2,3}")
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[A-Z])(?=.*[$@$!%*?&])(?=.*[0-9])(?=.*[a-z]).{10,15}$")
        let nameTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])[a-zA-ZäÄüÜöÖß\\s]{2,20}$")
        
        //Check input fields and TermSwitcher
        if nameTest.evaluate(with: surnameLabel.text) && nameTest.evaluate(with: firstNameLabel.text) &&  emailTest.evaluate(with: emailLabel.text) && passwordTest.evaluate(with: passwordLabel.text) && passwordTest.evaluate(with: confirmPasswordLabel.text) && TemSwitch.isOn {
    
            //Check if passwords are similar
            if passwordLabel.text?.characters.count == confirmPasswordLabel.text?.characters.count {
                valid = true
            }
        }
        
        //If all inputs are valid, enable the done button
        if valid == true {
            doneButton.isEnabled = true
        } else {
           doneButton.isEnabled = false
        }
    }


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            updateProfileBG(pickedImage: pickedImage)
        } else {
            print("Something went wrong")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func updateProfileBG(pickedImage: UIImage) {
        
        // remove old blur first
        for subview in photoImageView.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
        
        photoImageView.image = pickedImage
        
        // Blur Effect of Image Background
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = photoImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.85
        
        photoImageView.addSubview(blurEffectView)
        
        imagePickerButton.backgroundColor = UIColor(red: (228/255.0), green: (228/255.0), blue: (228/255.0), alpha: 0.0)
        
    }
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}
