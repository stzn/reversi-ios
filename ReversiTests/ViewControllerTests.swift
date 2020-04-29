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
            (#line, .light, boardWidth / 2 - 2, boardHeight / 2),
            (#line, .light, boardWidth / 2, boardHeight / 2 - 2),
            (#line, .light, boardWidth / 2 + 1, boardHeight / 2 - 1),
            (#line, .light, boardWidth / 2 - 1, boardHeight / 2 + 1),
            (#line, .dark, boardWidth / 2 + 1, boardHeight / 2),
            (#line, .dark, boardWidth / 2, boardHeight / 2 + 1),
            (#line, .dark, boardWidth / 2 - 1, boardHeight / 2 - 2),
            (#line, .dark, boardWidth / 2 - 2, boardHeight / 2 - 1),
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
            (#line, .dark, boardWidth / 2 - 2, boardHeight / 2),
            (#line, .dark, boardWidth / 2, boardHeight / 2 - 2),
            (#line, .dark, boardWidth / 2 + 1, boardHeight / 2 - 1),
            (#line, .dark, boardWidth / 2 - 1, boardHeight / 2 + 1),
            (#line, .light, boardWidth / 2 + 1, boardHeight / 2),
            (#line, .light, boardWidth / 2, boardHeight / 2 + 1),
            (#line, .light, boardWidth / 2 - 1, boardHeight / 2 - 2),
            (#line, .light, boardWidth / 2 - 2, boardHeight / 2 - 1),

            (#line, .dark, boardWidth / 2, boardHeight / 2),
            (#line, .dark, boardWidth / 2 - 1, boardHeight / 2 - 1),
            (#line, .light, boardWidth / 2 - 1, boardHeight / 2),
            (#line, .light, boardWidth / 2, boardHeight / 2 - 1),
        ]

        for testCase in testCases {
            let (line, disk, x, y) = testCase
            viewController.placeDisk(disk, atX: x, y: y, animated: false) { _ in
                XCTAssertNil(viewController.boardView.diskAt(x: x, y: y), line: line)
            }
        }
    }

    func testWhenChangePlayerTypeThenPlayerTypeChanged() {
        let store = InMemoryGameStateStore()
        let viewController = composeViewController(store: store)

        viewDidAppear(viewController)

        let playerControl = viewController.playerControls[Disk.dark.index]
        let index = playerControl.selectedSegmentIndex
        let playerType = PlayerType(rawValue: index)!

        playerControl.selectedSegmentIndex = playerType.flipped.rawValue
        playerControl.sendActions(for: .valueChanged)

        store.loadGame { result in
            switch result {
            case .success(let state):
                XCTAssertEqual(state.players[Disk.dark.index].type,
                               PlayerType(rawValue: playerType.flipped.rawValue))
            case .failure:
                XCTFail("should be success")
            }
        }
    }

    func testWhenResetThenGameWasInInitialState() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        let board = fullfillForWon(width: boardWidth, height: boardHeight)
        save(to: store,
             state: .init(activePlayerSide: .dark, players: defaultPlayers, board: board))
        let viewController = composeViewController(store: store,
                                                   viewModel: viewModel)
        viewDidAppear(viewController)
        viewModel.requestGameReset()
        initialPlacedDisks.forEach { (position, disk) in
            XCTAssertEqual(viewController.boardView.diskAt(x: position.x, y: position.y), disk)
        }
    }

    func testWhenNewGameStartAndAllDiskPlacedThenGameEnded() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        let board = fullfillForWon(width: boardWidth, height: boardHeight)
        save(to: store,
             state: .init(activePlayerSide: .dark, players: defaultPlayers, board: board))
        let viewController = composeViewController(store: store, viewModel: viewModel)
        viewDidAppear(viewController)

        viewModel.requestNextTurn()

        XCTAssertEqual(viewController.messageLabel.text, " won")
    }

    func testWhenNewGameStartAndAllDiskPlacedThenGameTied() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        let board = fullfillForTied(width: boardWidth, height: boardHeight)
        save(to: store,
             state: .init(activePlayerSide: .dark, players: defaultPlayers, board: board))
        let viewController = composeViewController(store: store, viewModel: viewModel)
        viewDidAppear(viewController)

        viewModel.requestNextTurn()

        XCTAssertEqual(viewController.messageLabel.text, "Tied")
    }

    func testWhenNewGameStartAndLeftOnlyOnePlacableDiskThenPassedPlayer() {
        let viewModel = ViewModel()
        let store = InMemoryGameStateStore()
        let board = fullfillForPassed(width: boardWidth, height: boardHeight)
        save(to: store,
             state: .init(activePlayerSide: .light, players: defaultPlayers, board: board))
        let viewController = composeViewController(store: store, viewModel: viewModel)

        (UIApplication.shared.connectedScenes.first!.delegate as? UIWindowSceneDelegate)?
            .window??.rootViewController = viewController

        viewModel.requestNextTurn()

        XCTAssertNotNil(viewController.presentedViewController)
    }

    // MARK: Helpers

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
