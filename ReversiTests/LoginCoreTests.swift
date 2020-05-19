//
//  LoginCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/19.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import ComposableArchitectureTestSupport
import XCTest

@testable import Reversi

class LoginCoreTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testLoginTappedWithEmptyEmailThenLoginButtonIsStillDisabled() {
        let store = anyStore()
        store.assert(
            .send(.emailChanged("")) {
                $0.email = ""
            },
            .send(.passwordChanged("hoge")) {
                $0.password = "hoge"
                $0.loginButtonEnabled = false
            }
        )
    }

    func testLoginTappedWithPasswordEmptyThenLoginButtonIsStillDisabled() {
        let store = anyStore()
        store.assert(
            .send(.emailChanged("hoge")) {
                $0.email = "hoge"
            },
            .send(.passwordChanged("")) {
                $0.password = ""
                $0.loginButtonEnabled = false
            }
        )
    }

    func testLoginTappedWithValidInputThenSuccessLogin() {
        let store = anyStore()
        store.assert(
            .send(.emailChanged("hoge")) {
                $0.email = "hoge"
            },
            .send(.passwordChanged("hoge")) {
                $0.password = "hoge"
                $0.loginButtonEnabled = true
            },
            .send(.loginButtonTapped(.init(email: "hoge", password: "hoge"))) {
                $0.loginButtonEnabled = false
            },
            .do { self.scheduler.run() },
            .receive(.loginResponse(.success(.init()))) {
                $0.loginButtonEnabled = true
            }
        )
    }

    func testLoginTappedWhenReceiveErrorResponseThenFailLogin() {
        let expectedError = LoginError()
        let store = anyStore()
        store.assert(
            .environment {
                $0.loginClient.login = {
                    _ in Effect.result { .failure(expectedError) }
                }
            },
            .send(.emailChanged("hoge")) {
                $0.email = "hoge"
            },
            .send(.passwordChanged("hoge")) {
                $0.password = "hoge"
                $0.loginButtonEnabled = true
            },
            .send(.loginButtonTapped(.init(email: "hoge", password: "hoge"))) {
                $0.loginButtonEnabled = false
            },
            .do { self.scheduler.run() },
            .receive(.loginResponse(.failure(expectedError))) {
                $0.password = nil
                $0.loginButtonEnabled = false
                $0.error = expectedError
            }
        )
    }

    // MARK: -Helpers
    
    private func anyStore(with state: LoginState = .initialState)
        -> TestStore<LoginState, LoginState, LoginAction, LoginAction, LoginEnvironment>
    {
        TestStore(
            initialState: state,
            reducer: loginReducer,
            environment: LoginEnvironment(
                loginClient: .mock,
                mainQueue: scheduler.eraseToAnyScheduler()))
    }
}

extension LoginState {
    static var initialState = LoginState(
        email: nil, password: nil, loginButtonEnabled: false, error: nil)
}
