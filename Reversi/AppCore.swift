//
//  AppCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

struct AppState: Equatable {
    var login: LoginState? = LoginState()
    var game: GameState? = nil
}

enum AppAction: Equatable {
    case login(LoginAction)
    case game(GameAction)
}

struct AppEnvironment {
    var loginClient: LoginClient
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
    Reducer { state, action, environment in
        switch action {
        case .login(.loginResponse(.success(let response))):
            state.game = GameState()
            state.login = nil
            return .none
        case .login:
            return .none
        case .game(.logoutButtonTapped):
            state.game = nil
            state.login = LoginState()
            return environment.gameStateManager
                .saveGame(state: GameState.intialState)
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
