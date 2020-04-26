//
//  ViewModel.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol ViewModelDelegate: AnyObject {
    func setInitialState(_ state: GameState)
    func setPlayerType(_ type: Int, of side: Disk)
    func setDisk(_ disk: Disk, atX x: Int, y: Int, on board: Board)
    func movedTurn(to player: GamePlayer)
    func passedTurn(of player: GamePlayer)
    func finishedGame(wonBy player: GamePlayer?)
    func startedComputerTurn(of player: GamePlayer)
    func endedComputerTurn(of player: GamePlayer)
}

final class ViewModel {
    weak var userActionDelegate: UserActionDelegate?
    weak var delegate: ViewModelDelegate?

    /// 非同期処理のキャンセルを管理します。
    private var playerCancellers: [GamePlayer: Canceller] = [:]

    func requestGameStart() {
        userActionDelegate?.requestStartGame()
    }

    func selectedCell(atX x: Int, y: Int, of side: Disk) {
        userActionDelegate?.placeDisk(at: Board.Position(x: x, y: y), of: side)
    }

    func changedPlayerType(_ type: Int, of side: Disk) {
        guard let player = PlayerType(rawValue: type) else {
            preconditionFailure("invalid index")
        }
        userActionDelegate?.changePlayerType(player, of: side)
    }

    func requestNextTurn() {
        userActionDelegate?.requestNextTurn()
    }

    func requestGameReset() {
        userActionDelegate?.requestResetGame()
    }
}

// MARK: User Action

extension ViewModel {
    /// プレイヤーの行動を待ちます。
    private func waitForPlayer(_ player: GamePlayer, on board: Board) {
        switch player.type {
        case .manual:
            break
        case .computer:
            let canceller = playTurnOfComputer(player) { [weak self] in
                guard let self = self else { return }
                self.setDiskAtRandom(by: player, on: board)
            }
            playerCancellers[player] = canceller
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer(_ player: GamePlayer, action: @escaping () -> Void) -> Canceller {
        self.delegate?.startedComputerTurn(of: player)
        let cleanUp: () -> Void = { [weak self, player] in
            guard let self = self else { return }
            self.delegate?.endedComputerTurn(of: player)
            self.playerCancellers[player] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if canceller.isCancelled { return }
            cleanUp()
            action()
        }
        return canceller
    }

    private func setDiskAtRandom(by player: GamePlayer, on board: Board) {
        let (x, y) =
            ReversiSpecification
            .validMoves(for: player.side, on: board)
            .randomElement()!
        self.delegate?.setDisk(player.side, atX: x, y: y, on: board)
    }

    private func resettedGame() {
        playerCancellers.forEach { (player, canceller) in
            canceller.cancel()
            playerCancellers[player] = nil
        }
    }
}

extension ViewModel: GameManagerDelegate {
    func update(_ action: NextAction) {
        switch action {
        case .start(let state):
            self.delegate?.setInitialState(state)
        case let .set(disk, position, board):
            self.delegate?.setDisk(disk, atX: position.x, y: position.y, on: board)
        case .next(let player, let board):
            self.delegate?.movedTurn(to: player)
            self.waitForPlayer(player, on: board)
        case .pass(let player):
            self.delegate?.passedTurn(of: player)
        case .finish(let winner):
            self.delegate?.finishedGame(wonBy: winner)
        case .reset:
            self.resettedGame()
        }
    }
}
