//
//  VMBall.swift
//  VMLines
//
//  Created by Varvara Myronova on 10.02.2021.
//

import Foundation

extension VMBall {
    enum kVMBallSize {
        case embryo;
        case fullSized
    }
}

class VMBall: Hashable {
    var color : String!
    var size  : kVMBallSize!
    
    required init(color: String, size: kVMBallSize) {
        self.size = size
        self.color = color
    }
    
    static func == (lhs: VMBall, rhs: VMBall) -> Bool {
        return lhs.size == rhs.size &&
            lhs.color == rhs.color
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(color)
        hasher.combine(size)
    }
}
