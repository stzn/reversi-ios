//
//  UserInputDelegate.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol UserInputDelegate: AnyObject {
    func changedPlayerType(_ type: PlayerType)
    func wentNextTurn()
    func resettedGame()
}

