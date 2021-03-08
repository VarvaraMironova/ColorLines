//
//  VMLinesRootView.swift
//  VMLines
//
//  Created by Varvara Myronova on 23.02.2021.
//

import UIKit
import SpriteKit

class VMLinesRootView: UIView {
    
    @IBOutlet var linesSceneView : SKView!
    @IBOutlet var soundButton    : UIButton!
    
    //MARK: - Public
    public func setupSceneForGame(game: VMGame) {
        if let scene = linesSceneView.scene as? VMLinesScene {
            scene.scaleMode = .aspectFit
            game.gameDelegate = scene
        }
    }
    
    public func coordinatesForPoint(location: CGPoint) -> VMElementCoordinates {
        let pileWidth = linesSceneView.bounds.size.width / 9
        let row = Int(location.y / pileWidth)
        let column = Int(location.x / pileWidth)
        
        return VMElementCoordinates(row: row, column: column)
    }
    
    public func switchSound() {
        if let scene = linesSceneView.scene as? VMLinesScene {
            soundButton.isSelected = !soundButton.isSelected
            scene.switchSound()
        }
    }
}
