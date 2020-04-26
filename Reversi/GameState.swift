//
//  GameState.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum NextAction {
    case start(GameState)
    case set(Disk, Board.Position, Board)
    case next(GamePlayer, Board)
    case pass(GamePlayer)
    case finish(GamePlayer?)
    case reset
}

struct GameState {
    var activePlayer: GamePlayer
    var players: [GamePlayer]
    var board: Board
}
