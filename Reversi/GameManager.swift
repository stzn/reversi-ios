//
//  GameManager.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol GameManagerDelegate: AnyObject {
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
            self.state = state
            self.save()
        }
    }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() -> GameState {
        let board = Board()
        board.reset()
        return GameState(
            activePlayer: self.darkPlayer,
            players: [self.darkPlayer, self.lightPlayer],
            board: board)
    }
}

/// MARK: save and load
extension GameManager {
    private func save(completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.store.saveGame(
            turn: self.state.activePlayer.side,
            players: self.state.players,
            board: self.board
        ) { completion?($0) }
    }
}

/// MARK: next turn

extension GameManager {
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    private func nextTurn(from player: GamePlayer) {
        if self.canDoNextTurn(player) {
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
        return
            !ReversiSpecification
            .validMoves(for: player.side, on: self.board).isEmpty
    }

    private func shouldPassNextTurn(_ player: GamePlayer) -> Bool {
        return
            !ReversiSpecification
            .validMoves(for: player.side.flipped, on: self.board).isEmpty
    }

    private func moveTurn(to player: GamePlayer) {
        self.turnPlayer(from: player.side)
        self.delegate?.update(.next(self.state.activePlayer, board))
    }

    private func passTurn(to player: GamePlayer) {
        self.turnPlayer(from: player.side)
        self.delegate?.update(.pass(self.state.activePlayer))
    }

    private func finishGame() {
        let winner = self.judgeWinner()
        self.delegate?.update(.finish(winner))
    }

    private func turnPlayer(from side: Disk) {
        self.state.activePlayer = self.state.players[side.flipped.index]
    }

    private func judgeWinner() -> GamePlayer? {
        guard let side = self.board.sideWithMoreDisks() else {
            return nil
        }
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
}

// MARK: UserActionDelegate

extension GameManager: UserActionDelegate {
    func requestStartGame() {
        self.delegate?.update(.start(self.state))
    }

    func placeDisk(at position: Board.Position, of side: Disk) {
        self.state.board.setDisk(side, atX: position.x, y: position.y)
        self.delegate?.update(.set(side, position, self.board))
        self.save()
    }

    func changePlayerType(_ type: PlayerType, of side: Disk) {
        self.state.players[side.index].setType(type)
        self.save()
    }

    func requestNextTurn() {
        self.nextTurn(from: self.state.activePlayer)
    }

    func requestResetGame() {
        self.state = self.newGame()
        self.delegate?.update(.start(self.state))
    }
}
