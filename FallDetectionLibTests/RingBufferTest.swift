//
// Created by Peter Boberg on 2018-05-30.
// Copyright (c) 2018 Frost AB. All rights reserved.
//

import Foundation
//
//  FixedSizeArrayTest.swift
//  FallDetectionTests
//
//  Created by Peter Boberg on 2018-04-12.
//  Copyright © 2018 Frost. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import FallDetectionLib

class RingBufferTest: QuickSpec {
    
    override func spec() {
        super.spec()
        
        describe("A Ring Buffer", closure: {
            
            // Given
            var ringBuffer = FDRingBuffer(capacity: 6, frequency: 6)
            
            it("Should have a fixed size capacity", closure: {
                // Then
                expect(ringBuffer.capacity).to(equal(6))
            })
            
            it("Should have a current count of capacity when capacity is reached", closure: {
                // When
                ringBuffer.add(element: 1)
                ringBuffer.add(element: 2)
                ringBuffer.add(element: 3)
                ringBuffer.add(element: 4)
                ringBuffer.add(element: 5)
                ringBuffer.add(element: 6)
                // Adding for eg two extra elements to the array above capacity
                ringBuffer.add(element: 7)
                ringBuffer.add(element: 8)
                
                // Then
                expect(ringBuffer.count()).to(equal(6))
            })
            
            it("Should return the array in an insertion ordered fashion", closure: {
                // When
                let expected = [3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
                let actual = ringBuffer.retrieve()
                
                // Then
                expect(actual).to(equal(expected))
            })
            
            it("Should have a time interval in seconds that equal 'count' / 'frequency' ", closure: {
                // When
                let actual = Double(ringBuffer.capacity / ringBuffer.count())
                let expected = ringBuffer.timeIntervalInSeconds()
                
                // Then
                expect(actual).to(equal(expected))
            })
        })
    }
}

