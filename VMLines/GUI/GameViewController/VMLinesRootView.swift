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
    @IBOutlet var restartButton  : UIButton!
    
    //MARK: - Public
    public func setupSceneForGame(game: VMGame) {
        if let scene = linesSceneView.scene as? VMLinesScene {
            scene.scaleMode = .aspectFit
            game.gameDelegate = scene
        }
    }
    
    public func coordinatesForPoint(location: CGPoint) -> VMElementCoordinates? {
        let headerHeight = linesSceneView.bounds.size.height - linesSceneView.bounds.size.width
        
        //check if the header was touched
        if location.y < headerHeight {
            return nil
        }
        
        let pileWidth = linesSceneView.bounds.size.width / 9
        
        let row = Int((location.y - headerHeight) / pileWidth)
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
