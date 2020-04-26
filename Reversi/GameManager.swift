//
//  GameManager.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol GameManagerDelegate: AnyObject {
    func startedGame(_ state: GameState)
    func update(_ action: NextAction)
}

final class GameManager {
    weak var delegate: GameManagerDelegate?

    private var darkPlayer = GamePlayer(type: .manual, side: .dark)
    private var lightPlayer = GamePlayer(type: .manual, side: .light)

    private let store: GameStateStore
    private(set) var state: GameState!
    var board: Board {
        return state.board
    }

    init(store: GameStateStore) {
        self.store = store

        store.loadGame { [weak self] result in
            guard let self = self else { return }
            var state: GameState
            switch result {
            case .success(let s):
                state = s
            case .failure:
                // TODO: error handling
                state = self.newGame()
            }
            self.delegate?.startedGame(state)
            self.state = state
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() -> GameState {
        let board = Board()
        board.reset()
        return GameState(activePlayerDisk: .dark, players: [darkPlayer, lightPlayer], board: board)
    }
}

/// MARK: next turn

extension GameManager {
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn(from player: GamePlayer) {
        if canDoNextTurn(player) {
            self.moveTurn(to: player)
            return
        }

        if shouldPassNextTurn(player) {
            self.passTurn(to: player)
            return
        }
        finishGame()
    }

    private func canDoNextTurn(_ player: GamePlayer) -> Bool {
        return !ReversiSpecification.validMoves(for: player.side, on: board).isEmpty
    }

    private func shouldPassNextTurn(_ player: GamePlayer) -> Bool {
        return !ReversiSpecification.validMoves(for: player.side.flipped, on: board).isEmpty
    }

    private func moveTurn(to player: GamePlayer) {
        let newPlayer = self.turnPlayer(from: player.side)
        self.delegate?.update(.next(newPlayer, board))
    }

    private func passTurn(to player: GamePlayer) {
        let newPlayer = self.turnPlayer(from: player.side)
        self.delegate?.update(.pass(newPlayer))
    }

    private func finishGame() {
        let winner = self.judgeWinner()
        self.delegate?.update(.finish(winner))
    }

    private func turnPlayer(from side: Disk) -> GamePlayer {
        switch side {
        case .dark:
            return lightPlayer
        case .light:
            return darkPlayer
        }
    }

    private func judgeWinner() -> GamePlayer? {
        guard let side = self.board.sideWithMoreDisks() else {
            return nil
        }
        switch side {
        case .dark:
            return darkPlayer
        case .light:
            return lightPlayer
        }
    }
}

extension GameManager {
    func changedPlayerType(_ type: PlayerType, of side: Disk) {
        switch side {
        case .dark:
            darkPlayer = darkPlayer.setType(type)
        case .light:
            lightPlayer = lightPlayer.setType(type)
        }
    }
}

