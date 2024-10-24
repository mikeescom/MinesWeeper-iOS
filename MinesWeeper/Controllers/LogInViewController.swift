//
//  ViewController.swift
//  MinesWeeper
//
//  Created by Saavedra Lozano, Miguel on 10/8/24.
//

import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

class LogInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let borderColor = CGColor(red: CGFloat(0), green: CGFloat(0.12156862745098039), blue: CGFloat(0.24705882352941178), alpha: CGFloat(1))
        let endColor = UIColor(red: CGFloat(0), green: CGFloat(0.12156862745098039), blue: CGFloat(0.24705882352941178), alpha: CGFloat(1))
        let startColor = UIColor(red: CGFloat(0.22745098039215686), green: CGFloat(0.42745098039215684), blue: CGFloat(0.5490196078431373), alpha: CGFloat(1))
        let backgroundLogInColors = [startColor, endColor]
        
        emailTextField.placeholder = "email"
        emailTextField.layer.cornerRadius = 15
        emailTextField.clipsToBounds = true
        emailTextField.layer.borderWidth = 2.0
        emailTextField.layer.borderColor = borderColor
        passwordTextField.placeholder = "password"
        passwordTextField.layer.cornerRadius = 15
        passwordTextField.clipsToBounds = true
        passwordTextField.layer.borderWidth = 2.0
        passwordTextField.layer.borderColor = borderColor
        logInButton.applyGradient(colours: backgroundLogInColors, locations: [0.0, 0.5, 1.0])
    }

    @IBAction func logInPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToCreateAccount", sender: self)
    }
    
    @IBAction func googleSignInPressed(_ sender: GIDSignInButton) {
        //googleSignIn()
        self.performSegue(withIdentifier: "goToBoard", sender: self)
    }
    
    func googleSignIn() {
        print("googleSignIn")
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            if let user = result?.user,let idToken = user.idToken?.tokenString {
                if error != nil {
                    print("Error: \(String(describing: error))")
                    return
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

                Auth.auth().signIn(with: credential) { result, error in
                    if error != nil {
                        print("Error: \(String(describing: error))")
                        return
                    } else {
                        self.performSegue(withIdentifier: "goToBoard", sender: self)
                    }
                }
            }
        }
    }
    
}

extension UIView {

    func applyGradient(colours: [UIColor], locations: [NSNumber]?) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
}
