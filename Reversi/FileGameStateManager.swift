//
//  FileGameStateStore.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/06.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

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

final class FileGameStateManager: GameStateManager {
    private let path: String
    init(path: String) {
        self.path = path
    }

    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    func saveGame(state: GameState) -> Effect<GameStateSaveAction, GameStateManagerError> {
        let path = self.path
        return Effect.result {
            var output: String = ""
            output += state.turn?.index.description ?? ""
            state.players.forEach {
                output += $0.rawValue.description
            }
            output += "\n"

            for y in Rule.yRange {
                for x in Rule.xRange {
                    output += state.board.diskAt(x: x, y: y).symbol
                }
                output += "\n"
            }

            do {
                try output.write(toFile: path, atomically: true, encoding: .utf8)
                return .success(.saved)
            } catch let error {
                return .failure(.write(path: path, cause: error))
            }
        }
    }

    func loadGame() -> Effect<GameStateLoadAction, GameStateManagerError> {
        let path = self.path
        return Effect.result {
            var input: String
            do {
                input = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                return .failure(.read(path: path, cause: error))
            }
            var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

            guard var line = lines.popFirst() else {
                return .failure(.read(path: path, cause: nil))
            }

            let turn: Disk
            do {  // turn
                guard
                    let diskSymbol = line.popFirst(),
                    let disknumber = Int(diskSymbol.description)
                else {
                    return .failure(.read(path: path, cause: nil))
                }
                turn = Disk(index: disknumber)
            }

            // players
            var players: [Player] = []
            for _ in Disk.sides {
                guard
                    let playerSymbol = line.popFirst(),
                    let playerNumber = Int(playerSymbol.description),
                    let player = Player(rawValue: playerNumber)
                else {
                    return .failure(.read(path: path, cause: nil))
                }
                players.append(player)
            }

            let board = Board()
            do {  // board
                guard lines.count == Rule.height else {
                    return .failure(.read(path: path, cause: nil))
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
                        return .failure(.read(path: path, cause: nil))
                    }
                    y += 1
                }
                guard y == Rule.height else {
                    return .failure(.read(path: path, cause: nil))
                }
            }
            let storedData = GameState(
                board: board, players: players,
                turn: turn,
                shouldSkip: false)
            return .success(.loaded(storedData))
        }
    }
}
