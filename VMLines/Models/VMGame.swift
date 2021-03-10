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
    
    func addBall(element: VMMatrixElement)
    
    func removeBall(element           : VMMatrixElement,
                     completion block : @escaping (Bool) -> Void)
    
    func updateScore(score: Int)
    
    func updateBestScore(bestScore: Int)
    
    func growUpBall(element: VMMatrixElement)
    
    func pickFutureColors(colors: [String])
    
    func gameOver()
}

class VMGame {
    var matrix : VMMatrix!
    var timer  : VMTimer?
    
    var embryoColors = [String]() {
        willSet(aNewValue) {
            if aNewValue != embryoColors {
                gameDelegate?.pickFutureColors(colors: aNewValue)
            }
        }
    }
    
    var score : Int = 0 {
        didSet {
            if score == oldValue {
                return
            }
            
            gameDelegate?.updateScore(score: score)
            
            if score > bestScore {
                bestScore = score
            }
        }
    }
    
    var bestScore : Int {
        set {
            UserDefaults().set(newValue, forKey: kVMBestScoreKey)
            gameDelegate?.updateBestScore(bestScore: newValue)
        }
        
        get {
            return UserDefaults().integer(forKey: kVMBestScoreKey)
        }
        
    }
    
    let kVMBestScoreKey = "bestScore"
    let ballColors = ["darkBlue", "darkRed", "green", "lightBlue", "lightRed", "pink", "yellow"]
    let matrixSize = (rows: 9, columns: 9)
    
    weak var gameDelegate: VMGameDelegate? {
        didSet {
            spawnBalls(initially: true)
            gameDelegate?.updateBestScore(bestScore: bestScore)
        }
    }
    
    required init() {
        setup()
    }
    
    private func setup() {
        matrix = VMMatrix(rows    : matrixSize.rows,
                          columns : matrixSize.columns)
        //timer = VMTimer(game: self)
    }
    
    @objc func updateTimer() {
        
    }
    
    //MARK: - Public
    public func restart() {
        gameDelegate?.gameOver()
        score = 0
        bestScore = UserDefaults().integer(forKey: kVMBestScoreKey)
        embryoColors = [String]()
        setup()
        spawnBalls(initially: true)
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
                moveBall(fromElement : selectedElement,
                         toElement   : element)
            }
        }
    }
    
    //MARK: - Field handling
    private func handleLines(lines            : Set<VMMatrixElement>,
                             completion block : @escaping (Bool) -> Void)
    {
        score += lines.count
        
        if let delegate = gameDelegate {
            let handleLinesGroup = DispatchGroup()
            
            for elementToClear in lines {
                handleLinesGroup.enter()
                
                delegate.removeBall(element: elementToClear) { [weak matrix, weak elementToClear] (finished) in
                    if let matrix = matrix, let element = elementToClear {
                        matrix.clearElement(element: element)
                    }
                    
                    handleLinesGroup.leave()
                }
            }
            
            handleLinesGroup.notify(queue: .main) {
                
                block(true)
            }
        }
    }
    
    private func moveBall(fromElement: VMMatrixElement,
                          toElement: VMMatrixElement)
    {
        //search a path from the starting element to the destination element
        if let path = matrix.path(start       : fromElement,
                                  destination : toElement)
        {
            //check if the destination element has an embryo ball
            //backup the destination element
            var embryoToRestore : VMMatrixElement?
            if let ball = toElement.ball, ball.size == .embryo {
                embryoToRestore = toElement.copy()
            }
            
            //remove the ball from the start element
            //add the ball to the destination element
            if let ball = fromElement.ball {
                fromElement.removeBall()
                toElement.addBall(ball: ball)
            }
            
            //check if there's a completed line(s) with the element
            let lines = matrix.linesWithElement(element: toElement)
            
            //if there's a path move the selected ball to the element
            gameDelegate?.moveBallByPath(path       : path,
                                         completion : { [weak self, weak matrix] (finished) in
                guard let strongSelf = self else { return }
                
                if finished {
                    if lines.count > 0 {
                        strongSelf.handleLines(lines: lines) { (finished) in
                            //when finished, put removed embryo back to the matrix
                            if let removedEmbryo = embryoToRestore,
                               let coordinates = removedEmbryo.coordinates,
                               let ball = removedEmbryo.ball,
                               let matrix = matrix,
                               finished
                            {
                                let element = matrix[coordinates.row, coordinates.column]
                                strongSelf.fillElement(element : element,
                                                       ball    : ball)
                                
                                embryoToRestore = nil
                            }
                        }
                        DispatchQueue.main.async {
                            
                        }
                    } else {
                        //if there was a removed embryo
                        //pass it to the spawn method
                        strongSelf.spawnBalls(initially         : false,
                                              elementToRestore  : embryoToRestore)
                    }
                }
            })
        }
    }
    
    private func spawnBalls(initially        : Bool,
                            elementToRestore : VMMatrixElement? = nil)
    {
        let embryosCount = 3
        var emptyCells = matrix.emptyCells
        
        if emptyCells.count < embryosCount {
            restart()
        } else {
            let fullSizedCount = initially ? 5 : 3
            
            if initially {
                //spawn fullSized balls
                for _ in 1...fullSizedCount {
                    if let color = ballColors.randomElement(),
                       let spot = emptyCells.randomElement()
                    {
                        let ball = VMBall(color: color, size: .fullSized)
                        fillElement(element: spot, ball: ball)
                        
                        emptyCells.removeAll(where: {$0 == spot})
                    }
                }
            } else {
                //grow up embryos
                let embryos = matrix.embryoCells
                var linesToHandle = [Set<VMMatrixElement>]()
                
                for embryoElement in embryos {
                    growUpElement(element: embryoElement)
                    
                    //Check if there's a line after the growUp
                    let lines = matrix.linesWithElement(element: embryoElement)
                    
                    if lines.count > 0 {
                        linesToHandle.append(lines)
                    }
                }
                
                //grow removed embryo up and
                //put it back to the field (with random coordinates)
                if let elementToRestore = elementToRestore {
                    if let spot = emptyCells.randomElement(),
                       let color = elementToRestore.ball?.color
                    {
                        let ball = VMBall(color: color, size: .fullSized)
                        fillElement(element: spot, ball: ball)
                        
                        let lines = matrix.linesWithElement(element: spot)
                        
                        if lines.count > 0 {
                            linesToHandle.append(lines)
                        }
                        
                        emptyCells.removeAll(where: {$0 == spot})
                    }
                }
                
                for line in linesToHandle {
                    handleLines(lines: line) { (finished) in }
                }
            }
            
            //spawn embryo balls
            for i in 0...embryosCount - 1 {
                if let spot = emptyCells.randomElement(),
                   let color = initially ? ballColors.randomElement() : embryoColors[i]
                {
                    let ball = VMBall(color: color, size: .embryo)
                    fillElement(element: spot, ball: ball)
                    
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
        }
    }
    
    //MARK: - Helpers
    private func pickFutureEmbryos() {
        
    }
    
    private func growUpElement(element: VMMatrixElement) {
        element.growUp()
        
        if let delegate = gameDelegate {
            delegate.growUpBall(element: element)
        }
    }
    
    private func fillElement(element : VMMatrixElement,
                             ball    : VMBall)
    {
        element.addBall(ball: ball)
        
        if let delegate = gameDelegate {
            delegate.addBall(element: element)
        }
    }
    
}
