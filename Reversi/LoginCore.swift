//
//  LoginCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct LoginState: Equatable {
    var email: String? = nil
    var password: String? = nil
    var loginButtonEnabled: Bool = false
    var error: LoginError? = nil
}

enum LoginAction: Equatable {
    case emailChanged(String?)
    case passwordChanged(String?)
    case loginButtonTapped(LoginRequest)
    case loginResponse(Result<LoginResponse, LoginError>)
    case errorDismissed
}

struct LoginEnvironment {
    var loginClient: LoginClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

var loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> {
    state, action, environment in

    func configureLoginButton() {
        guard let email = state.email,
            let password = state.password else {
                return
        }
        state.loginButtonEnabled = !email.isEmpty && !password.isEmpty
    }

    switch action {
    case .emailChanged(let email):
        state.email = email
        configureLoginButton()
        return .none
    case .passwordChanged(let password):
        state.password = password
        configureLoginButton()
        return .none
    case .loginButtonTapped(let request):
        state.loginButtonEnabled = false
        return environment.loginClient.login(request)
            .delay(for: 1.0, scheduler: environment.mainQueue)
            .catchToEffect()
            .receive(on: environment.mainQueue)
            .eraseToEffect()
            .map(LoginAction.loginResponse)
    case .loginResponse(let result):
        switch result {
        case .success(let response):
            state.loginButtonEnabled = true
        case .failure(let error):
            state.password = nil
            state.error = error
        }
        return .none
    case .errorDismissed:
        state.error = nil
        return .none
    }
}
