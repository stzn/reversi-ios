//
//  GameStateManager.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

protocol GameStateManager {
    func saveGame(state: AppState) -> Effect<GameStateSaveAction, GameStateManagerError>
    func loadGame() -> Effect<GameStateLoadAction, GameStateManagerError>
}

enum GameStateLoadAction: Equatable {
    case loaded(AppState)
}

enum GameStateSaveAction: Equatable {
    case saved
}

enum GameStateManagerError: Error, Equatable {
    static func == (lhs: GameStateManagerError, rhs: GameStateManagerError) -> Bool {
        switch (lhs, rhs) {
        case let (.read(lPath, lReason), .read(rPath, rReason)):
            return lPath == rPath
                && lReason?.localizedDescription == rReason?.localizedDescription
        case let (.write(lPath, lReason), .write(rPath, rReason)):
            return lPath == rPath
                && lReason?.localizedDescription == rReason?.localizedDescription
        default:
            return false
        }
    }

    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}
