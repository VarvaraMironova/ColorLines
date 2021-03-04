//
//  VMMatrix.swift
//  VMLines
//
//  Created by Varvara Myronova on 07.02.2021.
//

import Foundation

extension VMMatrix {
    subscript(row: Int, column: Int) -> VMMatrixElement {
        get {
            return element(row: row, column: column)
        }
        
        set (newValue) {
            var element = matrix[row][column]
            
            if element == newValue {
                return
            }
            
            element = newValue
        }
    }
    
    subscript(row: Int) -> [VMMatrixElement] {
        get {
            return matrix[row]
        }
    }
}

class VMMatrix {
    private var matrix = [[VMMatrixElement]]()
    
    public var emptyCells : [VMMatrixElement] {
        get {
            return matrix.flatMap { $0 }.filter { (element) -> Bool in
                return element.ball == nil
            }
        }
    }
    
    public var embryoCells : [VMMatrixElement] {
        get {
            return matrix.flatMap { $0 }.filter { (element) -> Bool in
                if let ball = element.ball, ball.size == .embryo {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    public var size : (rows: Int, columns: Int)
    
    var selectedElement : VMMatrixElement? {
        willSet (aNewValue) {
            if selectedElement == aNewValue {
                return
            }
            
            if let selectedElement = selectedElement {
                selectedElement.select(select: false)
            }
            
            if let aNewValue = aNewValue {
                aNewValue.select(select: true)
            }
        }
    }
    
    //MARK: - Initializations and Deallocation
    required init(rows: Int, columns: Int) {
        size = (rows, columns)
        
        for i in 0...rows-1 {
            var row = [VMMatrixElement]()
            
            for j in 0...columns-1 {
                let coordinates = VMElementCoordinates(row: i, column: j)
                let element = VMMatrixElement(coordinates: coordinates)
                
                row.append(element)
            }
            
            matrix.append(row)
        }
    }
    
    //MARK: - Public
    public func clearElement(element: VMMatrixElement) {
        element.removeBall()
    }
    
    //Since I don't care about the elements order,
    //And elements are unique,
    //I use Set instead of Array to store the result
    public func linesWithElement(element: VMMatrixElement) -> Set<VMMatrixElement> {
        var result = Set<VMMatrixElement>()
        
        if let ball = element.ball,
           ball.size == .fullSized,
           let coordinates = element.coordinates
        {
            let color = ball.color!
            let rowIndex = coordinates.row
            let columnIndex = coordinates.column
            
            //check row
            let row = matrix[rowIndex]
            let horizontalLine = lineForElementWithIndexAndColor(row  : row,
                                                                 index: columnIndex,
                                                                 color: color)
            
            //check column
            let columnWithElemnt = column(index: columnIndex)
            let verticalLine = lineForElementWithIndexAndColor(row  : columnWithElemnt,
                                                               index: rowIndex,
                                                               color: color)
            
            //check major diagonal
            let diagonal1 = majorDiagonal(coordinates: coordinates)
            let majorDiagonalIndex = diagonal1.firstIndex(where: {$0 == element})
            let majorDiagonalLine = lineForElementWithIndexAndColor(row  : diagonal1,
                                                                    index: majorDiagonalIndex!,
                                                                    color: color)
            
            //check minor diagonal
            let diagonal2 = minorDiagonal(coordinates: coordinates)
            let minorDiagonalIndex = diagonal2.firstIndex(where: {$0 == element})
            let minorDiagonalLine = lineForElementWithIndexAndColor(row  : diagonal2,
                                                                    index: minorDiagonalIndex!,
                                                                    color: color)
            
            let lines = [horizontalLine, verticalLine, majorDiagonalLine, minorDiagonalLine]
            
            for line in lines {
                if line.count > 4 {
                    result = result.union(line)
                }
            }
        }
        
        return result
    }
    
    private func lineForElementWithIndexAndColor(row   : [VMMatrixElement],
                                                 index : Int,
                                                 color : String) -> Set<VMMatrixElement>
    {
        var result = Set<VMMatrixElement>()
        
        for i in (0...index).reversed() {
            let nextElement = row[i]
            
            if let ball = nextElement.ball,
               ball.color == color &&
                ball.size == .fullSized
            {
                result.insert(nextElement)
            } else {
                break
            }
        }
        
        for i in index...row.count - 1 {
            let nextElement = row[i]
            
            if let ball = nextElement.ball,
               ball.color == color &&
                ball.size == .fullSized
            {
                result.insert(nextElement)
            } else {
                break
            }
        }
        
        return result
    }
    
    //MARK: - Matrix components
    private func element(row: Int, column: Int) -> VMMatrixElement {
        return matrix[Int(row)][column]
    }
    
    private func column(index: Int) -> [VMMatrixElement] {
        var result = [VMMatrixElement]()
        
        if index >= 0 && index < size.columns {
            for i in 0...size.rows - 1 {
                result.append(matrix[i][index])
            }
        }
        
        return result
    }
    
    //diagonal from top left to bottom right that includes an element with coordinates
    private func majorDiagonal(coordinates: VMElementCoordinates) -> [VMMatrixElement] {
        var result = [VMMatrixElement]()
        
        if areCoordinatesInBounds(coordinates: coordinates) {
            let rowsCount = size.rows
            let delta = coordinates.row - coordinates.column
            let range = delta < 0 ? Range(0...rowsCount - 1 + delta) : Range(delta...rowsCount - 1)
            
            for i in range {
                let j = i - delta
                let element = matrix[i][j]
                result.append(element)
            }
        }
        
        return result
    }
    
    private func minorDiagonal(coordinates: VMElementCoordinates) -> [VMMatrixElement] {
        var result = [VMMatrixElement]()
        
        if areCoordinatesInBounds(coordinates: coordinates) {
            let columnsCount = size.columns
            let sum = coordinates.row + coordinates.column
            let range = columnsCount - sum > 0 ?
                                Range(0...sum) : Range(sum - columnsCount + 1...columnsCount - 1)
            for j in range {
                let i = sum - j
                let element = matrix[i][j]
                result.append(element)
            }
        }
        
        return result
    }
    
    //MARK: - Helpers for searching the path
    
    public func pathLength(from: VMMatrixElement, to: VMMatrixElement) -> Int {
        return abs(to.coordinates.row - from.coordinates.row) +
            abs(to.coordinates.column - from.coordinates.column)
    }
    
    public func neighboursForElement(element: VMMatrixElement) -> [VMMatrixElement] {
        let columnsCount = size.columns
        let rowsCount = size.rows
        var result = [VMMatrixElement]()
        
        if let coordinates = element.coordinates {
            //top
            if coordinates.row > 0 {
                let topNode = matrix[coordinates.row - 1][coordinates.column]
                
                if nil == topNode.ball || topNode.ball?.size == .embryo {
                    result.append(topNode)
                }
            }
            
            //bottom
            if coordinates.row < rowsCount - 1 {
                let bottomNode = matrix[coordinates.row + 1][coordinates.column]
                
                if nil == bottomNode.ball || bottomNode.ball?.size == .embryo {
                    result.append(bottomNode)
                }
            }
            
            //right
            if coordinates.column < columnsCount - 1 {
                let rightNode = matrix[coordinates.row][coordinates.column + 1]
                
                if nil == rightNode.ball || rightNode.ball?.size == .embryo {
                    result.append(rightNode)
                }
            }
            
            //left
            if coordinates.column > 0 {
                let leftNode = matrix[coordinates.row][coordinates.column - 1]
                
                if nil == leftNode.ball || leftNode.ball?.size == .embryo {
                    result.append(leftNode)
                }
            }
        }
        
        return result
    }
    
    //MARK: - Helpers
    private func areCoordinatesInBounds(coordinates: VMElementCoordinates) -> Bool {
        return coordinates.row >= 0 &&
            coordinates.row < size.rows &&
            coordinates.column >= 0 &&
            coordinates.column < size.columns
    }
}

