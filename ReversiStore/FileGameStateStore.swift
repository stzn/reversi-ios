//
//  FileGameStateStore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ReversiCore

extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
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

    fileprivate var symbol: String {
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

public final class FileGameStateStore: GameStateStore {
    private let path: String
    public init(path: String) {
        self.path = path
    }

    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    /// ゲームの状態をファイルに書き出し、保存します。
    public func saveGame(
        turn: Disk, players: [GamePlayer], board: Board,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var output: String = ""
        output += turn.index.description
        players.forEach {
            output += $0.type.rawValue.description
        }
        output += "\n"

        for y in ReversiSpecification.yRange {
            for x in ReversiSpecification.xRange {
                output += board.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            completion(.failure(FileIOError.read(path: path, cause: error)))
            return
        }
        completion(.success(()))
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    public func loadGame(completion: @escaping (Result<GameState, Error>) -> Void) {
        var input: String
        do {
            input = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            completion(.failure(FileIOError.read(path: path, cause: error)))
            return
        }
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            completion(.failure(FileIOError.read(path: path, cause: nil)))
            return
        }

        let turn: Disk
        do {  // turn
            guard
                let diskSymbol = line.popFirst(),
                let disknumber = Int(diskSymbol.description)
            else {
                completion(.failure(FileIOError.read(path: path, cause: nil)))
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
                completion(.failure(FileIOError.read(path: path, cause: nil)))
                return
            }
            players.append(GamePlayer(type: playerType, side: side))
        }

        let board = Board()
        do {  // board
            guard lines.count == ReversiSpecification.height else {
                completion(.failure(FileIOError.read(path: path, cause: nil)))
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
                guard x == ReversiSpecification.width else {
                    completion(.failure(FileIOError.read(path: path, cause: nil)))
                    return
                }
                y += 1
            }
            guard y == ReversiSpecification.height else {
                completion(.failure(FileIOError.read(path: path, cause: nil)))
                return
            }
        }
        let storedData = GameState(
            activePlayerSide: turn,
            players: players,
            board: board)
        completion(.success(storedData))
    }
}
