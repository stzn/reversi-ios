//
//  LoginCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ComposableArchitecture

public struct LoginState: Equatable {
    var email: String? = nil
    var password: String? = nil
    var canRequestLogin: Bool = false
    var loginRequesting: Bool = false
    var error: LoginError? = nil

    public init(email: String? = nil, password: String? = nil,
                loginButtonEnabled: Bool = false, error: LoginError? = nil) {
        self.email = email
        self.password = password
        self.canRequestLogin = loginButtonEnabled
        self.error = error
    }
}

public enum LoginAction: Equatable {
    case emailChanged(String?)
    case passwordChanged(String?)
    case requestLogin(LoginRequest)
    case loginResponse(Result<LoginResponse, LoginError>)
    case errorDismissed
}

public struct LoginEnvironment {
    var loginClient: LoginClient
    var mainQueue: AnySchedulerOf<DispatchQueue>

    public init(loginClient: LoginClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
        self.loginClient = loginClient
        self.mainQueue = mainQueue
    }
}

public var loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> {
    state, action, environment in

    func configureLoginButton() {
        guard let email = state.email,
            let password = state.password else {
                return
        }
        state.canRequestLogin = !email.isEmpty && !password.isEmpty
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
    case .requestLogin(let request):
        state.loginRequesting = true
        state.canRequestLogin = false
        return environment.loginClient.login(request)
            .delay(for: 1.0, scheduler: environment.mainQueue)
            .catchToEffect()
            .receive(on: environment.mainQueue)
            .eraseToEffect()
            .map(LoginAction.loginResponse)
    case .loginResponse(let result):
        switch result {
        case .success(let response):
            state.canRequestLogin = true
        case .failure(let error):
            state.password = nil
            state.error = error
        }
        state.loginRequesting = false
        return .none
    case .errorDismissed:
        state.error = nil
        return .none
    }
}
