//
//  AppCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation
import Game
import Login

struct AppState: Equatable {
    var login: LoginState? = nil
    var game: GameState? = nil
}

enum AppAction: Equatable {
    case appLaunch
    case loadLoggedInResponse(Bool)
    case login(LoginAction)
    case loggedInResponse
    case loggedOutResponse
    case game(GameAction)
}

struct AppEnvironment {
    var loginClient: LoginClient
    var loginStateHolder: LoginStateHolder
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
    Reducer { state, action, environment in
        switch action {
        case .appLaunch:
            return environment.loginStateHolder.load()
                .map(AppAction.loadLoggedInResponse)
        case .loadLoggedInResponse(let loggedIn):
            if loggedIn {
                state.game = GameState()
                state.login = nil
            } else {
                state.game = nil
                state.login = LoginState()
            }
            return .none
        case .login(.loginResponse(.success(let response))):
            return environment.loginStateHolder.loggedIn()
                .map { _ in AppAction.loggedInResponse }
        case .login:
            return .none
        case .game(.logoutButtonTapped):
            return environment.loginStateHolder.loggedOut()
                .map { _ in AppAction.loggedOutResponse }
        case .game:
            return .none
        case .loggedInResponse:
            state.game = GameState()
            state.login = nil
            return .none
        case .loggedOutResponse:
            state.game = nil
            state.login = LoginState()
            return environment.gameStateManager
                .saveGame(GameState.intialState)
                .catchToEffect()
                .flatMap { _ in Effect<AppAction, Never>.none }
                .eraseToEffect()
        }
    },
    loginReducer.optional.pullback(
        state: \.login,
        action: /AppAction.login,
        environment: {
            LoginEnvironment(
                loginClient: $0.loginClient,
                mainQueue: $0.mainQueue
            )
        }),
    gameReducer.optional.pullback(
        state: \.game,
        action: /AppAction.game,
        environment: {
            GameEnvironment(
                computer: $0.computer,
                gameStateManager: $0.gameStateManager,
                mainQueue: $0.mainQueue)
        })
)
