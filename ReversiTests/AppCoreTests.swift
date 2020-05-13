//
//  AppCoreTests.swift
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

final class InMemoryGameStateManager: GameStateManager {
    var savedState: AppState?
    func saveGame(state: AppState) -> Effect<GameStateSaveAction, GameStateManagerError> {
        savedState = state
        return Effect(value: GameStateSaveAction.saved)
    }

    func loadGame() -> Effect<GameStateLoadAction, GameStateManagerError> {
        guard let state = savedState else {
            return Effect(error: .write(path: "", cause: nil))
        }
        return Effect(value: GameStateLoadAction.loaded(state))
    }
}

class AppCoreTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler
    func testGameStarted() {
        let store = TestStore(
            initialState: AppState.intialState,
            reducer: appReducer,
            environment: AppEnvironment(
                computer: { _, _ in
                    Effect(value: DiskPosition(x: 0, y: 0))
                        .delay(for: 1.0, scheduler: self.scheduler)
                        .eraseToEffect()
                },
                gameStateManager: InMemoryGameStateManager(),
                mainQueue: scheduler.eraseToAnyScheduler()))
        store.assert(
            .send(.gameStarted),
            .receive(.loadGameResponse(.failure(.write(path: "", cause: nil)))),
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testResetTapped() {
        let testState = AppState(
            board: Board(), players: [.computer, .computer], turn: .light, shouldSkip: true,
            currentTapPosition: nil)
        let store = anyTestStore(with: testState)
        store.assert(
            .send(.gameStarted),
            .receive(.loadGameResponse(.failure(.write(path: "", cause: nil)))) {
                $0 = AppState.intialState
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved))),
            .send(.resetTapped) { $0 = AppState.intialState },
            // AppCode.swift参照
            // .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved))),
            .receive(.gameStarted),
            .receive(.loadGameResponse(.success(.loaded(AppState.intialState)))),
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testTurnPassedThenGameEnd() {
        var testState = AppState.intialState
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
        var testState = AppState.intialState
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
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    func testTiedThenGameEnd() {
        var testState = AppState.intialState
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
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    // TODO: コンピュータのテスト
    // TODO: environmentのテスト

    // MARK: -Helpers

    private func anyTestStore(with state: AppState) -> TestStore<
        AppState, AppState, AppAction, AppAction, AppEnvironment
    > {
        return TestStore(
            initialState: state,
            reducer: appReducer,
            environment: AppEnvironment(
                computer: { _, _ in .fireAndForget {} },
                gameStateManager: InMemoryGameStateManager(),
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
