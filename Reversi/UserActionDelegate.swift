//
//  UserActionDelegate.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol UserActionDelegate: AnyObject {
    func requestStartGame()
    func placeDisk(at position: Board.Position, of side: Disk)
    func changePlayerType(_ type: PlayerType, of side: Disk)
    func requestNextTurn()
    func requestResetGame()
}

