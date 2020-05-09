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

    static var intialState: AppState {
        .init(
            board: Board.reset(),
            players: [.manual, .manual], turn: .dark,
            shouldSkip: false, currentTapPosition: nil)
    }
}

enum AppAction: Equatable {
    case gameStarted
    case diskPlaced(DiskPosition)
    case resetTapped
    case playerChanged(Disk, Player)
    case loadGameResponse(Result<GameStateLoadAction, GameStateManagerError>)
    case saveGame
    case saveGameResponse(Result<GameStateSaveAction, GameStateManagerError>)
    case computerPlay
    case computerPlayResponse(DiskPosition?)
    case turnSkipped
}

struct AppEnvironment {
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> {
    state, action, environment in

    func playTurnOfComputer() -> Effect<AppAction, Never> {
        return environment.computer(state.board, state.turn!)
            .map(AppAction.computerPlayResponse)
            .receive(on: DispatchQueue.main)
            .eraseToEffect()
    }

    var isGameEnd: Bool {
        guard let turn = state.turn else {
            return true
        }
        return Rule.validMoves(for: turn.flipped, on: state.board).isEmpty
            && Rule.validMoves(for: turn, on: state.board).isEmpty
    }

    switch action {
    case .gameStarted:
        return environment.gameStateManager.loadGame()
            .catchToEffect()
            .map(AppAction.loadGameResponse)
    case .diskPlaced(let position):
        guard var turn = state.turn else {
            return .none
        }
        if isGameEnd {
            state.turn = nil
        } else if Rule.validMoves(for: turn.flipped, on: state.board).isEmpty {
            state.shouldSkip = true
        } else {
            playTurn(&state, position: position)
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
        return Effect(value: .saveGame)
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
        return playTurnOfComputer()
    case .computerPlayResponse(let position):
        if let position = position {
            playTurn(&state, position: position)
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
    }
}

private func playTurn(_ state: inout AppState, position: DiskPosition) {
    guard var turn = state.turn else {
        return
    }

    let diskCoordinates = Rule.flippedDiskCoordinatesByPlacingDisk(
        turn, atX: position.x, y: position.y, on: state.board.disks)

    if diskCoordinates.isEmpty {
        return
    }

    state.currentTapPosition = .init(x: position.x, y: position.y)
    state.board.setDisk(turn, atX: position.x, y: position.y)

    for (x, y) in diskCoordinates {
        state.board.setDisk(turn, atX: x, y: y)
    }

    turn.flip()
    state.turn = turn
}
