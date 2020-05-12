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
        let store = TestStore(
            initialState: testState,
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

    func testPassTurn() {
        let board = fullfillForPassed(
            width: Rule.width, height: Rule.height)
        let testState = AppState(
            board: board,
            players: [.manual, .manual],
            turn: .dark, shouldSkip: false,
            currentTapPosition: DiskPosition(x: 2, y: 2))
        let store = TestStore(
            initialState: testState,
            reducer: appReducer,
            environment: AppEnvironment(
                computer: { _, _ in
                    Effect(value: DiskPosition(x: 1, y: 0))
                        .delay(for: 1.0, scheduler: self.scheduler)
                        .eraseToEffect()
                },
                gameStateManager: InMemoryGameStateManager(),
                mainQueue: scheduler.eraseToAnyScheduler()))
        store.assert(
            .send(.manualPlayerDiskPlaced(.init(x: 0, y: 0))),
            .receive(.placeDisk(.init(x: 0, y: 0))),
            .do { self.scheduler.advance() },
            .receive(.updateState(testState)) {
                $0.shouldSkip = true
            },
            .receive(.saveGame),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }

    private func fullfillForPassed(width: Int, height: Int) -> Board {
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

}
