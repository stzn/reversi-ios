//
//  FileGameStateStoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import Reversi

class FileGameStateStoreTests: XCTestCase {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            as NSString).appendingPathComponent("Test")
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
    }

    func testWhenLoadGameWithoutStoredDataThenNoDataGot() {
        let store = makeTestFileGameStore()
        let result = load(from: store)
        if case .success = result {
            XCTFail("expected failure, but got \(result)")
        }
    }

    func testWhenLoadGameWithStoredDataThenNoDataGot() {
        let store = makeTestFileGameStore()
        let saveData = GameState(
            activePlayerDisk: .dark,
            players: defaultPlayers,
            board: Board())
        let saveResult = save(data: saveData, to: store)
        if case .failure = saveResult {
            XCTFail("expected success, but got \(saveResult)")
        }

        let loadResult = load(from: store)
        if case .success(let storedData) = loadResult {
            XCTAssertEqual(storedData.isEqual(saveData), true)
        }
    }

    private func makeTestFileGameStore() -> FileGameStateStore {
        return FileGameStateStore(path: path)
    }

    private func save(data: GameState, to store: FileGameStateStore) -> Result<Void, Error> {
        var result: Result<Void, Error> =
            .failure(FileGameStateStore.FileIOError.write(path: path, cause: nil))
        let exp = expectation(description: "wait for save")
        store.saveGame(
            turn: data.activePlayerDisk,
            players: data.players,
            board: data.board
        ) {
            result = $0
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return result
    }

    private func load(from store: FileGameStateStore) -> Result<GameState, Error> {
        var result: Result<GameState, Error> =
            .failure(FileGameStateStore.FileIOError.read(path: path, cause: nil))
        let exp = expectation(description: "wait for load")
        store.loadGame {
            result = $0
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return result
    }
}

extension GameState {
    func isEqual(_ other: GameState) -> Bool {
        return self.board.disks == other.board.disks
            && self.activePlayerDisk.index == other.activePlayerDisk.index
            && self.players == other.players
    }
}
