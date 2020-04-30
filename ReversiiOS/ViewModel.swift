//
//  ViewModel.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ReversiCore

public protocol ViewModelDelegate: AnyObject {
    func setInitialState(_ state: GameState)
    func setPlayerType(_ type: Int, of side: Disk)
    func setDisk(_ disk: Disk, atX x: Int, y: Int, on board: Board)
    func movedTurn(to player: GamePlayer)
    func passedTurn()
    func finishedGame(wonBy player: GamePlayer?)
    func startedComputerTurn(of player: GamePlayer)
    func endedComputerTurn(of player: GamePlayer)
}

public final class ViewModel {
    public var userActionDelegate: UserActionDelegate?
    public weak var delegate: ViewModelDelegate?

    public init() {}
    
    /// 非同期処理のキャンセルを管理します。
    private var playerCancellers: [GamePlayer: Canceller] = [:]

    func requestGameStart() {
        userActionDelegate?.requestStartGame()
    }

    func selectedCell(for side: Disk, atX x: Int, y: Int) {
        do {
            try userActionDelegate?.placeDisk(at: Board.Position(x: x, y: y))
        } catch let error as DiskPlacementError {
            guard ReversiSpecification.canPlaceDisk(side, atX: x, y: y, on: error.on) else {
                return
            }
            userActionDelegate?.requestNextTurn()
        } catch {
            userActionDelegate?.requestNextTurn()
        }
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
    private func playTurnOfComputer(_ player: GamePlayer, action: @escaping () -> Void) -> Canceller
    {
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
        guard
            let (x, y) =
                ReversiSpecification
                .validMoves(for: player.side, on: board)
                .randomElement()
        else {
            delegate?.passedTurn()
            return
        }
        do {
            try userActionDelegate?.placeDisk(at: .init(x: x, y: y))
        } catch {
            userActionDelegate?.requestNextTurn()
        }
    }

    private func resettedGame(with state: GameState) {
        playerCancellers.forEach { (player, canceller) in
            canceller.cancel()
            playerCancellers[player] = nil
        }
        self.delegate?.setInitialState(state)
    }
}

extension ViewModel: GameManagerDelegate {
    public func update(_ action: NextAction) {
        switch action {
        case .start(let state):
            self.delegate?.setInitialState(state)
            let player = state.players[state.activePlayerSide.index]
            self.waitForPlayer(player, on: state.board)
        case let .set(disk, position, board):
            self.delegate?.setDisk(disk, atX: position.x, y: position.y, on: board)
        case .next(let player, let board):
            self.delegate?.movedTurn(to: player)
            self.waitForPlayer(player, on: board)
        case .pass:
            self.delegate?.passedTurn()
        case .finish(let winner):
            self.delegate?.finishedGame(wonBy: winner)
        case .reset(let state):
            self.resettedGame(with: state)
        }
    }
}
