//
//  AppCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/21.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import ComposableArchitectureTestSupport
import XCTest

@testable import Game
@testable import Login
@testable import Reversi

class AppCoreTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testInitialState() {
        let state = AppState()
        XCTAssertEqual(state.login, nil)
        XCTAssertEqual(state.game, nil)
    }

    func testAppLaunchWhenNotLoginThenUserNotLoggedIn() {
        let store = anyTestStore(with: AppState())
        store.assert(
            .send(.appLaunch),
            .receive(.loadLoginStateResponse(false)) {
                $0.login = LoginState()
                $0.game = nil
            }
        )
    }

    func testAppLaunchWhenAlreadyLoggedInThenUserLoggedIn() {
        let store = anyTestStore(with: AppState())
        store.assert(
            .environment {
                $0.loginStateHolder = LoginStateHolder(
                    load: { Effect(value: true) },
                    login: LoginStateHolder.mock.login,
                    logout: LoginStateHolder.mock.logout)
            },
            .send(.appLaunch),
            .receive(.loadLoginStateResponse(true)) {
                $0.login = nil
                $0.game = GameState()
            }

        )
    }

    func testLoginActionResponseThenUserLoggedIn() {
        let store = anyTestStore(with: AppState())
        store.assert(
            .send(.login(.loginResponse(.success(.init())))),
            .receive(.loginActionResponse) {
                $0.login = nil
                $0.game = GameState()
            }
        )
    }

    // MARK: -Helpers

    private func anyTestStore(with state: AppState, function: String = #function) -> TestStore<
        AppState, AppState, AppAction, AppAction, AppEnvironment
    > {
        return TestStore(
            initialState: state,
            reducer: appReducer,
            environment: AppEnvironment(
                loginClient: .mock,
                loginStateHolder: .mock,
                computer: { _, _ in .fireAndForget {} },
                gameStateManager: GameStateManager.mock(id: #function),
                mainQueue: scheduler.eraseToAnyScheduler()))
    }
}
