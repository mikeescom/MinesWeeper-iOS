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

/// How the signed-in player signed in. Account deletion asks them to confirm the same way.
enum SignInMethod {
    case apple, google, email
}

protocol AuthProviding: AnyObject {
    /// The signed-in player's Firebase uid, or nil when signed out.
    var currentUserId: String? { get }
    var currentUserPhotoURL: URL? { get }
    var currentUserEmail: String? { get }
    var currentSignInMethod: SignInMethod? { get }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void)
    func createAccount(email: String, password: String, completion: @escaping (Error?) -> Void)
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void)
    /// Completes with nil on success, and is never called if the player cancels.
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void)
    /// Completes with nil on success, and is never called if the player cancels.
    func signInWithApple(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void)
    func signOut()

    /// Confirms the signed-in player's identity again, which Firebase requires before deleting
    /// an account. [password] is used for email accounts. Fails with CancellationError if they
    /// cancel a sign-in sheet.
    func reauthenticate(presenting viewController: UIViewController, password: String?,
                        completion: @escaping (Error?) -> Void)
    /// Deletes the Firebase account (and revokes Sign in with Apple, as Apple requires).
    /// Call after reauthenticate.
    func deleteCurrentUser(completion: @escaping (Error?) -> Void)
}

final class FirebaseAuthService: AuthProviding {

    enum AuthServiceError: LocalizedError {
        case missingClientID
        case missingIDToken
        case notSignedIn
        case missingPassword

        var errorDescription: String? {
            switch self {
            case .missingClientID: return "Google sign-in is not configured."
            case .missingIDToken: return "Google did not return an ID token."
            case .notSignedIn: return "No one is signed in."
            case .missingPassword: return "Enter your password to confirm."
            }
        }
    }

    private var auth: Auth { Auth.auth() }

    var currentUserId: String? { auth.currentUser?.uid }
    var currentUserPhotoURL: URL? { auth.currentUser?.photoURL }
    var currentUserEmail: String? { auth.currentUser?.email }

    var currentSignInMethod: SignInMethod? {
        let providers = auth.currentUser?.providerData.map(\.providerID) ?? []
        if providers.contains("apple.com") { return .apple }
        if providers.contains("google.com") { return .google }
        if providers.contains("password") { return .email }
        return nil
    }

    /// The Apple authorization code from the latest reauthentication, used to revoke the
    /// Sign in with Apple token when the account is deleted.
    private var appleAuthorizationCode: String?

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
        googleCredential(presenting: viewController) { [auth] result in
            switch result {
            case .success(let credential):
                auth.signIn(with: credential) { _, error in completion(error) }
            case .failure(is CancellationError):
                return
            case .failure(let error):
                completion(error)
            }
        }
    }

    func signInWithApple(presenting viewController: UIViewController,
                         completion: @escaping (Error?) -> Void) {
        AppleSignInFlow.start(presenting: viewController) { [auth] result in
            switch result {
            case .success(let outcome):
                auth.signIn(with: outcome.credential) { _, error in completion(error) }
            case .failure(let error as AppleSignInFlow.FlowError) where error == .cancelled:
                return
            case .failure(let error):
                completion(error)
            }
        }
    }

    /// Shows Google's sign-in flow and returns a Firebase credential for the chosen account.
    /// Fails with CancellationError if the player cancels.
    private func googleCredential(presenting viewController: UIViewController,
                                  completion: @escaping (Result<AuthCredential, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(AuthServiceError.missingClientID))
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error {
                if let signInError = error as? GIDSignInError, signInError.code == .canceled {
                    completion(.failure(CancellationError()))
                } else {
                    completion(.failure(error))
                }
                return
            }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                completion(.failure(AuthServiceError.missingIDToken))
                return
            }
            completion(.success(GoogleAuthProvider.credential(withIDToken: idToken,
                                                              accessToken: user.accessToken.tokenString)))
        }
    }

    func reauthenticate(presenting viewController: UIViewController, password: String?,
                        completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            completion(AuthServiceError.notSignedIn)
            return
        }
        let reauthenticate: (AuthCredential) -> Void = { credential in
            user.reauthenticate(with: credential) { _, error in completion(error) }
        }
        switch currentSignInMethod {
        case .apple:
            AppleSignInFlow.start(presenting: viewController) { [weak self] result in
                switch result {
                case .success(let outcome):
                    self?.appleAuthorizationCode = outcome.authorizationCode
                    reauthenticate(outcome.credential)
                case .failure(let error as AppleSignInFlow.FlowError) where error == .cancelled:
                    completion(CancellationError())
                case .failure(let error):
                    completion(error)
                }
            }
        case .google:
            googleCredential(presenting: viewController) { result in
                switch result {
                case .success(let credential): reauthenticate(credential)
                case .failure(let error): completion(error)
                }
            }
        case .email, .none:
            guard let email = user.email, let password, !password.isEmpty else {
                completion(AuthServiceError.missingPassword)
                return
            }
            reauthenticate(EmailAuthProvider.credential(withEmail: email, password: password))
        }
    }

    func deleteCurrentUser(completion: @escaping (Error?) -> Void) {
        guard let user = auth.currentUser else {
            completion(AuthServiceError.notSignedIn)
            return
        }
        let deleteUser = { [weak self] in
            user.delete { error in
                if error == nil {
                    self?.appleAuthorizationCode = nil
                    GIDSignIn.sharedInstance.signOut()
                }
                completion(error)
            }
        }
        // Apple requires apps to revoke Sign in with Apple tokens when an account is deleted.
        if currentSignInMethod == .apple, let code = appleAuthorizationCode {
            auth.revokeToken(withAuthorizationCode: code) { error in
                if let error { print("FirebaseAuthService: revoking Apple token failed: \(error)") }
                deleteUser()
            }
        } else {
            deleteUser()
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
