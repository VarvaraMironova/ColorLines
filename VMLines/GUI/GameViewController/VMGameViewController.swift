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
    
    weak private var rootView: VMLinesRootView? {
        return viewIfLoaded as? VMLinesRootView
    }

    @IBOutlet var tapGestureRecognizer  : UITapGestureRecognizer!
    
    var game : VMGame?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the scene
        if let rootView = rootView {
            game = VMGame()
            
            rootView.setupSceneForGame(game: game!)
        }
        
        // setup gestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(VMGameViewController.onTapGesture))
    }
    
    @objc func onTapGesture(recognizer: UITapGestureRecognizer) {
        if let rootView = rootView,
           let sceneView = rootView.linesSceneView,
           let game = game
        {
            let location = recognizer.location(in: sceneView)
            let coordinates = rootView.coordinatesForPoint(location: location)
            game.selectElement(coordinates: coordinates)
        }
    }
    
    //MARK: - Actions
    @IBAction func onSoundButton(_ sender: UIButton) {
        if let rootView = rootView {
            rootView.switchSound()
        }
    }
    @IBAction func onRestartButton(_ sender: UIButton) {
        if let game = game {
            game.restart()
        }
    }
}
