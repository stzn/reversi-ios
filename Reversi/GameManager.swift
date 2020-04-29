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
    private var board: Board {
        return state.board
    }

    private var activePlayer: GamePlayer {
        self.state.players[self.state.activePlayerSide.index]
    }

    private var inactivePlayer: GamePlayer {
        self.state.players[self.state.activePlayerSide.flipped.index]
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
    private func newGame() -> GameState {
        let board = Board()
        board.reset()
        return GameState(
            activePlayerSide: self.darkPlayer.side,
            players: [self.darkPlayer, self.lightPlayer],
            board: board)
    }
}

/// MARK: save and load
extension GameManager {
    private func save(completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.store.saveGame(
            turn: self.state.activePlayerSide,
            players: self.state.players,
            board: self.board
        ) { completion?($0) }
    }
}

/// MARK: next action judgement

extension GameManager {
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    private func nextTurn() {
        self.turnPlayer()
        if !self.canDoNextTurn(activePlayer) {
            if !self.canDoNextTurn(inactivePlayer) {
                self.finishGame()
            } else {
                self.passTurn()
            }
        } else {
            self.moveTurn()
        }
    }

    private func turnPlayer() {
        self.state.activePlayerSide = self.state.activePlayerSide.flipped
    }

    private func canDoNextTurn(_ player: GamePlayer) -> Bool {
        return
            !ReversiSpecification
            .validMoves(for: player.side, on: self.board).isEmpty
    }

    private func moveTurn() {
        self.delegate?.update(.next(self.activePlayer, board))
        self.save()
    }

    private func passTurn() {
        self.delegate?.update(.pass)
        self.save()
    }

    private func finishGame() {
        let winner = self.judgeWinner()
        self.delegate?.update(.finish(winner))
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

    func placeDisk(at position: Board.Position) throws {
        let side = state.activePlayerSide
        guard ReversiSpecification.canPlaceDisk(side, atX: position.x, y: position.y, on: board)
        else {
            throw DiskPlacementError(disk: side, x: position.x, y: position.y)
        }
        let positions = ReversiSpecification.flippedDiskCoordinatesByPlacingDisk(
            side, atX: position.x, y: position.y, on: self.board)
        self.board.setDisks(side, at: [position] + positions.map(Board.Position.init)) {
            isSuccess in
            if isSuccess {
                self.delegate?.update(.set(side, position, self.board))
                self.save()
            }
        }
    }

    func changePlayerType(_ type: PlayerType, of side: Disk) {
        self.state.players[side.index].setType(type)
        self.delegate?.update(.next(self.activePlayer, self.board))
        self.save()
    }

    func requestNextTurn() {
        self.nextTurn()
    }

    func requestResetGame() {
        self.state = self.newGame()
        self.delegate?.update(.reset(state))
        self.save()
    }
}
