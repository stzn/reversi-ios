//
//  Helper.swift
//  ReversiStoreTests
//
//  Created by Shinzan Takata on 2020/05/01.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ReversiCore

@testable import ReversiStore

var defaultPlayers: [GamePlayer] = [
    GamePlayer(type: .manual, side: .dark),
    GamePlayer(type: .manual, side: .light),
]

var anyGameState = GameState(activePlayerSide: defaultPlayers.first!.side,
                             players: defaultPlayers,
                             board: Board())
