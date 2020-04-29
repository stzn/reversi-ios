//
//  GameState.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public enum NextAction {
    case start(GameState)
    case set(Disk, Board.Position, Board)
    case next(GamePlayer, Board)
    case pass
    case finish(GamePlayer?)
    case reset(GameState)
}

public struct GameState {
    public var activePlayerSide: Disk
    public var players: [GamePlayer]
    public var board: Board
    public init(activePlayerSide: Disk,
                players: [GamePlayer],
                board: Board) {
        self.activePlayerSide = activePlayerSide
        self.players = players
        self.board = board
    }
}
