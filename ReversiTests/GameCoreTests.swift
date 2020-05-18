//
//  GameCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/09.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine
import ComposableArchitecture
import ComposableArchitectureTestSupport
import XCTest

@testable import Reversi

class AppCoreTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testGameStarted() {
        let store = anyTestStore(with: .intialState)
        store.assert(
            .send(.gameStarted),
            .receive(.loadGameResponse(.failure(.write(path: "", cause: nil)))),
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testResetTapped() {
        let testState = GameState(
            board: Board(), players: [.computer, .computer], turn: .light, shouldSkip: true,
            currentTapPosition: nil)
        let store = anyTestStore(with: testState)
        store.assert(
            .send(.gameStarted),
            .receive(.loadGameResponse(.failure(.write(path: "", cause: nil)))) {
                $0 = GameState.intialState
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved))),
            .send(.resetTapped) { $0 = GameState.intialState },
            // mapで繋いだactionは検知できない
            // .receive(.saveGame),
            // .receive(.saveGameResponse(.success(.saved))),
            .do {
                self.scheduler.run()
            },
            .receive(.gameStarted),
            .receive(.loadGameResponse(.success(.loaded(GameState.intialState)))),
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testTurnPassed() {
        var testState = GameState.intialState
        testState.board = fullfillForPassed(
            width: Rule.width, height: Rule.height)

        let diskPlacedPosition = DiskPosition(x: 0, y: 0)
        let store = anyTestStore(with: testState)
        store.assert(
            .send(.manualPlayerDiskPlaced(diskPlacedPosition)),
            .receive(.placeDisk(diskPlacedPosition)),
            .do { self.scheduler.advance() },
            .receive(.updateState(testState)) {
                $0.shouldSkip = true
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved))),
            .send(.turnSkipped) {
                $0.shouldSkip = false
                $0.turn = .light
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testWonThenGameEnd() {
        var testState = GameState.intialState
        testState.board = fullfillForPassed(
            width: Rule.width, height: Rule.height)
        testState.turn = .light

        let diskPlacedPosition = DiskPosition(x: 0, y: 0)
        let store = anyTestStore(with: testState)
        store.assert(
            .send(.manualPlayerDiskPlaced(diskPlacedPosition)) {
                // この時点ではまだ値の更新はされていない
                XCTAssertNil($0.board.diskAt(x: diskPlacedPosition.x, y: diskPlacedPosition.y))
            },
            .receive(.placeDisk(diskPlacedPosition)),
            // mainQueueでupdateStateを行っているためmainQueueを勧める必要がある
            .do { self.scheduler.advance() },
            .receive(
                .updateState(
                    .init(
                        board: testState.board, players: testState.players, turn: .dark,
                        shouldSkip: false, currentTapPosition: diskPlacedPosition))
            ) {
                // この時点では値は更新はされる
                XCTAssertNotNil($0.board.diskAt(x: diskPlacedPosition.x, y: diskPlacedPosition.y))
                $0.turn = nil
                $0.currentTapPosition = nil
                XCTAssertEqual($0.board.sideWithMoreDisks(), .dark)
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testTiedThenGameEnd() {
        var testState = GameState.intialState
        testState.board = fullfillForTied(
            width: Rule.width, height: Rule.height)
        let diskPlacedPosition = DiskPosition(x: 0, y: 0)
        let store = anyTestStore(with: testState)
        store.assert(
            .send(.manualPlayerDiskPlaced(diskPlacedPosition)),
            .receive(.placeDisk(diskPlacedPosition)),
            .do { self.scheduler.advance() },
            .receive(.updateState(testState)) {
                $0.turn = nil
                $0.currentTapPosition = nil
                XCTAssertEqual($0.board.sideWithMoreDisks(), nil)
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testComputerPlay() {
        let diskPlacedPosition = DiskPosition(x: 2, y: 3)
        let testState = GameState.intialState
        let store = anyTestStore(with: testState)
        store.assert(
            .environment {
                $0.computer = { _, _ in Effect(value: diskPlacedPosition) }
            },
            .send(.computerPlay) {
                $0.playingAsComputer = .dark
            },
            .do { self.scheduler.run() },
            .receive(.computerPlayResponse(diskPlacedPosition)),
            .receive(.placeDisk(diskPlacedPosition)),
            .do { self.scheduler.advance() },
            .receive(
                .updateState(
                    .init(
                        board: testState.board,
                        players: testState.players,
                        turn: .light,
                        shouldSkip: false,
                        currentTapPosition: diskPlacedPosition,
                        playingAsComputer: .dark))
            ) {
                $0.currentTapPosition = diskPlacedPosition
                $0.turn = .light
                $0.playingAsComputer = nil
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testComputerPlayedThenGameEndByTied() {
        var testState = GameState.intialState
        testState.board = fullfillForTied(
            width: Rule.width, height: Rule.height)
        testState.turn = .light
        let diskPlacedPosition = DiskPosition(x: 0, y: 0)
        let store = anyTestStore(with: testState)
        store.assert(
            .environment {
                $0.computer = { _, _ in Effect(value: diskPlacedPosition) }
            },
            .send(.computerPlay) {
                $0.playingAsComputer = .light
            },
            .do { self.scheduler.run() },
            .receive(.computerPlayResponse(diskPlacedPosition)),
            .receive(.placeDisk(diskPlacedPosition)),
            .do { self.scheduler.run() },
            .receive(
                .updateState(
                    .init(
                        board: testState.board,
                        players: testState.players,
                        turn: .light,
                        shouldSkip: false,
                        currentTapPosition: nil,
                        playingAsComputer: .light))
            ) {
                $0.turn = nil
                $0.currentTapPosition = nil
                $0.playingAsComputer = nil
                XCTAssertEqual($0.board.sideWithMoreDisks(), nil)
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testComputerPlayedThenGameEndByWon() {
        var testState = GameState.intialState
        testState.board = fullfillForWon(
            width: Rule.width, height: Rule.height)
        testState.turn = .light
        let diskPlacedPosition = DiskPosition(x: 0, y: 0)
        let store = anyTestStore(with: testState)
        store.assert(
            .environment {
                $0.computer = { _, _ in Effect(value: diskPlacedPosition) }
            },
            .send(.computerPlay) {
                $0.playingAsComputer = .light
            },
            .do { self.scheduler.run() },
            .receive(.computerPlayResponse(diskPlacedPosition)),
            .receive(.placeDisk(diskPlacedPosition)),
            .do { self.scheduler.run() },
            .receive(
                .updateState(
                    .init(
                        board: testState.board,
                        players: testState.players,
                        turn: .light,
                        shouldSkip: false,
                        currentTapPosition: nil,
                        playingAsComputer: .light))
            ) {
                $0.turn = nil
                $0.currentTapPosition = nil
                $0.playingAsComputer = nil
                XCTAssertEqual($0.board.sideWithMoreDisks(), .dark)
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    // MARK: -Helpers

    private func anyTestStore(with state: GameState, function: String = #function) -> TestStore<
        GameState, GameState, GameAction, GameAction, GameEnvironment
    > {
        return TestStore(
            initialState: state,
            reducer: gameReducer,
            environment: GameEnvironment(
                computer: { _, _ in .fireAndForget {} },
                gameStateManager: GameStateManager.mock(id: function),
                mainQueue: scheduler.eraseToAnyScheduler()))
    }

    private func fullfillForWon(width: Int, height: Int) -> Board {
        let board = Board()
        for y in 0..<height {
            for x in 0..<width {
                board.setDisks(.dark, at: [.init(x: x, y: y)])
            }
        }
        return board
    }

    // 白黒均等にマスを全て埋める
    private func fullfillForTied(width: Int, height: Int) -> Board {
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

    // 黒が(0, 0)におけるマスのみ残して全てを埋める
    private func fullfillForPassed(width: Int, height: Int) -> Board {
        let lastX = width - 1
        let lastY = height - 1
        let board = Board()
        for y in 0..<height {
            for x in 0..<width {
                // 一箇所だけ隙間を空けておく
                if x == 0 && y == 0
                    || x == lastX && y == lastY
                {
                    continue
                }
                board.setDisks(.dark, at: [.init(x: x, y: y)])
            }
        }
        board.setDisks(.light, at: [.init(x: lastX, y: lastY)])
        return board
    }

}
