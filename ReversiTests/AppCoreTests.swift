//
//  AppCoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/05/09.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine
import XCTest
import ComposableArchitecture
import ComposableArchitectureTestSupport

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
    func testInitState() {
        let store = TestStore(initialState: AppState.intialState,
                              reducer: appReducer,
                              environment: AppEnvironment(
                                computer: { _,_  in Effect(value: DiskPosition(x: 0, y: 0))
                                    .delay(for: 1.0, scheduler: self.scheduler)
                                    .eraseToEffect() },
                                gameStateManager: InMemoryGameStateManager(),
                                mainQueue: scheduler.eraseToAnyScheduler()))
        store.assert(
            .send(.gameStarted),
            .receive(.loadGameResponse(.failure(.write(path: "", cause: nil)))),
            .receive(.saveGameResponse(.success(.saved)))
        )
    }
}
