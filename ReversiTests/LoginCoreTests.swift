//
//  LoginCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/19.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitectureTestSupport
import XCTest

@testable import Reversi

class LoginCoreTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testLoginTappedWithValidInputThenSuccessLogin() {
        let state = LoginState(email: nil, password: nil, loginButtonEnabled: false, error: nil)
        let store = TestStore(
            initialState: state,
            reducer: loginReducer,
            environment: LoginEnvironment(
                loginClient: .mock,
                mainQueue: scheduler.eraseToAnyScheduler()))
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
}
