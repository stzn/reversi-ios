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

    /// 盤をゲーム開始時に状態に戻します。
    func reset() {
        disks = [:]
        let width = ReversiSpecification.width
        let height = ReversiSpecification.height
        setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2 - 1, y: height / 2)
        setDisk(.light, atX: width / 2, y: height / 2)
    }

    /// `x`, `y` で指定されたセルの状態を、与えられた `disk` に変更します。
    /// - Parameter disk: セルに設定される新しい状態です。 `nil` はディスクが置かれていない状態を表します。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter completion: アニメーションの完了通知を受け取るハンドラーです。
    ///     `animated` に `false` が指定された場合は状態が変更された後で即座に同期的に呼び出されます。
    ///     ハンドラーが受け取る `Bool` 値は、 `UIView.animate()`  等に準じます。
    func setDisk(_ disk: Disk, atX x: Int, y: Int,
                 completion: ((Bool) -> Void)? = nil) {
        guard ReversiSpecification.isInRange(atX: x, y: y) else {
            completion?(false)
            return
        }
        disks[.init(x: x, y: y)] = disk
        completion?(true)
    }

    /// `x`, `y` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    func diskAt(x: Int, y: Int) -> Disk? {
        return disks.first(where: {
            (position, disk) in position == .init(x: x, y: y)
        })?.value
    }

    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func countDisks(of side: Disk) -> Int {
        return disks.values.filter { disk in
            switch (side, disk) {
            case (.dark, .dark), (.light, .light):
                return true
            default:
                return false
            }
        }.count
    }

    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Disk? {
        let darkCount = countDisks(of: .dark)
        let lightCount = countDisks(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
}

