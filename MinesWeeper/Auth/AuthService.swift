//
//  AuthService.swift
//  MinesWeeper
//
//  Every player, Google or email, is signed in to Firebase Auth; the Firebase uid keys their
//  records, as on Android. Screens depend on the AuthProviding protocol, so tests and previews
//  can pass a fake.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

protocol AuthProviding: AnyObject {
    /// The signed-in player's Firebase uid, or nil when signed out.
    var currentUserId: String? { get }
    var currentUserPhotoURL: URL? { get }
    var currentUserEmail: String? { get }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void)
    func createAccount(email: String, password: String, completion: @escaping (Error?) -> Void)
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void)
    /// Completes with nil on success, and is never called if the player cancels.
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void)
    func signOut()
}

final class FirebaseAuthService: AuthProviding {

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

    private var auth: Auth { Auth.auth() }

    var currentUserId: String? { auth.currentUser?.uid }
    var currentUserPhotoURL: URL? { auth.currentUser?.photoURL }
    var currentUserEmail: String? { auth.currentUser?.email }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in completion(error) }
    }

    func createAccount(email: String, password: String, completion: @escaping (Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { _, error in completion(error) }
    }

    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in completion(error) }
    }

    func signInWithGoogle(presenting viewController: UIViewController,
                          completion: @escaping (Error?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(AuthServiceError.missingClientID)
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [auth] result, error in
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
            auth.signIn(with: credential) { _, error in completion(error) }
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            print("FirebaseAuthService: Firebase sign-out failed: \(error)")
        }
        GIDSignIn.sharedInstance.signOut()
    }
}
