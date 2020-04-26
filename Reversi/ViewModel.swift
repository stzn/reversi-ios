//
//  ViewModel.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol ViewModelDelegate: AnyObject {
    func setInitialDisks(on board: Board)
    func setPlayerType(_ type: Int, of side: Disk)
    func setDisk(_ disk: Disk, atX x: Int, y: Int)
    func movedTurn(to player: GamePlayer)
    func passedTurn(of player: GamePlayer)
    func finishedGame(wonBy player: GamePlayer?)
}

final class ViewModel {
    weak var userActionDelegate: UserActionDelegate?
    weak var delegate: ViewModelDelegate?

    func requestGameStart() {
        userActionDelegate?.startGame()
    }

    func selectedCell(atX x: Int, y: Int) {
        userActionDelegate?.placeDisk(at: Board.Position(x: x, y: y))
    }

    func changedPlayerType(_ type: Int, of side: Disk) {
        guard let player = PlayerType(rawValue: type) else {
            preconditionFailure("invalid index")
        }
        userActionDelegate?.changePlayerType(player, of: side)
    }

    func requestNextTurn() {
        userActionDelegate?.goToNextTurn()
    }

    func requestGameReset() {
        userActionDelegate?.resetGame()
    }
}

extension ViewModel: GameManagerDelegate {
    func startedGame(_ state: GameState) {
        delegate?.setInitialDisks(on: state.board)
        state.players.forEach { player in
            delegate?.setPlayerType(player.type.rawValue, of: player.side)
        }
    }

    func setDisk(_ disk: Disk, at position: Board.Position) {
        delegate?.setDisk(disk, atX: position.x, y: position.y)
    }

    func movedTurn(to player: GamePlayer) {
        delegate?.movedTurn(to: player)
    }

    func passedTurn(of player: GamePlayer) {
        delegate?.passedTurn(of: player)
    }

    func finishedGame(wonBy player: GamePlayer?) {
        delegate?.finishedGame(wonBy: player)
    }
}
