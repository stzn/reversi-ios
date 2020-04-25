//
//  Board.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

final class Board {
    struct Position: Hashable {
        let x: Int
        let y: Int
    }

    private(set) var disks: [Position: Disk] = [:]
    private let specification: ReversiSpecification

    init(specification: ReversiSpecification) {
        self.specification = specification
    }

    func reset() {
        let width = specification.width
        let height = specification.height
        setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2 - 1, y: height / 2)
        setDisk(.light, atX: width / 2, y: height / 2)
    }

    func setDisk(_ disk: Disk, atX x: Int, y: Int) {
        guard specification.isInRange(atX: x, y: y) else {
            return
        }
        disks[.init(x: x, y: y)] = disk
    }

    func diskAt(x: Int, y: Int) -> Disk? {
        return disks.first(where: {
            (position, disk) in position == .init(x: x, y: y)
        })?.value
    }
}

