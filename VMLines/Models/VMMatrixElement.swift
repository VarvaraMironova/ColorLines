//
//  VMMatrixElement.swift
//  VMLines
//
//  Created by Varvara Myronova on 07.02.2021.
//

import Foundation

struct VMElementCoordinates: Hashable {
    var row     : Int
    var column  : Int
    
    public var description: String {
        get {
            return String(row)+","+String(column)
        }
    }
    
    static func == (lhs: VMElementCoordinates, rhs: VMElementCoordinates) -> Bool {
        return lhs.row == rhs.row &&
            lhs.column == rhs.column
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
}

extension VMMatrixElement {
    enum kVMElementState {
        case filled;
        case empty
    }
}

class VMMatrixElement : NSObject {
    
    var coordinates : VMElementCoordinates!
    var state       : kVMElementState = .empty
    
    var ball        : VMBall?
    
    @objc dynamic var selected : Bool = false
    
    required init(coordinates: VMElementCoordinates) {
        self.coordinates = coordinates
    }
    
    public func addBall(ball: VMBall) {
        self.ball = ball
        state = .filled
    }
    
    public func removeBall() {
        ball = nil
        state = .empty
        selected = false
    }
    
    public func select(select: Bool) {
        selected = select
    }
    
    public func growUp() {
        ball?.size = .fullSized
    }
    
    static func == (lhs: VMMatrixElement, rhs: VMMatrixElement) -> Bool {
        return lhs.state == rhs.state &&
            lhs.coordinates == rhs.coordinates &&
            lhs.ball == rhs.ball
    }
    
    //MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> VMMatrixElement {
        let copy = VMMatrixElement(coordinates: coordinates)
        copy.selected = selected
        copy.state = state
        
        if let ball = ball {
            copy.addBall(ball: ball)
        }
        
        return copy
    }
    

}
