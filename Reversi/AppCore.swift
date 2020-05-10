//
//  AppCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

struct AppState: Equatable {
    var board: Board
    var players: [Player]
    var turn: Disk?
    var shouldSkip: Bool
    var currentTapPosition: DiskPosition?
    var playerChanged: Bool = false

    static var intialState: AppState {
        .init(
            board: Board.reset(),
            players: [.manual, .manual], turn: .dark,
            shouldSkip: false, currentTapPosition: nil)
    }
}

enum AppAction: Equatable {
    case gameStarted
    case manualPlayerDiskPlaced(DiskPosition)
    case resetTapped
    case playerChanged(Disk, Player)
    case loadGameResponse(Result<GameStateLoadAction, GameStateManagerError>)
    case saveGame
    case saveGameResponse(Result<GameStateSaveAction, GameStateManagerError>)
    case computerPlay
    case computerPlayResponse(DiskPosition?)
    case turnSkipped
    case placeDisk(DiskPosition)
    case updateState(AppState)
}

struct AppEnvironment {
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> {
    state, action, environment in

    var isGameEnd: Bool {
        guard let turn = state.turn else {
            return true
        }
        return Rule.validMoves(for: turn.flipped, on: state.board).isEmpty
            && Rule.validMoves(for: turn, on: state.board).isEmpty
    }

    func stateAfterDiskPlaced(state: AppState, position: DiskPosition) -> Effect<AppState, Never> {
        var newState = state
        guard var turn = newState.turn else {
            return .none
        }

        let diskCoordinates = Rule.flippedDiskCoordinatesByPlacingDisk(
            turn, atX: position.x, y: position.y, on: newState.board.disks)

        if diskCoordinates.isEmpty {
            return .none
        }

        newState.currentTapPosition = .init(x: position.x, y: position.y)
        newState.board.setDisk(turn, atX: position.x, y: position.y)

        for (x, y) in diskCoordinates {
            newState.board.setDisk(turn, atX: x, y: y)
        }

        turn.flip()
        newState.turn = turn
        return Effect(value: newState)
    }

    switch action {
    case .gameStarted:
        return environment.gameStateManager.loadGame()
            .catchToEffect()
            .map(AppAction.loadGameResponse)
    case .manualPlayerDiskPlaced(let position):
        guard var turn = state.turn,
            state.players[turn.index] == .manual
        else {
            return .none
        }

        if isGameEnd {
            state.turn = nil
        } else if Rule.validMoves(for: turn.flipped, on: state.board).isEmpty {
            state.shouldSkip = true
        } else {
            return Effect(value: .placeDisk(position))
        }
        return Effect(value: .saveGame)
    case .resetTapped:
        return Effect.concatenate(
            // TODO: Effect(value: .saveGame)としたいがsaveGameResponseとgameStartedの順番が逆になる
            environment.gameStateManager.saveGame(state: AppState.intialState)
                .catchToEffect()
                .map(AppAction.saveGameResponse),
            Effect(value: AppAction.gameStarted)
        )
    case .playerChanged(let disk, let player):
        state.players[disk.index] = player
        return .none
    case .loadGameResponse(.success(.loaded(let loadedState))):
        state = loadedState
        return Effect(value: .saveGame)
    case .loadGameResponse(.failure(let error)):
        // TODO: error handling
        state = AppState.intialState
        return Effect(value: .saveGame)
    case .saveGame:
        return environment.gameStateManager.saveGame(state: state)
            .catchToEffect()
            .map(AppAction.saveGameResponse)
    case .saveGameResponse(let result):
        if case .failure(let error) = result {
            // TODO: error handling
            print(error.localizedDescription)
        }
        return .none
    case .computerPlay:
        return environment.computer(state.board, state.turn!)
            .map(AppAction.computerPlayResponse)
            .eraseToEffect()
    case .computerPlayResponse(let position):
        if let position = position {
            return Effect(value: .placeDisk(position))
        } else if isGameEnd {
            state.turn = nil
        } else {
            state.shouldSkip = true
        }
        return Effect(value: .saveGame)
    case .turnSkipped:
        state.shouldSkip = false
        state.turn?.flip()
        if let turn = state.turn, state.players[turn.index] == .computer {
            return Effect(value: .computerPlay)
        }
        return Effect(value: .saveGame)
    case .placeDisk(let position):
        return Effect.concatenate(
            stateAfterDiskPlaced(state: state, position: position)
                .receive(on: environment.mainQueue)
                .map(AppAction.updateState)
                .eraseToEffect(),
            Effect(value: AppAction.saveGame)
        )
    case .updateState(let newState):
        state = newState
        return .none
    }
}
