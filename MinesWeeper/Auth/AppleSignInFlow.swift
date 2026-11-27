//
//  AppleSignInFlow.swift
//  MinesWeeper
//
//  Runs Apple's sign-in sheet once and turns the result into a Firebase credential. A random
//  nonce ties the Apple ID token to this request, as Firebase requires.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import UIKit

final class AppleSignInFlow: NSObject {

    struct Outcome {
        let credential: AuthCredential
        /// Needed to revoke the Apple token when the account is deleted.
        let authorizationCode: String?
    }

    enum FlowError: LocalizedError {
        case cancelled
        case missingIdentityToken

        var errorDescription: String? {
            switch self {
            case .cancelled: return "Sign in with Apple was cancelled."
            case .missingIdentityToken: return "Apple did not return an identity token."
            }
        }
    }

    private let anchor: ASPresentationAnchor
    private let completion: (Result<Outcome, Error>) -> Void
    private let rawNonce = AppleSignInFlow.randomNonce()
    /// Keeps the flow alive while Apple's sheet is showing; cleared when it finishes.
    private var retainedSelf: AppleSignInFlow?

    private init(anchor: ASPresentationAnchor, completion: @escaping (Result<Outcome, Error>) -> Void) {
        self.anchor = anchor
        self.completion = completion
    }

    /// Shows Apple's sign-in sheet over [viewController]'s window.
    static func start(presenting viewController: UIViewController,
                      completion: @escaping (Result<Outcome, Error>) -> Void) {
        let anchor = viewController.view.window ?? ASPresentationAnchor()
        let flow = AppleSignInFlow(anchor: anchor, completion: completion)
        flow.retainedSelf = flow

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(flow.rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = flow
        controller.presentationContextProvider = flow
        controller.performRequests()
    }

    private func finish(_ result: Result<Outcome, Error>) {
        completion(result)
        retainedSelf = nil
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "Unable to generate a nonce: \(status)")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInFlow: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(FlowError.missingIdentityToken))
            return
        }
        let credential = OAuthProvider.appleCredential(withIDToken: idToken,
                                                       rawNonce: rawNonce,
                                                       fullName: appleCredential.fullName)
        let code = appleCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        finish(.success(Outcome(credential: credential, authorizationCode: code)))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            finish(.failure(FlowError.cancelled))
        } else {
            finish(.failure(error))
        }
    }
}

extension AppleSignInFlow: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        anchor
    }
}
