//
//  AuthService.swift
//  MinesWeeper
//
//  Every player, Google or email, is signed in to Firebase Auth; the Firebase uid keys their
//  records, as on Android.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum AuthService {

    enum AuthServiceError: LocalizedError {
        case missingClientID
        case missingIDToken

        var errorDescription: String? {
            switch self {
            case .missingClientID: return "Google sign-in is not configured."
            case .missingIDToken: return "Google did not return an ID token."
            }
        }
    }

    static var currentUser: User? { Auth.auth().currentUser }

    static func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in completion(error) }
    }

    static func createAccount(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in completion(error) }
    }

    static func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in completion(error) }
    }

    /// Shows Google's sign-in flow and signs the chosen account in to Firebase.
    /// Completes with nil on success, and with no call at all if the player cancels.
    static func signInWithGoogle(presenting viewController: UIViewController,
                                 completion: @escaping (Error?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(AuthServiceError.missingClientID)
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error {
                if let signInError = error as? GIDSignInError, signInError.code == .canceled {
                    return
                }
                completion(error)
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                completion(AuthServiceError.missingIDToken)
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { _, error in completion(error) }
        }
    }

    /// Signs out of Firebase and Google and forgets this player's preferences and local records.
    static func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("AuthService: Firebase sign-out failed: \(error)")
        }
        GIDSignIn.sharedInstance.signOut()
        Settings.clear()
        RecordsRepository.shared.clearLocalRecords()
    }
}
