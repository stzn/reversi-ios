//
//  UserActionDelegate.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol UserActionDelegate: AnyObject {
    func startGame()
    func placeDisk(at position: Board.Position)
    func changePlayerType(_ type: PlayerType, of side: Disk)
    func goToNextTurn()
    func resetGame()
}

