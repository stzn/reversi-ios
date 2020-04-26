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

        viewModel.selectedCell(atX: expected.x, y: expected.y, of: .dark)

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

    func testWhenCallRequestNextTurnThenDelegateAction() {
        let (viewModel, _, userActionDelegate) = makeTestTarget()

        viewModel.requestNextTurn()
        XCTAssertEqual(userActionDelegate.requestNextTurnCalled, true)
    }

    func testWhenCallRequestResetGameThenDelegateAction() {
        let (viewModel, _, userActionDelegate) = makeTestTarget()

        viewModel.requestGameReset()
        XCTAssertEqual(userActionDelegate.requestResetGameCalled, true)
    }

    func testWhenCallStartActionThenSendValidData() {
        let expected = anyGameState
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.start(expected))

        XCTAssertEqual(delegate.setInitialStateReceivedData?.board.disks,
                       expected.board.disks)
        delegate.setPlayerTypeReceivedData.enumerated().forEach { (index, received) in
            let (type, side) = received
            XCTAssertEqual(type, expected.players[index].type.rawValue)
            XCTAssertEqual(side, expected.players[index].side)
        }
    }

    func testWhenCallSetActionThenSendValidData() {
        let expected = (disk: Disk.dark,
                        position: Board.Position(x: 0, y: 0),
                        board: Board())
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.set(expected.disk, expected.position, expected.board))

        let receivedData = delegate.setDiskReceivedData.first!
        XCTAssertEqual(receivedData.board.disks,
                       expected.board.disks)
        XCTAssertEqual(Board.Position(x: receivedData.x, y: receivedData.y),
                       expected.position)
        XCTAssertEqual(receivedData.disk,
                       expected.disk)
    }

    func testWhenCallNextActionThenSendValidData() {
        let expected = (player: defaultPlayers[0],
                        board: Board())
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.next(expected.player, expected.board))

        let receivedData = delegate.movedTurnReceivedData.first!
        XCTAssertEqual(receivedData, expected.player)
    }

    func testWhenCallPassActionThenSendValidData() {
        let expected = (player: defaultPlayers[0],
                        board: Board())
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.pass(expected.player))

        let receivedData = delegate.passedTurnReceivedData.first!
        XCTAssertEqual(receivedData, expected.player)
    }

    func testWhenCallFinishActionThenSendValidData() {
        let expected = defaultPlayers[0]
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.finish(expected))

        let receivedData = delegate.finishedGameReceivedData
        XCTAssertEqual(receivedData, expected)
    }

    func testWhenCallTiedFinishActionThenSendValidData() {
        let expected: GamePlayer? = nil
        let (viewModel, delegate, _) = makeTestTarget()

        viewModel.update(.finish(expected))

        let receivedData = delegate.finishedGameReceivedData
        XCTAssertEqual(receivedData, expected)
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
    var setInitialStateReceivedData: GameState?
    func setInitialState(_ state: GameState) {
        setInitialStateReceivedData = state
    }

    var setDiskReceivedData: [(disk: Disk, x: Int, y: Int, board: Board)] = []
    func setDisk(_ disk: Disk, atX x: Int, y: Int, on board: Board) {
        setDiskReceivedData.append((disk, x, y, board))
    }

    var startedComputerReceivedData: [GamePlayer] = []
    func startedComputerTurn(of player: GamePlayer) {
        startedComputerReceivedData.append(player)
    }

    var endedComputerReceivedData: [GamePlayer] = []
    func endedComputerTurn(of player: GamePlayer) {
        endedComputerReceivedData.append(player)
    }

    var setPlayerTypeReceivedData: [(type: Int, side: Disk)] = []
    func setPlayerType(_ type: Int, of side: Disk) {
        setPlayerTypeReceivedData.append((type, side))
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
    func requestStartGame() {
        startGameCalled = true
    }

    var placeDiskReceivedData: [Board.Position] = []
    func placeDisk(at position: Board.Position, of side: Disk) {
        placeDiskReceivedData.append(position)
    }

    var changePlayerTypeReceivedData: [(type: PlayerType, side: Disk)] = []
    func changePlayerType(_ type: PlayerType, of side: Disk) {
        changePlayerTypeReceivedData.append((type, side))
    }

    var requestNextTurnCalled = false
    func requestNextTurn() {
        requestNextTurnCalled = true
    }

    var requestResetGameCalled = false
    func requestResetGame() {
        requestResetGameCalled = true
    }
}
