//
//  InMemoryGameStore.swift
//  ReversiCoreTests
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

@testable import ReversiCore

extension Optional where Wrapped == Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }

    var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}

final class InMemoryGameStateStore: GameStateStore {
    var savedData: String = ""

    enum IOError: Error {
        case write(cause: Error?)
        case read(cause: Error?)
    }

    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame(
        turn: Disk, players: [GamePlayer], board: Board,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var output: String = ""
        output += turn.index.description
        players.forEach {
            output += $0.type.rawValue.description
        }
        output += "\n"

        for y in Rule.yRange {
            for x in Rule.xRange {
                output += board.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }
        savedData = output
        completion(.success(()))
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame(completion: @escaping (Result<GameState, Error>) -> Void) {
        let input = savedData
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            completion(.failure(IOError.read(cause: nil)))
            return
        }

        let turn: Disk
        do {  // turn
            guard
                let diskSymbol = line.popFirst(),
                let disknumber = Int(diskSymbol.description)
            else {
                completion(.failure(IOError.read(cause: nil)))
                return
            }
            turn = Disk(index: disknumber)
        }

        // players
        var players: [GamePlayer] = []
        for side in Disk.sides {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let playerType = PlayerType(rawValue: playerNumber)
            else {
                completion(.failure(IOError.read(cause: nil)))
                return
            }
            players.append(GamePlayer(type: playerType, side: side))
        }

        let board = Board()
        do {  // board
            guard lines.count == Rule.height else {
                completion(.failure(IOError.read(cause: nil)))
                return
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    if let disk = Disk?(symbol: "\(character)").flatMap({ $0 }) {
                        board.setDisk(disk, atX: x, y: y)
                    }
                    x += 1
                }
                guard x == Rule.width else {
                    completion(.failure(IOError.read(cause: nil)))
                    return
                }
                y += 1
            }
            guard y == Rule.height else {
                completion(.failure(IOError.read(cause: nil)))
                return
            }
        }
        let storedData = GameState(
            activePlayerSide: turn,
            players: players,
            board: board)
        completion(.success(storedData))
    }

    func clear() {
        savedData = ""
    }
}
