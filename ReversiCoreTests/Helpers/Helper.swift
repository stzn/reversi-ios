//
//  Helper.swift
//  ReversiCoreTests
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import ReversiCore

var defaultPlayers: [GamePlayer] = [
    GamePlayer(type: .manual, side: .dark),
    GamePlayer(type: .manual, side: .light),
]

var anyGameState = GameState(activePlayerSide: defaultPlayers.first!.side,
                             players: defaultPlayers,
                             board: Board())

let initialPlacedDisks: [Board.Position: Disk] =
    [
        Board.Position(x: ReversiSpecification.width / 2 - 1, y: ReversiSpecification.height / 2 - 1): .light,
        Board.Position(x: ReversiSpecification.width / 2, y: ReversiSpecification.height / 2 - 1): .dark,
        Board.Position(x: ReversiSpecification.width / 2 - 1, y: ReversiSpecification.height / 2): .dark,
        Board.Position(x: ReversiSpecification.width / 2, y: ReversiSpecification.height / 2): .light,
    ]

func deleteGame() {
    let path = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        as NSString).appendingPathComponent("Game")
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: path) {
        try! fileManager.removeItem(atPath: path)
    }
}

let boardWidth: Int = ReversiSpecification.width
let boardHeight: Int = ReversiSpecification.height

import XCTest

extension XCTestCase {
    func fullfillForWon(width: Int, height: Int) -> Board {
        let board = Board()
        for y in 0..<height {
            for x in 0..<width {
                board.setDisks(.dark, at: [.init(x: x, y: y)])
            }
        }
        return board
    }

    func fullfillForTied(width: Int, height: Int) -> Board {
        let board = Board()
        var turn: Disk = .dark
        for y in 0..<height {
            for x in 0..<width {
                board.setDisks(turn, at: [.init(x: x, y: y)])
                turn = turn.flipped
            }
        }
        return board
    }

    func fullfillForPassed(width: Int, height: Int) -> Board {
        let lastX = width - 1
        let lastY = height - 1
        let board = Board()
        for y in 0..<height {
            for x in 0..<width {
                // 一箇所だけ隙間を空けておく
                if x == 0 && y == 0
                    || x == lastX && y == lastY {
                    continue
                }
                board.setDisks(.dark, at: [.init(x: x, y: y)])
            }
        }
        board.setDisks(.light, at: [.init(x: lastX, y: lastY)])
        return board
    }

    func save(to store: GameStateStore, state: GameState){
        let exp = expectation(description: "wait for save")
        store.saveGame(turn: state.activePlayerSide, players: state.players,
                       board: state.board) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

