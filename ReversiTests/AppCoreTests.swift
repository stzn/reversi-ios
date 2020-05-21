//
//  AppCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/21.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import ComposableArchitectureTestSupport
import Game
import Login
import XCTest

@testable import Reversi

class AppCoreTests: XCTestCase {
  let scheduler = DispatchQueue.testScheduler

  func testInitialState() {
    let state = AppState()
    XCTAssertEqual(state.login, nil)
    XCTAssertEqual(state.game, nil)
  }

  func testAppLaunchWhenNotLoggedInThenShowLoginScreen() {
    let store = anyTestStore(with: AppState())
    store.assert(
      .send(.appLaunch),
      .receive(.loadLoggedInResponse(false)) {
        $0.login = LoginState()
        $0.game = nil
      }
    )
  }

  func testAppLaunchWhenLoggedInThenShowGameScreen() {
    let store = anyTestStore(with: AppState())
    store.assert(
      .environment {
        $0.loginStateHolder = LoginStateHolder(
          load: { Effect(value: true) },
          loggedIn: LoginStateHolder.mock.loggedIn,
          loggedOut: LoginStateHolder.mock.loggedOut)
      },
      .send(.appLaunch),
      .receive(.loadLoggedInResponse(true)) {
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
