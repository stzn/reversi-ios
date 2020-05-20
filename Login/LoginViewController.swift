//
//  LoginViewController.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine
import ComposableArchitecture
import UIKit

public final class LoginViewController: UIViewController {
    var cancellables: Set<AnyCancellable> = []
    var store: Store<LoginState, LoginAction>!
    var viewStore: ViewStore<LoginState, LoginAction>!

    public static func instantiate(store: Store<LoginState, LoginAction>) -> LoginViewController {
        let viewController =
            UIStoryboard(name: "LoginViewController", bundle: nil)
            .instantiateViewController(identifier: "LoginViewController")
            as! LoginViewController
        viewController.store = store
        viewController.viewStore = ViewStore(store)
        return viewController
    }

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Login"

        self.viewStore.publisher.loginButtonEnabled
            .assign(to: \.isEnabled, on: loginButton)
            .store(in: &cancellables)

        self.viewStore.publisher.email
            .assign(to: \.text, on: emailTextField)
            .store(in: &cancellables)

        self.viewStore.publisher.password
            .assign(to: \.text, on: passwordTextField)
            .store(in: &cancellables)

        self.viewStore.publisher.error
            .sink { [weak self] error in
                if let error = error {
                    // TODO: error handling
                    print(error)
                    let alert = UIAlertController(
                        title: "Error!", message: "Login Failed", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self?.viewStore.send(.errorDismissed)
                    }
                    alert.addAction(okAction)
                    self?.present(alert, animated: true)
                }
            }.store(in: &cancellables)
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty
        else {
            assertionFailure("must input both texts")
            return
        }
        self.viewStore.send(.loginButtonTapped(.init(email: email, password: password)))
    }

    @IBAction func emailValueChanged(_ sender: UITextField) {
        self.viewStore.send(.emailChanged(sender.text))
    }

    @IBAction func passwordValueChanged(_ sender: UITextField) {
        self.viewStore.send(.passwordChanged(sender.text))
    }
}

#if DEBUG
import SwiftUI

extension LoginViewController: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> LoginViewController {
        let store = Store<LoginState, LoginAction>(
            initialState: .init(),
            reducer: loginReducer,
            environment: LoginEnvironment(
                loginClient: .mock,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()))
        return LoginViewController.instantiate(store: store)
    }

    public func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
    }
}

struct LoginView: PreviewProvider {
    private static let devices = [
        "iPhone SE",
        "iPhone 11",
        "iPad Pro (11-inch) (2nd generation)",
    ]

    static var previews: some View {
        ForEach(devices, id: \.self) { name in
            Group {
                self.content
                    .previewDevice(PreviewDevice(rawValue: name))
                    .previewDisplayName(name)
                    .colorScheme(.light)
                self.content
                    .previewDevice(PreviewDevice(rawValue: name))
                    .previewDisplayName(name)
                    .colorScheme(.dark)
            }
        }
    }

    private static var content: LoginViewController {
        let store = Store<LoginState, LoginAction>(
            initialState: .init(),
            reducer: loginReducer,
            environment: LoginEnvironment(
                loginClient: .mock,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()))
        return LoginViewController.instantiate(store: store)
    }
}
#endif
