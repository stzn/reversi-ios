//
//  UserActionDelegate.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public protocol UserActionDelegate: AnyObject {
    func requestStartGame()
    func placeDisk(at position: Board.Position) throws
    func changePlayerType(_ type: PlayerType, of side: Disk)
    func requestNextTurn()
    func requestResetGame()
}

