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
    func testWhenNewGameAndPlaceDiskAtValidPoasionThenPlacedDisk() {
        typealias TestCase = (UInt, Disk, Int, Int)

        let viewController = composeViewController()
        viewDidAppear(viewController)
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
            viewController.placeDisk(disk, atX: x, y: y, animated: false) { _ in
                XCTAssertNotNil(viewController.boardView.diskAt(x: x, y: y), line: line)
            }
        }
    }

    func testWhenNewGameAndPlaceDiskAtInValidPoasionThenNotPlacedDisk() {
        typealias TestCase = (UInt, Disk, Int, Int)

        let viewController = composeViewController()
        viewDidAppear(viewController)

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
            viewController.placeDisk(disk, atX: x, y: y, animated: false) { _ in
                XCTAssertNil(viewController.boardView.diskAt(x: x, y: y), line: line)
            }
        }
    }

//    func testWhenChangePlayerTypeThenPlayerTypeChanged() {
//        let viewController = composeViewController()
//        viewDidAppear(viewController)
//
//        let index = viewController.playerControls[Disk.dark.index].selectedSegmentIndex
//        let playerType = PlayerType(rawValue: index)!
//
//        viewController.changePlayer(index: index)
//        XCTAssertEqual(viewController.playerControls[Disk.dark.index].selectedSegmentIndex,
//                       playerType.flipped.rawValue)
//    }

    func testWhenResetThenGameWasInInitialState() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        fullfillForWon(store: store,
                       width: width, height: height)
        let viewController = composeViewController(store: store,
                                                   viewModel: viewModel)
        viewDidAppear(viewController)
        viewModel.requestGameReset()
        initialPlacedDisks.forEach { (x, y) in
            XCTAssertNotNil(viewController.boardView.diskAt(x: x, y: y))
        }
    }

    func testWhenNewGameStartAndAllDiskPlacedThenGameEnded() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        fullfillForWon(store: store, width: width, height: height)
        let viewController = composeViewController(store: store, viewModel: viewModel)
        viewDidAppear(viewController)

        viewModel.requestNextTurn()

        XCTAssertEqual(viewController.messageLabel.text, " won")
    }

    func testWhenNewGameStartAndAllDiskPlacedThenGameTied() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        fullfillForTied(store: store, width: width, height: height)
        let viewController = composeViewController(store: store, viewModel: viewModel)
        viewDidAppear(viewController)

        viewModel.requestNextTurn()

        XCTAssertEqual(viewController.messageLabel.text, "Tied")
    }

    private func viewDidAppear(_ viewController: ViewController) {
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
    }

    private func composeViewController(
        store: GameStateStore = InMemoryGameStateStore(),
        viewModel: ViewModel = ViewModel()
    ) -> ViewController {
        let gameManager = GameManager(store: store)
        viewModel.userActionDelegate = gameManager
        gameManager.delegate = viewModel
        return ViewController.instantiate(viewModel: viewModel)
    }

    /// 盤の幅（ `8` ）を表します。
    private let width: Int = 8

    /// 盤の高さ（ `8` ）を返します。
    private let height: Int = 8

    private let initialPlacedDisks: [(x: Int, y: Int)] =
        [
            (x: ReversiSpecification.width / 2 - 1, y: ReversiSpecification.height / 2 - 1),
            (x: ReversiSpecification.width / 2, y: ReversiSpecification.height / 2 - 1),
            (x: ReversiSpecification.width / 2 - 1, y: ReversiSpecification.height / 2),
            (x: ReversiSpecification.width / 2, y: ReversiSpecification.height / 2),
        ]

    func fullfillForWon(store: GameStateStore,
              width: Int, height: Int) {
        let board = Board()
        for y in 0..<height {
            for x in 0..<width {
                board.setDisks(.dark, at: [.init(x: x, y: y)])
            }
        }
        let exp = expectation(description: "wait for save")
        store.saveGame(turn: .dark, players: defaultPlayers, board: board) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func fullfillForTied(store: GameStateStore,
              width: Int, height: Int) {
        let board = Board()
        var turn: Disk = .dark
        for y in 0..<height {
            for x in 0..<width {
                board.setDisks(turn, at: [.init(x: x, y: y)])
                turn = turn.flipped
            }
        }
        let exp = expectation(description: "wait for save")
        store.saveGame(turn: .dark, players: defaultPlayers, board: board) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

extension ViewController {
    func changePlayer(index: Int) {
        playerControls[index].simulateValueChanged()
    }
}

extension PlayerType {
    var flipped: PlayerType {
        switch self {
        case .manual:
            return .computer
        case .computer:
            return .manual
        }
    }
}
