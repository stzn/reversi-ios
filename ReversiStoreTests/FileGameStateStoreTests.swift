//
//  FileGameStateStoreTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//
import ReversiCore
import XCTest

@testable import ReversiStore

class FileGameStateStoreTests: XCTestCase {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            as NSString).appendingPathComponent("Test")
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        delete(path: path)
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

    func testWhenLoadGameWithStoredDataThenDataGot() {
        let store = makeTestFileGameStore()
        let saveData = anyGameState
        let saveResult = save(data: saveData, to: store)
        if case .failure = saveResult {
            XCTFail("expected success, but got \(saveResult)")
        }

        let loadResult = load(from: store)
        if case .success(let storedData) = loadResult {
            XCTAssertEqual(storedData.isEqual(saveData), true)
        }
    }

    func testWhenSaveGameWithErrorThenProvideErrorResult() {
        let invalidPath = ""
        let store = FileGameStateStore(path: invalidPath)
        let result = save(data: anyGameState, to: store)

        switch result {
        case .success:
            XCTFail("expected failure, but got \(result)")
        case .failure(let error):
            XCTAssertTrue(error is FileGameStateStore.FileIOError)
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
            turn: data.activePlayerSide,
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

    private func delete(path: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try! fileManager.removeItem(atPath: path)
        }
    }
}

extension GameState {
    func isEqual(_ other: GameState) -> Bool {
        return self.board.disks == other.board.disks
            && self.activePlayerSide == other.activePlayerSide
            && self.players == other.players
    }
}
