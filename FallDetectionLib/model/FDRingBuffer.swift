//
// Created by Peter Boberg on 2018-04-12.
// Copyright (c) 2018 Frost. All rights reserved.
//

import Foundation

/**
    This struct represents a rolling fixed size array
    that continuously replaces the oldest values with the newest ones
    in a roll based fashion
*/
typealias Hertz = Int
typealias Samples = Int

struct FDRingBuffer {

    let capacity: Int
    let frequency: Hertz
    private var array: [Double]
    private var headIdx = -1

    init(capacity: Samples, frequency: Hertz) {
        self.capacity = capacity
        self.frequency = frequency
        self.array = [Double](repeating: 0, count: capacity)
    }

    mutating func add(element: Double) {
        headIdx += 1
        if headIdx == array.count {
            headIdx = 0
        }

        array[headIdx] = element
    }

    mutating func clear() {
        array = []
    }

    func count() -> Int {
        return self.array.count
    }

    func timeIntervalInSeconds() -> Double {
        return Double(array.count) / Double(frequency)
    }

    func get(sample: Int) -> Double {
        return array[sample]
    }

    func retrieve() -> [Double] {
        let head = array[...headIdx]
        let tail = headIdx == array.count - 1 ? [] : array[(headIdx + 1)..<array.count]
        var returned = [Double](tail)
        returned.append(contentsOf: head)
        return returned
    }
}
