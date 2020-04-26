//
//  GameState.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum NextAction {
    case set(Disk, Board.Position, Board)
    case next(GamePlayer, Board)
    case pass(GamePlayer)
    case finish(GamePlayer?)
}

struct GameState {
    let activePlayerDisk: Disk
    let players: [GamePlayer]
    let board: Board
}
