//
//  ViewModelTests.swift
//  ReversiTests
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest

@testable import Reversi

class ViewModelTests: XCTestCase {
    func testWhenCallSelectedCellThenSendValiadData() {
        let expected = Board.Position(x: 0, y: 0)
        let (viewModel, _, userActionDelegate) = makeTestTarget()
        viewModel.selectedCell(atX: expected.x, y: expected.y)
        XCTAssertEqual(userActionDelegate.placeDiskReceivedData.first!,
                       expected)
    }

    func testWhenCallChangedPlayerTypeThenSendValidData() {
        let expected = (type: PlayerType.manual, side: Disk.dark)
        let (viewModel, _, userActionDelegate) = makeTestTarget()
        viewModel.changedPlayerType(expected.type.rawValue, of: expected.side)

        guard let receivedData = userActionDelegate.changePlayerTypeReceivedData.first else {
            XCTFail("should set data")
            return
        }
        XCTAssertEqual(receivedData.type, expected.type)
        XCTAssertEqual(receivedData.side, expected.side)
    }

    func testWhenCallstartedGameThenSendValidData() {
        let expected = GameState(activePlayerDisk: .dark,
                                 players: defaultPlayers,
                                 board: Board())
        let (viewModel, delegate, _) = makeTestTarget()
        viewModel.startedGame(expected)

        XCTAssertEqual(delegate.setInitialDisksReceivedData?.disks,
                       expected.board.disks)
        delegate.setPlayerTypeReceivedData.enumerated().forEach { (index, received) in
            let (type, side) = received
            XCTAssertEqual(type, expected.players[index].type.rawValue)
            XCTAssertEqual(side, expected.players[index].side)
        }
    }

    private func makeTestTarget() -> (ViewModel, MockViewModelDelegate, MockUserActionDelegate) {
        let viewModel = ViewModel()
        let delegate = MockViewModelDelegate()
        viewModel.delegate = delegate
        let userActionDelegate = MockUserActionDelegate()
        viewModel.userActionDelegate = userActionDelegate
        return (viewModel, delegate, userActionDelegate)
    }
}

// MARK: ViewModelDelegate for test

final class MockViewModelDelegate: ViewModelDelegate {
    var setInitialDisksReceivedData: Board?
    func setInitialDisks(on board: Board) {
        setInitialDisksReceivedData = board
    }

    var setPlayerTypeReceivedData: [(type: Int, side: Disk)] = []
    func setPlayerType(_ type: Int, of side: Disk) {
        setPlayerTypeReceivedData.append((type, side))
    }

    var setDiskReceivedData: [(disk: Disk, x: Int, y: Int)] = []
    func setDisk(_ disk: Disk, atX x: Int, y: Int) {
        setDiskReceivedData.append((disk, x, y))
    }

    var movedTurnReceivedData: [GamePlayer] = []
    func movedTurn(to player: GamePlayer) {
        movedTurnReceivedData.append(player)
    }

    var passedTurnReceivedData: [GamePlayer] = []
    func passedTurn(of player: GamePlayer) {
        passedTurnReceivedData.append(player)
    }

    var finishedGameReceivedData: GamePlayer?
    func finishedGame(wonBy player: GamePlayer?) {
        finishedGameReceivedData = player
    }
}

// MARK: UserActionDelegate for test

final class MockUserActionDelegate: UserActionDelegate {
    var startGameCalled = false
    func startGame() {
        startGameCalled = true
    }

    var placeDiskReceivedData: [Board.Position] = []
    func placeDisk(at position: Board.Position) {
        placeDiskReceivedData.append(position)
    }

    var changePlayerTypeReceivedData: [(type: PlayerType, side: Disk)] = []
    func changePlayerType(_ type: PlayerType, of side: Disk) {
        changePlayerTypeReceivedData.append((type, side))
    }

    var goToNextTurnCalled = false
    func goToNextTurn() {
        goToNextTurnCalled = true
    }

    var resetGameCalled = false
    func resetGame() {
        resetGameCalled = true
    }
}
