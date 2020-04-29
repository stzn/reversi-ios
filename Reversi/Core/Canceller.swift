//
//  Canceller.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}
