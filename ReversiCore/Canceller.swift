//
//  Canceller.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public final class Canceller {
    private(set) public var isCancelled: Bool = false
    private let body: (() -> Void)?

    public init(_ body: (() -> Void)?) {
        self.body = body
    }

    public func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}
