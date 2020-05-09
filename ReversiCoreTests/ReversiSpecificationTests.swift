//
//  ReversiLogicTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import ReversiCore

class RuleTests: XCTestCase {
    func testWhenPlaceDiskOnValidPlaceThenCanPlaceDisk() {
        typealias TestCase = (line: UInt, x: Int, y: Int, disk: Disk, expectedResult: Bool)
        let board = Board()

        let edge = Board.Position(x: 0, y: 0)
        do {
            board.setDisk(.light, atX: edge.x, y: edge.y)
            board.setDisk(.dark, atX: edge.x + 1, y: edge.y)
            board.setDisk(.dark, atX: edge.x, y: edge.y + 1)
            board.setDisk(.dark, atX: edge.x + 1, y: edge.y + 1)
        }

        let center = Board.Position(
            x: Rule.width / 2,
            y: Rule.height / 2)
        do {
            board.setDisk(.dark, atX: center.x, y: center.y)
            board.setDisk(.light, atX: center.x + 1, y: center.y)
            board.setDisk(.light, atX: center.x, y: center.y + 1)
            board.setDisk(.light, atX: center.x - 1, y: center.y)
            board.setDisk(.light, atX: center.x, y: center.y - 1)
            board.setDisk(.light, atX: center.x + 1, y: center.y + 1)
            board.setDisk(.light, atX: center.x + 1, y: center.y - 1)
            board.setDisk(.light, atX: center.x - 1, y: center.y + 1)
            board.setDisk(.light, atX: center.x - 1, y: center.y - 1)
        }

        let testCases: [TestCase] = [
            (#line, edge.x + 2, edge.y, .light, true),
            (#line, edge.x, edge.y + 2, .light, true),
            (#line, edge.x + 2, edge.y + 2, .light, true),

            (#line, center.x + 2, center.y, .dark, true),
            (#line, center.x, center.y + 2, .dark, true),
            (#line, center.x, center.y - 2, .dark, true),
            (#line, center.x - 2, center.y, .dark, true),
            (#line, center.x + 2, center.y + 2, .dark, true),
            (#line, center.x - 2, center.y - 2, .dark, true),

            // wrong disk type
            (#line, edge.x + 2, edge.y, .dark, false),
            (#line, edge.x, edge.y + 2, .dark, false),
            (#line, edge.x + 3, edge.y + 3, .dark, false),

            (#line, center.x + 2, center.y, .light, false),
            (#line, center.x, center.y + 2, .light, false),
            (#line, center.x, center.y - 2, .light, false),
            (#line, center.x - 2, center.y, .light, false),
            (#line, center.x + 3, center.y + 3, .light, false),
            (#line, center.x - 3, center.y - 3, .light, false),

            // duplicate position
            (#line, edge.x, edge.y, .dark, false),
            (#line, center.x, center.y, .light, false),
        ]

        for testCase in testCases {
            let (line, x, y, disk, expected) = testCase
            XCTAssertEqual(
                Rule.canPlaceDisk(disk, atX: x, y: y, on: board),
                expected,
                line: line)
        }
    }
}
