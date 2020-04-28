//
//  ViewControllerTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/27.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import Reversi

class ViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        deleteGame()
    }

    func testWhenNewGameAndPlaceDiskAtValidPoasionThenPlacedDisk() {
        typealias TestCase = (UInt, Disk, Int, Int)

        let viewController = makeAndShowViewController()
        let testCases: [TestCase] = [
            (#line, .light, width / 2 - 2, height / 2),
            (#line, .light, width / 2, height / 2 - 2),
            (#line, .light, width / 2 + 1, height / 2 - 1),
            (#line, .light, width / 2 - 1, height / 2 + 1),
            (#line, .dark, width / 2 + 1, height / 2),
            (#line, .dark, width / 2, height / 2 + 1),
            (#line, .dark, width / 2 - 1, height / 2 - 2),
            (#line, .dark, width / 2 - 2, height / 2 - 1),
        ]

        for testCase in testCases {
            let (line, disk, x, y) = testCase
            do {
                try
                    viewController.placeDisk(disk, atX: x, y: y, animated: false)
            } catch {
                XCTFail("\(error)", line: line)
            }
        }
    }

    func testWhenNewGameAndPlaceDiskAtInValidPoasionThenNotPlacedDisk() {
        typealias TestCase = (UInt, Disk, Int, Int)

        let viewController = makeAndShowViewController()
        let testCases: [TestCase] = [
            (#line, .dark, width / 2 - 2, height / 2),
            (#line, .dark, width / 2, height / 2 - 2),
            (#line, .dark, width / 2 + 1, height / 2 - 1),
            (#line, .dark, width / 2 - 1, height / 2 + 1),
            (#line, .light, width / 2 + 1, height / 2),
            (#line, .light, width / 2, height / 2 + 1),
            (#line, .light, width / 2 - 1, height / 2 - 2),
            (#line, .light, width / 2 - 2, height / 2 - 1),

            (#line, .dark, width / 2, height / 2),
            (#line, .dark, width / 2 - 1, height / 2 - 1),
            (#line, .light, width / 2 - 1, height / 2),
            (#line, .light, width / 2, height / 2 - 1),
        ]

        for testCase in testCases {
            let (line, disk, x, y) = testCase
            do {
                try
                    viewController
                    .placeDisk(disk, atX: x, y: y, animated: false)
                XCTFail("should fail", line: line)
            } catch {
                XCTAssertTrue(error is DiskPlacementError)
            }
        }
    }

    func testWhenNewGameStartAndPlaceDiskThenTurnChanged() {
        let viewController = makeAndShowViewController()

        XCTAssertEqual(viewController.turn, .dark)

        try!
            viewController
            .placeDisk(.dark, atX: width / 2 + 1, y: height / 2, animated: false)
        viewController.nextTurn()

        XCTAssertEqual(viewController.turn, .light)
    }

    func testWhenNewGameStartAndAllDiskPlacedThenGameEnded() {
        let viewController = makeAndShowViewController()
        fullfill(of: viewController, width: width, height: height)
        let darkCount = viewController.countDisks(of: .dark)
        let lightCount = viewController.countDisks(of: .light)
        let winner = viewController.sideWithMoreDisks()
        if darkCount == lightCount {
            XCTAssertNil(winner)
        } else {
            XCTAssertNotNil(winner)
        }
    }

    func testWhenResetThenGameWasInInitialState() {
        let viewController = makeAndShowViewController()
        fullfill(of: viewController, width: width, height: height)
        viewController.newGame()
        let darkCount = viewController.countDisks(of: .dark)
        let lightCount = viewController.countDisks(of: .light)
        XCTAssertEqual(darkCount, 2)
        XCTAssertEqual(lightCount, 2)
        XCTAssertEqual(viewController.turn, .dark)
    }

    private func makeAndShowViewController() -> ViewController {
        guard
            let viewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateInitialViewController() as? ViewController
        else {
            fatalError("must not be nil")
        }
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
        return viewController
    }

    /// 盤の幅（ `8` ）を表します。
    private let width: Int = 8

    /// 盤の高さ（ `8` ）を返します。
    private let height: Int = 8

    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
            as NSString).appendingPathComponent("Game")
    }

    func deleteGame() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try! fileManager.removeItem(atPath: path)
        }
    }

    func fullfill(of viewController: ViewController, width: Int, height: Int) {
        while let turn = viewController.turn {
            guard let (x, y) = viewController.validMoves(for: turn).randomElement() else {
                break
            }
            let exp = expectation(description: "wait for next turn")
            do {
                try viewController.placeDisk(turn, atX: x, y: y, animated: false) { _ in
                    viewController.nextTurn()
                    exp.fulfill()
                }
            } catch {
                exp.fulfill()
                break
            }
            wait(for: [exp], timeout: 1.0)
        }
    }

}
