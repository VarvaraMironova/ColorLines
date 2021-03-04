//
//  VMGame.swift
//  VMLines
//
//  Created by Varvara Myronova on 08.02.2021.
//

import Foundation

protocol VMGameDelegate: class {
    func moveBallByPath(path             : [VMMatrixElement],
                        completion block : @escaping (Bool) -> Void)
    
    func addBalls(elements: Set<VMMatrixElement>)
    
    func removeBall(element           : VMMatrixElement,
                     completion block : @escaping (Bool) -> Void)
    
    func growUpBall(element: VMMatrixElement)
    
    func gameOver()
}

class VMGame {
    var matrix : VMMatrix!
    var timer  : VMTimer?
    
    var embryoColors = [String]()
    
    public var score : Int = 0 {
        didSet {
            if score > bestScore {
                UserDefaults().set(score, forKey: kVMBestScoreKey)
            }
        }
    }
    
    public lazy var bestScore : Int = {
        return UserDefaults().integer(forKey: kVMBestScoreKey)
    }()
    
    let kVMBestScoreKey = "bestScore"
    let ballColors = ["darkBlue", "darkRed", "green", "lightBlue", "lightRed", "pink", "yellow"]
    let matrixSize = (rows: 9, columns: 9)
    
    weak var gameDelegate: VMGameDelegate?
    
    required init(delegate: VMGameDelegate) {
        gameDelegate = delegate
        
        setup()
    }
    
    private func setup() {
        matrix = VMMatrix(rows    : matrixSize.rows,
                          columns : matrixSize.columns)
        
        spawnBalls(initially: true)
        //timer = VMTimer(game: self)
    }
    
    @objc func updateTimer() {
        
    }
    
    //MARK: - Public
    public func reset() {
        score = 0
        embryoColors = [String]()
        setup()
    }
    
    public func selectElement(coordinates: VMElementCoordinates) {
        let element = matrix[coordinates.row, coordinates.column]
        
        if let ball = element.ball, ball.size == .fullSized {
            //select the ball
            matrix.selectedElement = element
        } else {
            //check if there's a selected selectedElement with a ball
            if let selectedElement = matrix.selectedElement {
                //if yes move the ball from the selected element to the element
                moveBall(fromElement: selectedElement, toElement: element)
            }
        }
    }
    
    //MARK: - Searching the path
    private struct kVMNode: Equatable {
        var element    : VMMatrixElement
        var parent     : VMMatrixElement?
        
        //Path length from the start node to the current node DE FACTO
        var g : Int
        
        //f = g + hypotesys cost from the current to the destination node
        var f : Int
        
        init(element    : VMMatrixElement,
             parent     : VMMatrixElement?,
             g          : Int,
             f          : Int)
        {
            self.element = element
            self.parent = parent
            self.g = g
            self.f = f
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.element == rhs.element &&
                lhs.g == rhs.g &&
                lhs.f == rhs.f &&
                lhs.parent == rhs.parent
        }
    }
    
    public func path(start: VMMatrixElement, destination: VMMatrixElement) -> [VMMatrixElement]? {
        if let destinationBall = destination.ball, destinationBall.size == .fullSized {
            return nil
        }
        
        if let ball = start.ball, ball.size == .fullSized {
            //Initiate first Node from the first element
            let f_initial = matrix.pathLength(from: start, to: destination)
            let node_initial = kVMNode(element : start,
                                       parent  : nil,
                                       g       : 0,
                                       f       : f_initial)
            var openList = [node_initial]
            var closedList = [kVMNode]()
            
            while !openList.isEmpty {
                //find the node with the least f on the open list
                //sort open list by pathLength in descending order
                var openList_sorted = openList.sorted {
                    return $0.f > $1.f
                }
                
                //pop the node with the shortest pathLength
                if let currentNode = openList_sorted.popLast() {
                    openList.removeAll(where: {$0 == currentNode})
                    //generate currentNode's neighbours and set their parents to currentNode
                    let neighbours = matrix.neighboursForElement(element: currentNode.element)
                    
                    for neighbour in neighbours {
                        let g = currentNode.g + 1
                        let h = matrix.pathLength(from: neighbour, to: destination)
                        let node = kVMNode(element      : neighbour,
                                           parent       : currentNode.element,
                                           g            : g,
                                           f            : g+h)
                        
                        if neighbour == destination {
                            //the path's found
                            closedList.append(currentNode)
                            closedList.append(node)
                            
                            return pathFromNodes(nodes: closedList, startElement: start)
                        }
                        
                        if closedList.contains(where: {$0.element == node.element})
                        {
                            continue
                        } else if let openNode = openList.first(where: {$0.element == node.element}),
                           node.f >= openNode.f
                        {
                            continue
                        } else {
                            openList.append(node)
                        }
                    }
                    
                    if !closedList.contains(where: {$0.element == currentNode.element}) {
                        closedList.append(currentNode)
                    }
                }
            }
        }
        
        return nil
    }
    
    //MARK: - Completing lines
    private func handleLines(lines: Set<VMMatrixElement>,
                             completion block : @escaping (Bool) -> Void)
    {
        score += lines.count
        
        if let delegate = gameDelegate {
            let handleLinesGroup = DispatchGroup()
            
            for elementToClear in lines {
                handleLinesGroup.enter()
                matrix.clearElement(element: elementToClear)
                
                delegate.removeBall(element: elementToClear) { (finished) in
                    handleLinesGroup.leave()
                }
            }
            
            handleLinesGroup.notify(queue: .main) {
                    block(true)
            }
        }
    }
    
    //MARK: - Field handling
    private func moveBall(fromElement: VMMatrixElement,
                          toElement: VMMatrixElement)
    {
        //search a path from the starting element to the destination element
        if let path = path(start: fromElement, destination: toElement) {
            //if there's a path move the selected ball to the element
            gameDelegate?.moveBallByPath(path       : path,
                                         completion : { [weak self, weak matrix, weak gameDelegate] (finished) in
                guard let strongSelf = self else { return }
                
                if finished {
                    //check if the destination element has an embryo ball
                    //backup the destination element
                    var embryoToRestore : VMMatrixElement?
                    if let ball = toElement.ball, ball.size == .embryo {
                        //save the element
                        embryoToRestore = toElement.copy()
                    }
                    
                    //remove the ball from the start element
                    //add the ball to the destination element
                    if let ball = fromElement.ball {
                        fromElement.removeBall()
                        toElement.addBall(ball: ball)
                    }
                    
                    if let matrix = matrix {
                        //check if there's a completed line(s) with the element
                        let lines = matrix.linesWithElement(element: toElement)
                        
                        if lines.count > 0 {
                            DispatchQueue.main.async {
                                strongSelf.handleLines(lines: lines) { (finished) in
                                    //when finished, put removed embryo back to the matrix
                                    if let removedEmbryo = embryoToRestore
                                    {
                                        if let coordinates = removedEmbryo.coordinates {
                                            let elementToRestore = matrix[coordinates.row, coordinates.column]
                                            elementToRestore.addBall(ball: removedEmbryo.ball!)
                                            
                                            if let delegate = gameDelegate {
                                                delegate.addBalls(elements: [elementToRestore])
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            //grow up embryo balls and generate new embryos
                            strongSelf.spawnBalls(initially: false)
                        }
                    }
                }
            })
        }
    }
    
    private func spawnBalls(initially: Bool) {
        let embryosCount = 3
        var emptyCells = matrix.emptyCells
        
        if emptyCells.count < embryosCount {
            gameDelegate?.gameOver()
            reset()
        } else {
            var elementsToFill = Set<VMMatrixElement>()
            let fullSizedCount = initially ? 5 : 3
            
            if initially {
                //spawn fullSized balls
                for _ in 1...fullSizedCount {
                    if let color = ballColors.randomElement(),
                       let spot = emptyCells.randomElement()
                    {
                        let ball = VMBall(color: color, size: .fullSized)
                        spot.addBall(ball: ball)
                        
                        elementsToFill.insert(spot)
                        emptyCells.removeAll(where: {$0 == spot})
                    }
                }
            } else {
                //grow up embryos
                let embryos = matrix.embryoCells
                
                if let delegate = gameDelegate {
                    for embryoElement in embryos {
                        embryoElement.growUp()
                        delegate.growUpBall(element: embryoElement)
                        
                        //Check if there's a line after the growUp
                        let lines = matrix.linesWithElement(element: embryoElement)
                        
                        if lines.count > 0 {
                            handleLines(lines: lines) { (finished) in }
                            
                            break
                        }
                    }
                }
            }
            
            //spawn embryo balls
            for i in 0...embryosCount - 1 {
                if let spot = emptyCells.randomElement(),
                   let color = initially ? ballColors.randomElement() : embryoColors[i]
                {
                    let ball = VMBall(color: color, size: .embryo)
                    spot.addBall(ball: ball)
                    
                    elementsToFill.insert(spot)
                    emptyCells.removeAll(where: {$0 == spot})
                }
            }
            
            //pick the colors for the future embryos
            embryoColors = [String]()
            for _ in 1...embryosCount {
                if let color = ballColors.randomElement() {
                    embryoColors.append(color)
                }
            }
            
            if let delegate = gameDelegate {
                delegate.addBalls(elements: elementsToFill)
            }
        }
    }
    
    //MARK: - Helpers
    private func pathFromNodes(nodes       : [kVMNode],
                               startElement: VMMatrixElement) -> [VMMatrixElement]
    {
        var currentNode = nodes.last!
        var result = [currentNode.element]
        
        while currentNode.parent != startElement {
            if let previousNode = nodes.first(where:
                                                {$0.element == currentNode.parent})
            {
                currentNode = previousNode
                result.insert(currentNode.element, at: 0)
            }
        }
        
        result.insert(startElement, at: 0)
        
        return result
    }
    
}
