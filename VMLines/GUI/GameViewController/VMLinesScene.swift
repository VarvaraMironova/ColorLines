//
//  VMLinesScene.swift
//  VMLines
//
//  Created by Varvara Myronova on 23.02.2021.
//

import UIKit
import SpriteKit
import SceneKit

extension VMLinesScene {
    enum kVMHeaderLabelType {
        case left;
        case right
    }
}

extension SKNode {
    func visit(logic: (_ node: SKNode) -> ()) {
        logic(self)
        children.forEach { $0.visit(logic: logic) }
    }
}

extension SKLabelNode {
    func setup() {
        visit { (node) -> () in
            if let label = node as? SKLabelNode {
                label.fontName = "ARCADE"
                label.fontColor = UIColor(red   : 121.0/255.0,
                                          green : 196.0/255.0,
                                          blue  : 232.0/255.0,
                                          alpha : 1.0)
                label.fontSize = 40.0
                label.horizontalAlignmentMode = .center
                label.text = "00000"
            }
        }
    }
}

class VMLinesScene: SKScene,
                    VMGameDelegate
{
    var bestScoreLabel : SKLabelNode?
    var scoreLabel    : SKLabelNode?
    
    private var soundIsOn : Bool = true
    
    //MARK: - Preload actions
    private var playExplosionSound : SKAction = SKAction.playSoundFileNamed("exposion.mp3",
                                                                    waitForCompletion: false)
    
    //MARK: - Constants
    //MARK: - Action Keys
    let kVMMoveActionKey         = "move"
    let kVMScaleActionKey        = "scale"
    let kVMBackToCenterActionKey = "back"
    let kVMJumpActionKey         = "jump"
    
    //MARK: - Size constants
    let kVMBallSize        = CGSize(width: 40.0, height: 40.0)
    let kVMEmbryoScale     = SCNVector3(0.5, 0.5, 0.5)
    let kVMFullSizeScale   = SCNVector3(1.4, 1.4, 1.4)
    let kVMFutureBallScale = SCNVector3(1, 1, 1)
    
    //MARK: - Durations
    let kVMJumpDuration  = 0.1
    let kVMMoveDuration  = 0.06
    let kVMScaleDuration = 0.2
    let kVMFadeDuration  = 0.3
    
    //MARK: - UIConstants
    let kVMLabelIntent      : CGFloat = 8.0
    let kVMHeaderLabelWidth : CGFloat = 50.0
    
    lazy var jumpDelta : CGFloat = {
        let pileHight = size.width / 9.0
        
        return (pileHight - kVMBallSize.height) / CGFloat(kVMFullSizeScale.y)
    }()
    
    override func didMove(to view: SKView) {
        fillBackground()
    }
    
    //MARK:- Public
    public func switchSound() {
        soundIsOn = !soundIsOn
    }
    
    //MARK:- Private
    private func ballPosition(coordinates: VMElementCoordinates) -> CGPoint {
        let itemWidth = size.width / 9.0
        let headerHeight = size.height - size.width
        let centralCoordinate = VMElementCoordinates(row: 4, column: 4)
        let x = itemWidth * CGFloat(coordinates.column - centralCoordinate.column)
        let y = -itemWidth * CGFloat(coordinates.row - centralCoordinate.row) + (headerHeight - 2 * itemWidth)
        
        return CGPoint(x: x, y: y)
    }
    
    private func headerBallPosition(index: Int) -> CGPoint {
        let width = size.width
        let height = size.height
        let itemWidth = width / 9.0
        let headerHeight = height - width
        
        let x = itemWidth * CGFloat(index - 1)
        let y = (height - headerHeight) / 2.0
        
        return CGPoint(x: x, y: y)
    }
    
    private func headerLabelPosition(headerLabelType: kVMHeaderLabelType) -> CGPoint {
        let width = size.width
        let height = size.height
        let headerHeight = height - width
        
        let x = headerLabelType == .left ?
            (-width / 2.0 + kVMLabelIntent + kVMHeaderLabelWidth) : (width / 2.0 - kVMLabelIntent - kVMHeaderLabelWidth)
        let y = (height - headerHeight) / 2.0 - 20.0
        
        return CGPoint(x: x, y: y)
    }
    
    
    
    private func fillBackground() {
        //background
        let bgNode = SKSpriteNode(imageNamed: "field")
        bgNode.size = size
        bgNode.position = CGPoint.zero

        addChild(bgNode)
        
        //bestScoreLabel
        bestScoreLabel = SKLabelNode()
        bestScoreLabel?.setup()
        bestScoreLabel?.position = headerLabelPosition(headerLabelType: .left)
        
        addChild(bestScoreLabel!)
        
        //scoreLabel
        scoreLabel = SKLabelNode()
        scoreLabel?.setup()
        scoreLabel?.position = headerLabelPosition(headerLabelType: .right)
        
        addChild(scoreLabel!)
    }
    
    private func setupLightForBallScene(ballScene: SCNScene) {
        // create and add a light to the scene
        let lightNode = SCNNode()
        
        let light = SCNLight()
        light.type = .omni
        lightNode.light = light
        lightNode.position = SCNVector3(x: 0, y: 20, z: 10)
        ballScene.rootNode.addChildNode(lightNode)
    }
    
    private func scoreToString(score: Int) -> String {
        var result = String(score)
        
        while result.count < 5 {
            result.insert("0", at: result.startIndex)
        }
        
        return result
    }
    
    //MARK:- Action Helpers
    private func jump(ballNode: SK3DNode) {
        // 1. move down
        let startDown = SKAction.moveBy(x       : 0.0,
                                        y       : -jumpDelta,
                                        duration: kVMJumpDuration)
        let jumpAppex = SKAction.wait(forDuration: 0.06)
        let startSequence = SKAction.sequence([startDown, jumpAppex])
        ballNode.run(startSequence)
        
        // 2. jump
        let jumpUp = SKAction.moveBy(x        : 0.0,
                                     y        : jumpDelta * 2,
                                     duration : kVMJumpDuration)
        let jumpDown = SKAction.moveBy(x        : 0.0,
                                       y        : -jumpDelta * 2,
                                       duration : kVMJumpDuration)
        let jumpSequence = SKAction.sequence([jumpUp, jumpAppex, jumpDown, jumpAppex])
        
        ballNode.run(SKAction.repeatForever(jumpSequence), withKey: kVMJumpActionKey)
    }
    
    //Starting element is the first element in the path
    //Destination element is the last element in the path
    private func movingSequenceForPath(path : [VMMatrixElement]) -> [SKAction] {
        var result = [SKAction]()
        let pileHight = size.width / 9.0
        
        if var element = path.first {
            for i in 1...path.count - 1 {
                let nextElement = path[i]
                
                let deltaX = CGFloat(nextElement.coordinates.column - element.coordinates.column) * pileHight
                let deltaY = -CGFloat(nextElement.coordinates.row - element.coordinates.row) * pileHight
                let move = SKAction.moveBy(x        : deltaX,
                                           y        : deltaY,
                                           duration : kVMMoveDuration)
                result.append(move)
                
                element = nextElement
            }
        }
        
        return result
    }
    
    private func clearAnimations(element: VMMatrixElement) {
        let ballCenter = ballPosition(coordinates:element.coordinates)

        if let ballNode = atPoint(ballCenter) as? SK3DNode {
            ballNode.removeAction(forKey: kVMJumpActionKey)
            //return ball back to the initial position
            let delta = ballCenter.y - ballNode.position.y
            let back = SKAction.moveBy(x       : 0.0,
                                       y       : delta,
                                       duration: self.kVMJumpDuration)
            ballNode.run(back, withKey: kVMBackToCenterActionKey)
        }
    }
    
    private func removeFutureColor(point: CGPoint) {
        if let ballNode = atPoint(point) as? SK3DNode {
            ballNode.removeFromParent()
        }
    }
    
    //MARK: - VMGameDelegate
    func gameOver() {
        DispatchQueue.main.async {}
        removeAllChildren()
        fillBackground()
    }
    
    func pickFutureColors(colors: [String]) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            
            for color in colors {
                let name = String(format: "VMBalls.scnassets/%@.scn", color)
                
                if let ballScene = SCNScene(named: name) {
                    strongSelf.setupLightForBallScene(ballScene: ballScene)
                    
                    let node = SK3DNode(viewportSize: strongSelf.kVMBallSize)
                    node.scnScene = ballScene
                    let position = strongSelf.headerBallPosition(index: colors.firstIndex(of: color)!)
                    
                    strongSelf.removeFutureColor(point: position)
                    
                    node.position = position
                    node.name = color
                    
                    strongSelf.addChild(node)
                }
            }
        }
    }
    
    func addBall(element: VMMatrixElement) {
        DispatchQueue.main.async {}
        if let ball = element.ball,
           let color = ball.color
        {
            let name = String(format: "VMBalls.scnassets/%@.scn", color)
            
            if let ballScene = SCNScene(named: name) {
                addSelectionObserver(element: element)
                
                // create and add a light to the scene
                setupLightForBallScene(ballScene: ballScene)
                
                // retrieve the ball node
                if let ballNode = ballScene.rootNode.childNode(withName    : color,
                                                               recursively : true)
                {
                    switch ball.size {
                    case .embryo:
                        ballNode.scale = kVMEmbryoScale
                        break
                    case .fullSized:
                        ballNode.scale = kVMFullSizeScale
                        break
                    case .none:
                        break
                    }
                }
                
                // set the scene to the view
                let node = SK3DNode(viewportSize: kVMBallSize)
                node.scnScene = ballScene
                node.position = ballPosition(coordinates: element.coordinates)
                node.name = color
                
                addChild(node)
            }
        }
    }
    
    func removeBall(element          : VMMatrixElement,
                    completion block : @escaping (Bool) -> Void)
    {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            //invalidate observer
            strongSelf.removeSelectionObserver(element: element)
            //remove the ballNode from the scene
            let ballCenter = strongSelf.ballPosition(coordinates:element.coordinates)
            
            if let color = element.ball?.color {
                let exposionSceneName = String(format: "ExplodeBall.scnassets/%@.scn", color)
                
                if let ballNode = strongSelf.atPoint(ballCenter) as? SK3DNode,
                   let exposionScene = SCNScene(named: exposionSceneName)
                    {
                    ballNode.scnScene = exposionScene
                    
                    if strongSelf.soundIsOn {
                        ballNode.run(strongSelf.playExplosionSound)
                    }
                    
                    let waitAction = SKAction.wait(forDuration: 0.3)
                    ballNode.run(waitAction) {
                        ballNode.removeFromParent()

                        block(true)
                        DispatchQueue.main.async {
                            
                        }
                    }
                }
            }
        }
    }
    
    func updateScore(score: Int) {
        scoreLabel?.text = scoreToString(score: score)
    }
    
    func updateBestScore(bestScore: Int) {
        bestScoreLabel?.text = scoreToString(score: bestScore)
    }
    
    func growUpBall(element: VMMatrixElement) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            
            let ballCenter = strongSelf.ballPosition(coordinates:element.coordinates)
            
            if let ballNode = strongSelf.atPoint(ballCenter) as? SK3DNode,
               let ballScene = ballNode.scnScene,
               let ball = element.ball
            {
                for childNode in ballScene.rootNode.childNodes {
                    if childNode.name == ball.color {
                        let scaleAction = SCNAction.scale(to        : CGFloat(strongSelf.kVMFullSizeScale.x),
                                                          duration  : strongSelf.kVMScaleDuration)
                        childNode.runAction(scaleAction,
                                            forKey: strongSelf.kVMScaleActionKey)
                    }
                }
            }
        }
    }
    
    func moveBallByPath(path             : [VMMatrixElement],
                        completion block : @escaping (Bool) -> Void)
    {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            
            if let startElement = path.first {
                let ballCenter = strongSelf.ballPosition(coordinates:startElement.coordinates)
                
                if let ballNode = strongSelf.atPoint(ballCenter) as? SK3DNode {
                    //clear all animations from the ballNode
                    strongSelf.clearAnimations(element: startElement)
                
                    let destinationElement = path.last
                    let destinationCoordinates = strongSelf.ballPosition(coordinates:(destinationElement?.coordinates)!)
                    
                    //check if there's a small ball in the destination element
                    let nodeToRemove = strongSelf.atPoint(destinationCoordinates) as? SK3DNode
                    
                    //create move actions sequence for the path
                    let movingSequence = strongSelf.movingSequenceForPath(path: path)
                    
                    //There's no method to run SKAction with key and completion block!
                    ballNode.run(SKAction.sequence(movingSequence)) {[weak self] in
                        guard let strongSelf = self else { return }
                        
                        DispatchQueue.main.async {
                            nodeToRemove?.removeFromParent()
                            
                            if let destinationElement = destinationElement,
                               destinationElement != startElement
                            {
                                //add observer to the destination element
                                //remove observing from the startElement
                                strongSelf.addSelectionObserver(element: destinationElement)
                                strongSelf.removeSelectionObserver(element: startElement)
                            }
                            
                            block(true)
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- KVO
    //observe element's attribute @selected
    //selectionObservers is a dictionary of NSKeyValueObservation
    //with coordinate.description as a key
    //invalidate observers after removing and/or moving ball
    var selectionObservers = [String : NSKeyValueObservation]()
    
    func addSelectionObserver(element: VMMatrixElement) {
        if let coordinates = element.coordinates {
            let selectionObserver = element.observe(\.selected, options: .new)
            { [weak self](element, change) in
                //indicate the selected node
                guard let strongSelf = self else { return }
                let ballCenter = strongSelf.ballPosition(coordinates:coordinates)

                if let ballNode = strongSelf.atPoint(ballCenter) as? SK3DNode {
                    if element.selected {
                        strongSelf.jump(ballNode: ballNode)
                    } else {
                        strongSelf.clearAnimations(element: element)
                    }
                }
            }
            
            selectionObservers[coordinates.description] = selectionObserver
        }
    }
    
    func removeSelectionObserver(element: VMMatrixElement) {
        if let coordinates = element.coordinates,
           let observer = selectionObservers[coordinates.description]
        {
            observer.invalidate()
            selectionObservers[coordinates.description] = nil
        }
    }

}
