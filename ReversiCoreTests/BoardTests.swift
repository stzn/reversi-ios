//
//  BoardTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import ReversiCore

class BoardTests: XCTestCase {
    func testWhenInitThenDisksAreEmpty() {
        let board = Board()
        XCTAssertTrue(board.disks.isEmpty)
    }

    func testWhenCallResetThenBoardIsInInitialState() {
        let board = Board()
        board.reset()
        let width = ReversiSpecification.width
        let height = ReversiSpecification.height
        XCTAssertEqual(board.diskAt(x: width / 2 - 1, y: height / 2 - 1), .light)
        XCTAssertEqual(board.diskAt(x: width / 2, y: height / 2 - 1), .dark)
        XCTAssertEqual(board.diskAt(x: width / 2 - 1, y: height / 2), .dark)
        XCTAssertEqual(board.diskAt(x: width / 2, y: height / 2), .light)
        XCTAssertEqual(board.countDisks(of: .light), 2)
        XCTAssertEqual(board.countDisks(of: .dark), 2)
    }

    func testWhenCallSetDiskThenDisksAreSetIfValid() {
        typealias TestCase = (line: UInt, x: Int, y: Int, expectedResult: Bool)

        let width = ReversiSpecification.width
        let height = ReversiSpecification.height

        let testCases: [TestCase] = [
            (#line, 0, 0, true),
            (#line, width - 1, 0, true),
            (#line, width - 1, height - 1, true),
            (#line, 0, height - 1, true),
            (#line, -1, 0, false),
            (#line, 0, -1, false),
            (#line, width, 0, false),
            (#line, width, height, false),
            (#line, 0, height, false),
        ]
        let board = Board()
        for testCase in testCases {
            let (line, x, y, expected) = testCase
            board.setDisk(.light, atX: x, y: y) { result in
                XCTAssertEqual(result, expected, line: line)
            }
        }
    }

    func testCallCountDisksThenDisksCountIsCorrect() {
        let board = Board()
        XCTAssertEqual(board.countDisks(of: .light), 0)
        XCTAssertEqual(board.countDisks(of: .dark), 0)

        board.setDisk(.light, atX: 0, y: 0)
        XCTAssertEqual(board.countDisks(of: .light), 1)
        XCTAssertEqual(board.countDisks(of: .dark), 0)

        board.setDisk(.dark, atX: 1, y: 0)
        XCTAssertEqual(board.countDisks(of: .light), 1)
        XCTAssertEqual(board.countDisks(of: .dark), 1)
    }

    func testCallSideMoreDisksThenReturnCorrectDiskType() {
        let board = Board()
        XCTAssertEqual(board.sideWithMoreDisks(), nil)

        board.setDisk(.light, atX: 0, y: 0)
        XCTAssertEqual(board.sideWithMoreDisks(), .light)

        board.setDisk(.dark, atX: 1, y: 0)
        XCTAssertEqual(board.sideWithMoreDisks(), nil)

        board.setDisk(.dark, atX: 2, y: 0)
        XCTAssertEqual(board.sideWithMoreDisks(), .dark)
    }
}
