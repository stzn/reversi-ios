//
//  AppCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation
import Login
import Game

struct AppState: Equatable {
    var login: LoginState? = nil
    var game: GameState? = nil
}

enum AppAction: Equatable {
    case appLaunch
    case login(LoginAction)
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
            if environment.loginStateHolder.load() {
                state.game = GameState()
                state.login = nil
            } else {
                state.game = nil
                state.login = LoginState()
            }
            return .none
        case .login(.loginResponse(.success(let response))):
            environment.loginStateHolder.save()
            state.game = GameState()
            state.login = nil
            return .none
        case .login:
            return .none
        case .game(.logoutButtonTapped):
            environment.loginStateHolder.remove()
            state.game = nil
            state.login = LoginState()
            return environment.gameStateManager
                .saveGame(GameState.intialState)
                .catchToEffect()
                .flatMap { _ in Effect<AppAction, Never>.none }
                .eraseToEffect()
        case .game:
            return .none
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
