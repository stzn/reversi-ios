//
//  GameManagerTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

class MockComputerPlayerDelegate: ComputerPlayerDelegate {
    var startedTurnCalled = false
    func startedTurn(of player: GamePlayer) {
        startedTurnCalled = true
    }

    var endedTurnCalled = false
    func endedTurn(of player: GamePlayer) {
        endedTurnCalled = true
    }
}

class MockGameManagerDelegate: GameManagerDelegate {
    var setDiskCalled = false
    func setDisk(_ disk: Disk, atX: Int, y: Int) {
        setDiskCalled = false
    }

    var changedTurnCalled = false
    func changedTurn(to player: GamePlayer) {
        changedTurnCalled = true
    }

    var passedTurnCalled = false
    func passedTurn(of player: GamePlayer) {
        passedTurnCalled = true
    }

    var finishedGameCalled = false
    func finishedGame(wonBy player: GamePlayer?) {
        finishedGameCalled = true
    }
}

class GameManagerTests: XCTestCase {
    func testWhenCallNewGameThenEverythingIsInitial() {
        let (gameManager, board) = startNewGame()
        XCTAssertEqual(gameManager.activePlayer?.turn, .dark)
        XCTAssertEqual(board.disks, Board.initialDisks)
    }

    func testWhenCallWaitForPlayerThenManualPlayerDoesNothing() {
        let (gameManager, _) = startNewGame()
        let computerDelegate = MockComputerPlayerDelegate()
        gameManager.computerDelegate = computerDelegate
        gameManager.changedPlayerType(.manual)

        gameManager.waitForPlayer()

        XCTAssertEqual(computerDelegate.startedTurnCalled, false)
        XCTAssertEqual(computerDelegate.endedTurnCalled, false)
    }

    func testWhenCallWaitForPlayerThenComputerPlayerStartsPlayTurn() {
        let (gameManager, _) = startNewGame()
        let computerDelegate = MockComputerPlayerDelegate()
        gameManager.computerDelegate = computerDelegate
        gameManager.changedPlayerType(.computer)

        gameManager.waitForPlayer()

        XCTAssertEqual(computerDelegate.startedTurnCalled, true)
    }

    func testWhenCallNextTurnAndBothPlayersHavePlaceThenChangeTurn() {
        let (gameManager, _) = startNewGame()
        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        gameManager.nextTurn()

        XCTAssertEqual(delegate.changedTurnCalled, true)
    }

    func testWhenCallNextTurnAndBothPlayersHaveNoPlaceThenGameFinishes() {
        let (gameManager, board) = startNewGame()
        board.fullfill(with: .dark)
        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        gameManager.nextTurn()

        XCTAssertEqual(delegate.finishedGameCalled, true)
    }

    func testWhenCallNextTurnAndNextPlayerHasPlaceThenPassNextTurn() {
        let (gameManager, board) = startNewGame()

        // 左上を別の色、左下は空にして残りは同じ色で埋める
        for y in ReversiSpecification.yRange {
            for x in ReversiSpecification.xRange {
                if x == 0, y == ReversiSpecification.height - 1 {
                    continue
                }
                if x == 0, y == 0 {
                    board.setDisk(.light, atX: x, y: y)
                } else {
                    board.setDisk(.dark, atX: x, y: y)
                }
            }
        }

        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        gameManager.nextTurn()

        XCTAssertEqual(delegate.passedTurnCalled, true)
    }

    // TODO: 時間がかかるのでCI上のみで実行する
    //    func testWhenCallPlayTurnOfComputerWithoutCancelThenPlayerEndsTurn() {
    //        let (gameManager, _) = startNewGame()
    //        let computerDelegate = MockComputerPlayerDelegate()
    //        gameManager.computerDelegate = computerDelegate
    //        gameManager.changedPlayerType(.computer)
    //
    //        let exp = expectation(description: "wait for finishing")
    //        _ = gameManager.playTurnOfComputer {
    //            XCTAssertEqual(computerDelegate.startedTurnCalled, true)
    //            XCTAssertEqual(computerDelegate.endedTurnCalled, true)
    //            exp.fulfill()
    //        }
    //        wait(for: [exp], timeout: 3.0)
    //    }
    //
    //    func testWhenCallPlayTurnOfComputerWithCancelThenPlayerDoesNotComplete() {
    //        let (gameManager, _) = startNewGame()
    //        let computerDelegate = MockComputerPlayerDelegate()
    //        gameManager.computerDelegate = computerDelegate
    //        gameManager.changedPlayerType(.computer)
    //
    //        let exp = expectation(description: "wait for finishing")
    //        let canceller = gameManager.playTurnOfComputer {
    //            exp.fulfill()
    //        }
    //        canceller.cancel()
    //
    //        let result = XCTWaiter.wait(for: [exp], timeout: 3.0)
    //        if case .timedOut = result {
    //            return
    //        }
    //        XCTFail()
    //    }

    // MARK: Helper

    private func startNewGame() -> (GameManager, Board) {
        let board = Board()
        let gameManager = GameManager(board: board)
        gameManager.newGame()
        return (gameManager, board)
    }
}

// MARK: File-private extensions

extension Board {
    static var initialDisks: [Position: Disk] {
        let width = ReversiSpecification.width
        let height = ReversiSpecification.height
        return [
            Position(x: width / 2 - 1, y: height / 2 - 1): .light,
            Position(x: width / 2, y: height / 2 - 1): .dark,
            Position(x: width / 2 - 1, y: height / 2): .dark,
            Position(x: width / 2, y: height / 2): .light,
        ]
    }

    func fullfill(with disk: Disk) {
        for y in ReversiSpecification.yRange {
            for x in ReversiSpecification.xRange {
                self.setDisk(disk, atX: x, y: y)
            }
        }
    }
}
