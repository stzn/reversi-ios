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

    func testWhenNewGameStartAndLeftOnlyOnePlacableDiskThenPassedPlayer() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        fullfillForPassed(store: store, width: width, height: height)
        let viewController = composeViewController(store: store, viewModel: viewModel)
        (UIApplication.shared.connectedScenes.first!.delegate as? UIWindowSceneDelegate)?
            .window??.rootViewController = viewController

        viewModel.requestNextTurn()

        XCTAssertNotNil(viewController.presentedViewController)
    }

    private func viewDidAppear(_ viewController: ViewController) {
        viewController.loadViewIfNeeded()
        viewController.beginAppearanceTransition(false, animated: false)
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

    private func fullfillForWon(store: GameStateStore,
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

    private func fullfillForTied(store: GameStateStore,
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

    private func fullfillForPassed(store: GameStateStore,
              width: Int, height: Int) {
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
        let exp = expectation(description: "wait for save")
        store.saveGame(turn: .light, players: defaultPlayers, board: board) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func deleteGame() {
        let path = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
            as NSString).appendingPathComponent("Game")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try! fileManager.removeItem(atPath: path)
        }
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
