//
//  VMGameViewController.swift
//  VMLines
//
//  Created by Varvara Myronova on 19.02.2021.
//

import UIKit
import SceneKit
import SpriteKit

class VMGameViewController: UIViewController,
                            UIGestureRecognizerDelegate
                            
{
    

    @IBOutlet var sceneView             : SKView!
    @IBOutlet var tapGestureRecognizer  : UITapGestureRecognizer!
    
    var game : VMGame?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the scene
        if let scene = sceneView.scene as? VMLinesScene {
            scene.scaleMode = .aspectFit
            game = VMGame(delegate: scene)
        }
        
        // setup gestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(VMGameViewController.onTapGesture))
    }
    
    @objc func onTapGesture(recognizer: UITapGestureRecognizer) {
        if let game = game {
            let location = recognizer.location(in: sceneView)
            let coordinates = coordinatesByLocation(location: location)
            game.selectElement(coordinates: coordinates)
        }
    }
    
    //MARK: - Heplers
    private func coordinatesByLocation(location: CGPoint) -> VMElementCoordinates {
        let pileWidth = sceneView.bounds.size.width / 9
        let row = Int(location.y / pileWidth)
        let column = Int(location.x / pileWidth)
        
        return VMElementCoordinates(row: row, column: column)
    }
    
}
