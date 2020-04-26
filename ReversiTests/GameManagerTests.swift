//
//  GameManagerTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

class GameManagerTests: XCTestCase {
    func testWhenCallNewGameThenEverythingIsInitial() {
        let gameManager = startNewGame()
        XCTAssertEqual(gameManager.board.disks, Board.initialDisks)
    }

    func testWhenCallNextTurnAndBothPlayersHavePlaceThenMoveTurn() {
        let gameManager = startNewGame()
        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        let activePlayer = gameManager.state.activePlayer
        gameManager.nextTurn(from: activePlayer)

        let action = delegate.receivedNextActions.first!
        if case .next(let receivedPlayer, let receivedBoard) = action {
            XCTAssertEqual(receivedPlayer, activePlayer.flipped)
            XCTAssertEqual(receivedBoard.disks, gameManager.board.disks)
        } else {
            XCTFail("invalid case")
        }
    }

    func testWhenCallNextTurnAndBothPlayersHaveNoPlaceThenFinishGame() {
        let gameManager = startNewGame()
        gameManager.fullfill(with: .dark)
        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        gameManager.nextTurn(from:  gameManager.state.activePlayer)

        let action = delegate.receivedNextActions.first!
        if case .finish = action {
        } else {
            XCTFail("invalid case")
        }
    }

    func testWhenCallNextTurnAndNextPlayerHasPlaceThenPassNextTurn() {
        let gameManager = startNewGame()

        // 左上を別の色、左下は空にして残りは同じ色で埋める
        for y in ReversiSpecification.yRange {
            for x in ReversiSpecification.xRange {
                if x == 0, y == ReversiSpecification.height - 1 {
                    continue
                }
                if x == 0, y == 0 {
                    gameManager.board.setDisk(.light, atX: x, y: y)
                } else {
                    gameManager.board.setDisk(.dark, atX: x, y: y)
                }
            }
        }

        let delegate = MockGameManagerDelegate()
        gameManager.delegate = delegate

        let activePlayer = gameManager.state.activePlayer
        gameManager.nextTurn(from: activePlayer)

        let action = delegate.receivedNextActions.first!
        if case .pass(let receivedPlayer) = action {
            XCTAssertEqual(receivedPlayer, activePlayer.flipped)
        } else {
            XCTFail("invalid case")
        }
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

    private func startNewGame() -> GameManager {
        let store = MemoryGameStateStore()
        let gameManager = GameManager(store: store)
        _ = gameManager.newGame()
        return gameManager
    }
}

// MARK: GameManagerDelegate for test

final class MockGameManagerDelegate: GameManagerDelegate {
    var receivedNextActions: [NextAction] = []
    func update(_ action: NextAction) {
        receivedNextActions.append(action)
    }

    var startedGameCalled = false
    func startedGame(_ state: GameState) {
        startedGameCalled = true
    }

    var setDiskCalled = false
    func setDisk(_ disk: Disk, at: Board.Position) {
        setDiskCalled = true
    }
}

// MARK: GameStateStore for test

class MemoryGameStateStore: GameStateStore {
    enum StoreError: Error {
        case noData
    }

    var state: GameState?
    func saveGame(turn: Disk, players: [GamePlayer], board: Board, completion: @escaping (Result<Void, Error>) -> Void) {
        state = GameState(activePlayer: players[turn.index],
                          players: players, board: board)
        completion(.success(()))
    }

    func loadGame(completion: @escaping (Result<GameState, Error>) -> Void) {
        guard let state = state else {
            completion(.failure(StoreError.noData))
            return
        }
        completion(.success(state))
    }
}

// MARK: File-private extensions

extension GamePlayer {
    var flipped: GamePlayer {
        return .init(type: type, side: side.flipped)
    }
}

extension GameManager {
    func fullfill(with disk: Disk) {
        for y in ReversiSpecification.yRange {
            for x in ReversiSpecification.xRange {
                self.board.setDisk(disk, atX: x, y: y)
            }
        }
    }
}

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
}
