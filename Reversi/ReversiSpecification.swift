//
//  ReversiSpecification.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

enum ReversiSpecification {
    /// 盤の幅を表します。
    public static let width: Int = 8

    /// 盤の高さを返します。
    public static let height: Int = 8

    /// 盤のセルの `x` の範囲を返します。
    public static let xRange: Range<Int> = 0..<width

    /// 盤のセルの `y` の範囲を返します。
    public static let yRange: Range<Int> = 0..<height

    private static func flippedDiskCoordinatesByPlacingDisk(
        _ disk: Disk, atX x: Int, y: Int, on board: Board
    ) -> [(Int, Int)] {
        let directions = [
            (x: -1, y: -1),
            (x: 0, y: -1),
            (x: 1, y: -1),
            (x: 1, y: 0),
            (x: 1, y: 1),
            (x: 0, y: 1),
            (x: -1, y: 0),
            (x: -1, y: 1),
        ]

        guard board.diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                switch (disk, board.diskAt(x: x, y: y)) {
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }

        return diskCoordinates
    }

    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    static func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int, on board: Board) -> Bool {
        return !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y, on: board).isEmpty
    }

    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    static func validMoves(for side: Disk, on board: Board) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []

        for y in yRange {
            for x in xRange {
                if canPlaceDisk(side, atX: x, y: y, on: board) {
                    coordinates.append((x, y))
                }
            }
        }

        return coordinates
    }

    static func isInRange(atX x: Int, y: Int) -> Bool {
        return xRange.contains(x) && yRange.contains(y)
    }
}

