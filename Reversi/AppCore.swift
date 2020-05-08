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

    guard var turn = state.turn else {
        return .none
    }

    switch action {
    case .gameStarted:
        return environment.gameStateManager.loadGame()
            .catchToEffect()
            .map(AppAction.loadGameResponse)
    case .diskPlaced(let position):
        turn.flip()

        if Rule.validMoves(for: turn, on: state.board).isEmpty {
            if Rule.validMoves(for: turn.flipped, on: state.board).isEmpty {
                state.turn = nil
            } else {
                state.turn = turn
            }
        } else {
            playTurn(&state, position: position)
        }
        return environment.gameStateManager.saveGame(state: state)
            .catchToEffect()
            .map(AppAction.saveGameResponse)
    case .resetTapped:
        return environment.gameStateManager.saveGame(state: AppState.intialState)
            .catchToEffect()
            .map(AppAction.saveGameResponse)
            .flatMap { _ in Effect(value: AppAction.gameStarted) }
            .eraseToEffect()
    case .playerChanged(let disk, let player):
        state.players[disk.index] = player
        return environment.gameStateManager.saveGame(state: state)
            .catchToEffect()
            .map(AppAction.saveGameResponse)
    case .loadGameResponse(.success(.loaded(let loadedState))):
        state = loadedState
        return environment.gameStateManager.saveGame(state: state)
            .catchToEffect()
            .map(AppAction.saveGameResponse)
    case .loadGameResponse(.failure(let error)):
        // TODO: error handling
        state = AppState.intialState
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
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    case .computerPlayResponse(let position):
        if let position = position {
            return Effect(value: AppAction.diskPlaced(position))
        } else {
            state.shouldSkip = true
            return .none
        }
    case .turnSkipped:
        state.shouldSkip = false
        state.turn?.flip()
        return .none
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
