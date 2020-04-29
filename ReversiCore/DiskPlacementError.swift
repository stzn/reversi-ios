//
//  DiskPlacementError.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
