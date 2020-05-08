//
//  DiskPosition.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//
struct DiskPosition: Equatable, Hashable, Comparable {
    static func < (lhs: DiskPosition, rhs: DiskPosition) -> Bool {
        lhs.x < rhs.x && lhs.y < rhs.y
    }

    let x: Int
    let y: Int
}
