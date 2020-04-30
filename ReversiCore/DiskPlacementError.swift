//
//  DiskPlacementError.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
    public let on: Board
    init(disk: Disk, x: Int, y: Int, on: Board) {
        self.disk = disk
        self.x = x
        self.y = y
        self.on = on
    }
}
