//
//  GameStateManager.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

enum GameStateLoadAction: Equatable {
    case loaded( GameState)
}

enum GameStateSaveAction: Equatable {
    case saved
}

enum GameStateManagerError: Error, Equatable {
    static func == (lhs: GameStateManagerError, rhs: GameStateManagerError) -> Bool {
        switch (lhs, rhs) {
        case let (.read(lPath, lReason), .read(rPath, rReason)):
            return lPath == rPath
                && lReason?.localizedDescription == rReason?.localizedDescription
        case let (.write(lPath, lReason), .write(rPath, rReason)):
            return lPath == rPath
                && lReason?.localizedDescription == rReason?.localizedDescription
        default:
            return false
        }
    }

    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}

struct GameStateManager {
    var saveGame: ( GameState) -> Effect<GameStateSaveAction, GameStateManagerError>
    var loadGame: () -> Effect<GameStateLoadAction, GameStateManagerError>
}

extension GameStateManager {
    private static var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
            as NSString).appendingPathComponent("Game")
    }

    static var live = GameStateManager(
        saveGame: { state in
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
        },
        loadGame: {
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
                let storedData =  GameState(
                    board: board, players: players,
                    turn: turn,
                    shouldSkip: false)
                return .success(.loaded(storedData))
            }
        })
}

#if DEBUG

extension GameStateManager {
    static func mock(id: String) -> GameStateManager {
        GameStateManager(
        saveGame: { state in
            savedState[id] = state
            return Effect(value: GameStateSaveAction.saved)
        },
        loadGame: {
            guard let state = savedState[id] else {
                return Effect(error: .write(path: "", cause: nil))
            }
            savedState[id] = nil
            return Effect(value: GameStateLoadAction.loaded(state))
        })
    }
}

private var savedState: [String:  GameState] = [:]

#endif

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
