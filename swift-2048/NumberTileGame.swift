//
//  NumberTileGame.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. Released under the terms of the MIT license.
//

import UIKit

///
/// A view controller representing the swift-2048 game. It serves mostly to tie a GameModel and a GameboardView
/// together. Data flow works as follows: user input reaches the view controller and is forwarded to the model. Move
/// orders calculated by the model are returned to the view controller and forwarded to the gameboard view, which
/// performs any animations to update its state.
///

class NumberTileGameViewController: UIViewController {
  // dimension: number of tiles in both directions
  // threshold: value of the winning tile
  var modelSpec: (dimension: Int, threshold: Int) {
    // Made this a computed property to better organize the ownership of the model specification (i.e.
    // this object owns the model, and the model owns the dimension/threshold properties).
    get {
      return (model.dimension, model.threshold)
    }
    // Creates a new model when the spec being set differs, thus, if the specs match then the existing
    // model will persist (thus, consider calling reset if the spec isn't changing).
    set {
      if newValue.dimension != model.dimension || newValue.threshold != newValue.threshold {
        model = GameModel(dimension: newValue.dimension, threshold: newValue.threshold)
      }
    }
  }
  private var model: GameModel! {
    didSet {
      model.delegate = self
    }
  }
  
  @IBOutlet weak var dimensionControl: UISegmentedControl!
  weak var board: GameboardView!
  weak var scoreView: ScoreView!

  // Width of the gameboard
  let boardWidth: CGFloat = 230.0
  // How much padding to place between the tiles
  let thinPadding: CGFloat = 3.0
  let thickPadding: CGFloat = 6.0

  // Amount of space to place between the different component views (gameboard, score view, etc)
  let viewPadding: CGFloat = 10.0

  // Amount that the vertical alignment of the component views should differ from if they were centered
  let verticalViewOffset: CGFloat = 0.0

  init(dimension: Int, threshold: Int) {
    super.init(nibName: nil, bundle: nil)
    defer { // allows for the model didSet-observer to execute inside of init
      model = GameModel(dimension: dimension, threshold: threshold)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    defer { // allows for the model didSet-observer to execute inside of init
      model = GameModel(dimension: 4, threshold: 2048)
    }
  }

  func setupSwipeControls() {
    let upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("up:"))
    upSwipe.numberOfTouchesRequired = 1
    upSwipe.direction = UISwipeGestureRecognizerDirection.Up
    view.addGestureRecognizer(upSwipe)

    let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("down:"))
    downSwipe.numberOfTouchesRequired = 1
    downSwipe.direction = UISwipeGestureRecognizerDirection.Down
    view.addGestureRecognizer(downSwipe)

    let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("left:"))
    leftSwipe.numberOfTouchesRequired = 1
    leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
    view.addGestureRecognizer(leftSwipe)

    let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("right:"))
    rightSwipe.numberOfTouchesRequired = 1
    rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
    view.addGestureRecognizer(rightSwipe)
  }


  @IBAction func shareGameState() {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.mainScreen().scale)
    if let context = UIGraphicsGetCurrentContext() {
      CGContextSaveGState(context)
      CGContextTranslateCTM(context, scoreView.frame.origin.x, scoreView.frame.origin.y)
      scoreView.layer.renderInContext(context)
      CGContextRestoreGState(context)
      CGContextTranslateCTM(context, board.frame.origin.x, board.frame.origin.y)
      board.layer.renderInContext(context)
      
      let gameScreenShot = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext();
      
      let shareGameVC = UIActivityViewController(activityItems: [gameScreenShot], applicationActivities: nil)
      presentViewController(shareGameVC, animated: true, completion: nil)
    }
  }
  
  // View Controller
  override func viewDidLoad()  {
    super.viewDidLoad()
    setupSwipeControls()
    setupGame()
  }

  @IBAction func newGame() {
    if let selectedOption = DimensionalOption(rawValue: dimensionControl.selectedSegmentIndex) where selectedOption.dimension() != modelSpec.dimension {
      modelSpec = (selectedOption.dimension(), model.threshold)
      // board and scoreView and are both weak IUO (implicitly unwrapped optional), thus, they are
      // actually optional but can be (and usually are) treated as non-optional in the code.
      // Removing them from the view hierarchy releases our ownership interest (maintained by our
      // view.subviews property), which allows for a fresh call to setupGame
      board.removeFromSuperview()
      scoreView.removeFromSuperview()
      setupGame()
    } else {
      reset()
    }
  }
  
  func reset() {
    board.reset()
    model.reset()
    model.insertTileAtRandomLocation(2)
    model.insertTileAtRandomLocation(2)
  }

  func setupGame() {
    let vcHeight = view.bounds.size.height
    let vcWidth = view.bounds.size.width

    // This nested function provides the x-position for a component view
    func xPositionToCenterView(v: UIView) -> CGFloat {
      let viewWidth = v.bounds.size.width
      let tentativeX = 0.5*(vcWidth - viewWidth)
      return tentativeX >= 0 ? tentativeX : 0
    }
    // This nested function provides the y-position for a component view
    func yPositionForViewAtPosition(order: Int, views: [UIView]) -> CGFloat {
      assert(views.count > 0)
      assert(order >= 0 && order < views.count)
//      let viewHeight = views[order].bounds.size.height
      let totalHeight = CGFloat(views.count - 1)*viewPadding + views.map({ $0.bounds.size.height }).reduce(verticalViewOffset, combine: { $0 + $1 })
      let viewsTop = 0.5*(vcHeight - totalHeight) >= 0 ? 0.5*(vcHeight - totalHeight) : 0

      // Not sure how to slice an array yet
      var acc: CGFloat = 0
      for i in 0..<order {
        acc += viewPadding + views[i].bounds.size.height
      }
      return viewsTop + acc
    }

    // Create the score view
    let scoreView = ScoreView(backgroundColor: UIColor.blackColor(),
      textColor: UIColor.whiteColor(),
      font: UIFont(name: "HelveticaNeue-Bold", size: 16.0) ?? UIFont.systemFontOfSize(16.0),
      radius: 6)
    scoreView.score = 0

    // Create the gameboard
    let padding: CGFloat = modelSpec.dimension > 5 ? thinPadding : thickPadding
    let v1 = boardWidth - padding*(CGFloat(modelSpec.dimension + 1))
    let width: CGFloat = CGFloat(floorf(CFloat(v1)))/CGFloat(modelSpec.dimension)
    let gameboard = GameboardView(dimension: modelSpec.dimension,
      tileWidth: width,
      tilePadding: padding,
      cornerRadius: 6,
      backgroundColor: UIColor.blackColor(),
      foregroundColor: UIColor.darkGrayColor())

    // Set up the frames
    let views = [scoreView, gameboard]

    var f = scoreView.frame
    f.origin.x = xPositionToCenterView(scoreView)
    f.origin.y = yPositionForViewAtPosition(0, views: views)
    scoreView.frame = f

    f = gameboard.frame
    f.origin.x = xPositionToCenterView(gameboard)
    f.origin.y = yPositionForViewAtPosition(1, views: views)
    gameboard.frame = f


    // Add to game state
    view.addSubview(gameboard)
    board = gameboard
    view.addSubview(scoreView)
    self.scoreView = scoreView

    model.insertTileAtRandomLocation(2)
    model.insertTileAtRandomLocation(2)
  }

  // Misc
  func followUp() {
    let (userWon, _) = model.userHasWon()
    if userWon {
      // TODO: alert delegate we won
      let alertView = UIAlertView()
      alertView.title = "Victory"
      alertView.message = "You won!"
      alertView.addButtonWithTitle("Cancel")
      alertView.show()
      // TODO: At this point we should stall the game until the user taps 'New Game' (which hasn't been implemented yet)
      return
    }

    // Now, insert more tiles
    let randomVal = Int(arc4random_uniform(10))
    model.insertTileAtRandomLocation(randomVal == 1 ? 4 : 2)

    // At this point, the user may lose
    if model.userHasLost() {
      NSLog("You lost...")
      let alertView = UIAlertView()
      alertView.title = "Defeat"
      alertView.message = "You lost..."
      alertView.addButtonWithTitle("Cancel")
      alertView.show()
    }
  }

  // Commands
  @objc(up:)
  func upCommand(r: UIGestureRecognizer!) {
    model.queueMove(MoveDirection.Up,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(down:)
  func downCommand(r: UIGestureRecognizer!) {
    model.queueMove(MoveDirection.Down,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(left:)
  func leftCommand(r: UIGestureRecognizer!) {
    model.queueMove(MoveDirection.Left,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }

  @objc(right:)
  func rightCommand(r: UIGestureRecognizer!) {
    model.queueMove(MoveDirection.Right,
      completion: { (changed: Bool) -> () in
        if changed {
          self.followUp()
        }
      })
  }
}

extension NumberTileGameViewController: GameModelProtocol {
  func scoreChanged(score: Int) {
    scoreView.scoreChanged(newScore: score)
  }

  func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
    board.moveOneTile(from, to: to, value: value)
  }

  func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
    board.moveTwoTiles(from, to: to, value: value)
  }

  func insertTile(location: (Int, Int), value: Int) {
    board.insertTile(location, value: value)
  }
}
