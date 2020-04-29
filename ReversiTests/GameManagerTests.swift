//
//  GameManagerTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import Reversi

class GameManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        deleteGame()
    }

    func testWhenHasSavedDataAndCallInitThenSavedDataLoaded() {
        let expectedState = GameState(
            activePlayerSide: .light,
            players: defaultPlayers,
            board: Board())
        let store = InMemoryGameStateStore()
        save(to: store, state: expectedState)

        let manager = GameManager(store: store)

        XCTAssertEqual(manager.state.activePlayerSide, expectedState.activePlayerSide)
        XCTAssertEqual(manager.state.players, expectedState.players)
        XCTAssertEqual(manager.state.board.disks, expectedState.board.disks)
    }

    func testWhenCallReuqestGameThenSentProperState() {
        let delegate = MockGameManagerDelegate()
        let manager = GameManager(store: InMemoryGameStateStore())
        manager.delegate = delegate
        manager.requestStartGame()
        guard let action = delegate.receivedActions.first,
            case .start(let state) = action
        else {
            return
        }
        XCTAssertEqual(
            state.players,
            [
                GamePlayer(type: .manual, side: .dark),
                GamePlayer(type: .manual, side: .light),
            ])
        XCTAssertEqual(state.board.disks, initialPlacedDisks)
        XCTAssertEqual(state.activePlayerSide, .dark)
    }

    func testWhenCallPlaceDiskThenSetAndSentProperState() {
        let board = Board()
        board.reset()
        let expectedState = GameState(
            activePlayerSide: .dark,
            players: defaultPlayers,
            board: board)
        let store = InMemoryGameStateStore()
        save(to: store, state: expectedState)
        let delegate = MockGameManagerDelegate()
        let manager = GameManager(store: store)
        manager.delegate = delegate
        let expectedX = ReversiSpecification.width / 2 + 1
        let expectedY = ReversiSpecification.height / 2
        let expectedPosition = Board.Position(x: expectedX, y: expectedY)

        try! manager.placeDisk(at: expectedPosition)

        guard let action = delegate.receivedActions.first,
            case .set(let side, let position, let b) = action
        else {
            return
        }
        XCTAssertEqual(side, expectedState.activePlayerSide)
        for (position, disk) in manager.state.board.disks {
            XCTAssertEqual(b.disks[position], disk)
        }
        XCTAssertEqual(position, expectedPosition)
    }

    func testWhenCallChangePlayerThenSetProperPlayerType() {
        let expectedState = GameState(
            activePlayerSide: .dark,
            players: defaultPlayers,
            board: Board())
        let store = InMemoryGameStateStore()
        save(to: store, state: expectedState)
        let delegate = MockGameManagerDelegate()
        let manager = GameManager(store: store)
        manager.delegate = delegate

        manager.changePlayerType(.computer, of: .dark)

        guard let action = delegate.receivedActions.first,
            case .next(let player, let board) = action
        else {
            return
        }
        XCTAssertEqual(player,
                       manager.state.players[manager.state.activePlayerSide.index])
        XCTAssertEqual(board.disks,
                       manager.state.board.disks)
    }

    func testWhenCanDoNextAndCallRequestNextTurnThenTurnedActivePlayer() {
        let expectedState = GameState(
            activePlayerSide: .dark,
            players: defaultPlayers,
            board: Board())

        let delegate = MockGameManagerDelegate()
        let store = InMemoryGameStateStore()
        save(to: store, state: expectedState)

        let manager = GameManager(store: store)
        manager.delegate = delegate

        manager.requestNextTurn()

        guard let action = delegate.receivedActions.first,
            case .next(let player, _) = action
        else {
            return
        }
        XCTAssertEqual(player.side,
                       manager.state.activePlayerSide)
    }

    func testWhenCannotDoNextAndCallRequestNextTurnThenPassedTurn() {
        let delegate = MockGameManagerDelegate()
        let store = InMemoryGameStateStore()
        let board = fullfillForPassed(width: ReversiSpecification.width, height: ReversiSpecification.height)

        save(to: store,
             state: .init(activePlayerSide: .light, players: defaultPlayers, board: board))

        let manager = GameManager(store: store)
        manager.delegate = delegate

        manager.requestNextTurn()

        guard let action = delegate.receivedActions.first,
            case .pass = action
        else {
            XCTFail("shold be pass \(delegate.receivedActions.first!)")
            return
        }
        XCTAssertEqual(.dark,
                       manager.state.activePlayerSide)
    }

    private func load(from store: GameStateStore) -> GameState {
        let exp = expectation(description: "wait for load")
        var state: GameState!
        store.loadGame { result in
            switch result {
            case .success(let s):
                state = s
            case .failure(let error):
                XCTFail("\(error.localizedDescription)")
            }
            exp.fulfill()
        }
        return state
    }
}

final class MockGameManagerDelegate: GameManagerDelegate {
    var receivedActions: [NextAction] = []
    func update(_ action: NextAction) {
        receivedActions.append(action)
    }
}
