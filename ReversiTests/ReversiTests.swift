//
//  ReversiTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/23.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import XCTest

@testable import App
@testable import Game
@testable import Login

class ReversiTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testLoginAndLogout() {
        let state = AppState()
        let store = TestStore(
            initialState: state, reducer: appReducer,
            environment: AppEnvironment(
                loginClient: .mock, loginStateHolder: .mock,
                computer: { _, _ in .fireAndForget {} },
                gameStateManager: .mock(id: UUID().uuidString),
                mainQueue: scheduler.eraseToAnyScheduler()))
        store.assert([
            .send(.appLaunch),
            .receive(.loadLoginStateResponse(false)) {
                $0.login = LoginState()
            },
            .send(.login(LoginAction.emailChanged("hoge"))) {
                $0.login?.email = "hoge"
            },
            .send(.login(LoginAction.passwordChanged("hoge"))) {
                $0.login?.password = "hoge"
                $0.login?.loginButtonEnabled = true
            },
            .send(.login(LoginAction.loginButtonTapped(.init(email: "hoge", password: "hoge")))) {
                $0.login?.loginButtonEnabled = false
                $0.login?.loginRequesting = true
            },
            .do { self.scheduler.run() },
            .receive(.login(.loginResponse(.success(.init())))) {
                $0.login?.loginButtonEnabled = true
                $0.login?.loginRequesting = false
            },
            .receive(.loginActionResponse) {
                $0.login = nil
                $0.game = GameState()
            },
            .send(.game(.logoutButtonTapped)),
            .receive(.logoutActionResponse) {
                $0.login = LoginState()
                $0.game = nil
            },
            .receive(.game(.saveGameResponse(.success(.saved)))),
        ])
    }
}
