//
//  GameCore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

struct GameState: Equatable {
    var board: Board = Board()
    var players: [Player] = [.manual, .manual]
    var turn: Disk? = nil
    var shouldSkip: Bool = false
    var currentTapPosition: DiskPosition? = nil
    var playingAsComputer: Disk? = nil

    static var intialState: GameState {
        .init(
            board: Board.reset(),
            players: [.manual, .manual], turn: .dark,
            shouldSkip: false, currentTapPosition: nil)
    }
}

enum GameAction: Equatable {
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
    case updateState(GameState)
    case logoutButtonTapped
}

struct GameEnvironment {
    var computer: (Board, Disk) -> Effect<DiskPosition?, Never>
    var gameStateManager: GameStateManager
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let gameReducer = Reducer<GameState, GameAction, GameEnvironment> {
    state, action, environment in

    struct CancelId: Hashable {}

    var isGameEnd: Bool {
        guard let turn = state.turn else {
            return true
        }
        return Rule.validMoves(for: turn.flipped, on: state.board).isEmpty
            && Rule.validMoves(for: turn, on: state.board).isEmpty
    }

    func stateAfterDiskPlaced(state: GameState, position: DiskPosition) -> GameState {
        var newState = state
        guard var turn = newState.turn else {
            return newState
        }

        let diskCoordinates = Rule.flippedDiskCoordinatesByPlacingDisk(
            turn, atX: position.x, y: position.y, on: newState.board.disks)

        if diskCoordinates.isEmpty {
            return newState
        }

        newState.currentTapPosition = .init(x: position.x, y: position.y)
        newState.board.setDisk(turn, atX: position.x, y: position.y)

        for (x, y) in diskCoordinates {
            newState.board.setDisk(turn, atX: x, y: y)
        }

        turn.flip()
        newState.turn = turn
        return newState
    }

    switch action {
    case .gameStarted:
        return environment.gameStateManager.loadGame()
            .catchToEffect()
            .map(GameAction.loadGameResponse)
    case .manualPlayerDiskPlaced(let position):
        guard var turn = state.turn,
            state.players[turn.index] == .manual
        else {
            return .none
        }
        return Effect(value: .placeDisk(position))
    case .resetTapped:
        return environment.gameStateManager.saveGame(GameState.intialState)
            .catchToEffect()
            .map(GameAction.saveGameResponse)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
            .map { _ in GameAction.gameStarted }
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
        state = GameState.intialState
        return Effect(value: .saveGame)
    case .saveGame:
        return environment.gameStateManager.saveGame(state)
            .catchToEffect()
            .map(GameAction.saveGameResponse)
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
            .map(GameAction.computerPlayResponse)
            .eraseToEffect()
            .cancellable(id: CancelId())
    case .computerPlayResponse(let position):
        if let position = position {
            return Effect(value: .placeDisk(position))
        }
        return Effect(value: .updateState(state))
    case .turnSkipped:
        state.shouldSkip = false
        state.turn?.flip()
        if let turn = state.turn, state.players[turn.index] == .computer {
            return Effect(value: .computerPlay)
        }
        return Effect(value: .saveGame)
    case .placeDisk(let position):
        let newState = stateAfterDiskPlaced(state: state, position: position)
        return Effect(value: .updateState(newState))
            .receive(on: environment.mainQueue)
            .eraseToEffect()
            .cancellable(id: CancelId())
    case .updateState(let receivedState):
        var newState = receivedState
        guard let turn = newState.turn else {
            return .none
        }
        if isGameEnd {
            newState.turn = nil
            newState.currentTapPosition = nil
        } else if Rule.validMoves(for: turn, on: newState.board).isEmpty {
            newState.shouldSkip = true
        }
        newState.playingAsComputer = nil
        state = newState
        return Effect(value: GameAction.saveGame)
    case .logoutButtonTapped:
        return environment.gameStateManager.saveGame(GameState.intialState)
            .catchToEffect()
            .map(GameAction.saveGameResponse)

    }
}
