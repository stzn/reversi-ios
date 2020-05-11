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
    var playingAsComputer: Disk? = nil

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
    case judgeGameProcess
}

struct AppEnvironment {
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> {
    state, action, environment in

    struct CancelId: Hashable {}

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
        return Effect(value: .placeDisk(position))
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
        if player == .manual, state.turn == disk {
            state.playingAsComputer = nil
            return Effect.concatenate(
                Effect(value: .saveGame),
                .cancel(id: CancelId())
            )
        }
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
        guard let turn = state.turn else {
            return .none
        }
        state.playingAsComputer = turn
        return environment.computer(state.board, turn)
            .delay(for: 2.0, scheduler: environment.mainQueue)
            .map(AppAction.computerPlayResponse)
            .eraseToEffect()
            .cancellable(id: CancelId())
    case .computerPlayResponse(let position):
        if let position = position {
            return Effect(value: .placeDisk(position))
        }
        return Effect(value: AppAction.judgeGameProcess)
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
                .eraseToEffect()
                .cancellable(id: CancelId()),
            Effect(value: AppAction.saveGame),
            Effect(value: AppAction.judgeGameProcess)
        )
    case .updateState(let newState):
        state = newState
        return .none
    case .judgeGameProcess:
        guard let turn = state.turn else {
            return .none
        }
        if isGameEnd {
            state.turn = nil
        } else if Rule.validMoves(for: turn, on: state.board).isEmpty {
            state.shouldSkip = true
        }
        state.playingAsComputer = nil
        return .none
    }
}
