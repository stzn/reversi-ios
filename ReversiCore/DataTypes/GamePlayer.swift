//
//  GamePlayer.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public enum PlayerType: Int {
    case manual = 0
    case computer = 1
}

public struct GamePlayer: Equatable, Hashable {
    public var type: PlayerType
    public let side: Disk
    public init(type: PlayerType, side: Disk) {
        self.type = type
        self.side = side
    }

    mutating func setType(_ type: PlayerType) {
        self.type = type
    }
}
