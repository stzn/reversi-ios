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
    struct ViewState: Equatable {
        let email: String?
        let password: String?
        let isLoginButtonEnabled: Bool
        let isIndicatorHidden: Bool
        let needErrorShow: Bool
    }

    enum ViewAction {
        case emailChanged(String?)
        case passwordChanged(String?)
        case loginButtonTapped(LoginRequest)
        case errorDismissed
    }

    var cancellables: Set<AnyCancellable> = []
    var store: Store<LoginState, LoginAction>!
    var viewStore: ViewStore<ViewState, ViewAction>!

    public static func instantiate(store: Store<LoginState, LoginAction>) -> LoginViewController {
        let viewController =
            UIStoryboard(
                name: "LoginViewController",
                bundle: Bundle(for: LoginViewController.self)
            )
            .instantiateViewController(identifier: "LoginViewController")
            as! LoginViewController
        viewController.store = store
        viewController.viewStore = ViewStore(store.scope(state: { $0.view }, action: LoginAction.view))
        return viewController
    }

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    private lazy var lodingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: view.topAnchor),
            indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            indicator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return indicator
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Login"

        self.viewStore.publisher.isIndicatorHidden
            .sink { [weak self] hidden in
                guard let self = self else {
                    return
                }
                if hidden {
                    self.view.isUserInteractionEnabled = true
                    self.lodingIndicator.stopAnimating()
                } else {
                    self.view.isUserInteractionEnabled = false
                    self.lodingIndicator.startAnimating()
                }
            }
            .store(in: &cancellables)

        self.viewStore.publisher.isLoginButtonEnabled
            .assign(to: \.isEnabled, on: loginButton)
            .store(in: &cancellables)

        self.viewStore.publisher.email
            .assign(to: \.text, on: emailTextField)
            .store(in: &cancellables)

        self.viewStore.publisher.password
            .assign(to: \.text, on: passwordTextField)
            .store(in: &cancellables)

        self.viewStore.publisher.needErrorShow
            .sink { [weak self] needShown in
                if needShown {
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

extension LoginState {
    var view: LoginViewController.ViewState {
        .init(email: self.email,
              password: self.password,
              isLoginButtonEnabled: self.loginButtonEnabled,
              isIndicatorHidden: !self.loginRequesting,
              needErrorShow: self.error != nil)
    }
}

extension LoginAction {
    static func view(_ localAction: LoginViewController.ViewAction) -> Self {
        switch localAction {
        case .emailChanged(let email):
            return .emailChanged(email)
        case .passwordChanged(let password):
            return .passwordChanged(password)
        case .loginButtonTapped(let request):
            return .loginButtonTapped(request)
        case .errorDismissed:
            return .errorDismissed
        }
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

    public func updateUIViewController(
        _ uiViewController: LoginViewController, context: Context
    ) {
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
