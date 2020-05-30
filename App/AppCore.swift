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

public struct AppState: Equatable {
    public var login: LoginState? = nil
    public var game: GameState? = nil

    public init(
        login: LoginState? = nil,
        game: GameState? = nil
    ) {
        self.login = login
        self.game = game
    }
}

public enum AppAction: Equatable {
    case appLaunch
    case loadLoginStateResponse(Bool)
    case loginActionResponse
    case logoutActionResponse
    case login(LoginAction)
    case game(GameAction)
}

public struct AppEnvironment {
    public var loginClient: LoginClient
    public var loginStateHolder: LoginStateHolder
    public var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    public var gameStateManager: GameStateManager
    public var mainQueue: AnySchedulerOf<DispatchQueue>

    public init(
        loginClient: LoginClient,
        loginStateHolder: LoginStateHolder,
        computer: @escaping (Board, Disk) -> Effect<DiskPosition?, Never>,
        gameStateManager: GameStateManager,
        mainQueue: AnySchedulerOf<DispatchQueue>
    ) {
        self.loginClient = loginClient
        self.loginStateHolder = loginStateHolder
        self.computer = computer
        self.gameStateManager = gameStateManager
        self.mainQueue = mainQueue
    }
}

public let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
    Reducer { state, action, environment in
        switch action {
        case .appLaunch:
            return environment.loginStateHolder.load()
                .map(AppAction.loadLoginStateResponse)
        case .loadLoginStateResponse(let loggedIn):
            if loggedIn {
                state.game = GameState()
                state.login = nil
            } else {
                state.game = nil
                state.login = LoginState()
            }
            return .none
        case .loginActionResponse:
            state.game = GameState()
            state.login = nil
            return .none
        case .logoutActionResponse:
            state.game = nil
            state.login = LoginState()
            return environment.gameStateManager
                .saveGame(GameState.intialState)
                .catchToEffect()
                .flatMap { _ in Effect<AppAction, Never>.none }
                .eraseToEffect()
        case .login(.loginResponse(.success(let response))):
            return environment.loginStateHolder.login()
                .map { _ in AppAction.loginActionResponse }
        case .login:
            return .none
        case .game(.logout):
            return environment.loginStateHolder.logout()
                .map { _ in AppAction.logoutActionResponse }
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
