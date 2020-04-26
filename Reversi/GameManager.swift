//
//  GameManager.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol GameManagerDelegate: AnyObject {
    func setDisk(_ disk: Disk, atX: Int, y: Int)
    func changedTurn(to player: GamePlayer)
    func passedTurn(of player: GamePlayer)
    func finishedGame(wonBy player: GamePlayer?)
}

protocol ComputerPlayerDelegate: AnyObject {
    func startedTurn(of player: GamePlayer)
    func endedTurn(of player: GamePlayer)
}

final class GameManager {
    weak var delegate: GameManagerDelegate?
    weak var computerDelegate: ComputerPlayerDelegate?

    private var darkPlayer = GamePlayer(type: .manual, turn: .dark)
    private var lightPlayer = GamePlayer(type: .manual, turn: .light)
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    private(set) var activePlayer: GamePlayer?
    /// 非同期処理のキャンセルを管理します。
    private var playerCancellers: [GamePlayer: Canceller] = [:]
    private(set) var board = Board()

    private let store: GameStateStore
    init(store: GameStateStore) {
        self.store = store

        store.loadGame { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let state):
                self.setLoadedGame(state: state)
            case .failure:
                // TODO: error handling
                self.newGame()
            }
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        board.reset()
        activePlayer = darkPlayer
    }

    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let player = self.activePlayer else { return }
        switch player.type {
        case .manual:
            break
        case .computer:
            let canceller = playTurnOfComputer { [weak self] in
                guard let self = self else { return }
                self.setDiskAtRandom(by: player)
            }
            playerCancellers[player] = canceller
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer(action: @escaping () -> Void) -> Canceller {
        guard let player = self.activePlayer else { preconditionFailure() }
        computerDelegate?.startedTurn(of: player)
        let cleanUp: () -> Void = { [weak self, player] in
            guard let self = self else { return }
            self.computerDelegate?.endedTurn(of: player)
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

    private func setLoadedGame(state: GameState) {
        self.board = state.board
        state.players.forEach { player in
            switch player.turn {
            case .dark:
                self.darkPlayer = player
            case .light:
                self.lightPlayer = player
            }
        }

        switch state.activePlayerDisk {
        case .dark:
            self.activePlayer = darkPlayer
        case .light:
            self.activePlayer = lightPlayer
        }
    }

    private func setDiskAtRandom(by player: GamePlayer) {
        let (x, y) =
            ReversiSpecification
                .validMoves(for: player.turn, on: self.board)
                .randomElement()!
        self.delegate?.setDisk(player.turn, atX: x, y: y)
    }
}

/// MARK: next turn

extension GameManager {
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard let player = self.activePlayer else { return }

        if canDoNextTurn(player) {
            self.changeTurn(to: player)
            return
        }

        if shouldPassNextTurn(player) {
            self.passTurn(to: player)
            return
        }
        finishGame()
    }

    private func canDoNextTurn(_ player: GamePlayer) -> Bool {
        return !ReversiSpecification.validMoves(for: player.turn, on: board).isEmpty
    }

    private func shouldPassNextTurn(_ player: GamePlayer) -> Bool {
        return !ReversiSpecification.validMoves(for: player.turn.flipped, on: board).isEmpty
    }

    private func changeTurn(to player: GamePlayer) {
        self.turnPlayer()
        self.delegate?.changedTurn(to: player)
        waitForPlayer()
    }

    private func passTurn(to player: GamePlayer) {
        self.turnPlayer()
        self.delegate?.passedTurn(of: player)
    }

    private func finishGame() {
        self.activePlayer = nil
        let winner = self.judgeWinner()
        self.delegate?.finishedGame(wonBy: winner)
    }

    private func turnPlayer() {
        guard let player = activePlayer else { preconditionFailure() }
        if player == darkPlayer {
            activePlayer = lightPlayer
        } else {
            activePlayer = darkPlayer
        }
    }

    private func judgeWinner() -> GamePlayer? {
        guard let turn = self.board.sideWithMoreDisks() else {
            return nil
        }
        switch turn {
        case .dark:
            return darkPlayer
        case .light:
            return lightPlayer
        }
    }
}

extension GameManager {
    func changedPlayerType(_ type: PlayerType) {
        guard let player = self.activePlayer else {
            return
        }
        activePlayer = player.setType(type)
    }

    func wentNextTurn() {
        self.nextTurn()
    }

    func resettedGame() {
        playerCancellers.forEach { (player, canceller) in
            canceller.cancel()
            playerCancellers[player] = nil
        }
    }
}

