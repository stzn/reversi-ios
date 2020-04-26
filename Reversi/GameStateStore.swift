//
//  GameStateStore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol GameStateStore {
    func saveGame(turn: Disk, players: [GamePlayer], board: Board,
                  completion: @escaping (Result<Void, Error>) -> Void)
    func loadGame(completion: @escaping (Result<StoredData, Error>) -> Void)
}

struct StoredData {
    let activePlayerDisk: Disk
    let players: [GamePlayer]
    let board: Board
}
