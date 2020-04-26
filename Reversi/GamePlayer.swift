//
//  GamePlayer.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum PlayerType: Int {
    case manual = 0
    case computer = 1
}

struct GamePlayer: Equatable, Hashable {
    var type: PlayerType
    let side: Disk

    mutating func setType(_ type: PlayerType) {
        self.type = type
    }
}
