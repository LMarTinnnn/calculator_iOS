//
//  ViewController.swift
//  calculator
//
//  Created by 刘勇博 on 2017/7/19.
//  Copyright © 2017年 Magicarp. All rights reserved.
//

import UIKit
// use MVC to seperate the UI and data stucture
// controler should not have calculating part.

class ViewController: UIViewController {
    
    //Controler's Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        displayValue = 0
        screenDiscription.text = ""
    }
    
    //Model
    private var dict = ["M": 0.0]
    private var brain = CalculatorBrain()
    
    
    //View
    @IBOutlet weak var screen: UILabel! {
        didSet {
            //label 默认是不接受交互
            screen.isUserInteractionEnabled = true
            
            let backSpaceRecognizerLeft = UISwipeGestureRecognizer(target: self, action: #selector(backSpace))
            backSpaceRecognizerLeft.direction = .left
            let backSpaceRecognizerRight = UISwipeGestureRecognizer(target: self, action: #selector(backSpace))
            backSpaceRecognizerRight.direction = .right
            screen.addGestureRecognizer(backSpaceRecognizerLeft)
            screen.addGestureRecognizer(backSpaceRecognizerRight)
        }
    }
    
    @IBOutlet weak var screenDiscription: UILabel!
    
    var userIsTyping = false
    
    
    var displayValue: Double { //compute properties
        //作为左值时调用set方法 右值的时候调用get
        get {
            return Double(screen.text!)!
        }
        set {
            if abs(newValue) >= abs(Double(Int64.max)) {
                screen.text = "Error!"
            } else if doubleValIsInt(newValue) {    //change number likes 20.0 to 20
                screen.text = String(Int(newValue))
            } else if newValue.isNaN {
                screen.text = "MATH ERROR"
            } else {
                screen.text = String(newValue)
            }
            
        }
    }
    
    //methods
    func screenIsNotFull(digitNumInScreen num: Int) -> Bool{
        if num < 15 {
            return true
        }
        return false
    }
    
    func notContinuousZero(pressedDigit digit_P: String, displayDigit digit_D: String) -> Bool {
        if digit_P == "0" && digit_D == "0" {
            return false
        }
        return true
    }
    
    func pointIsInScreen(digitInScreen: String) -> Bool {
        if digitInScreen.contains(".") {
            return true
        }
        return false
    }
    
    func backSpace() {
        print("back")
        if screen.text!.characters.count > 1, userIsTyping {
            screen.text?.remove(at: (screen.text?.index(before: (screen.text?.endIndex)!))!)
        }
    }
    
    //actions
    @IBAction func acPressed(_ sender: UIButton) {
        displayValue = 0
        userIsTyping = false
        screenDiscription.text = ""
        brain = CalculatorBrain()
    }
    
    @IBAction func digitPressed(_ sender: UIButton) {
        let digit = sender.currentTitle!
        
        if notContinuousZero(pressedDigit: digit, displayDigit: screen.text!) {
            //avoid "00000" display on the screen.
            if !(digit == "." && pointIsInScreen(digitInScreen: String(screen.text!))) {
                // 如果不是 已经输入过小数点 且 又要输入小数点
                if userIsTyping {
                    if screenIsNotFull(digitNumInScreen: (screen.text!.characters.count)) {
                        screen.text = screen.text! + digit}
                } else {
                    screen.text = digit
                    if digit != "0" {  //第一个数字不为0才改变输入状态
                        userIsTyping = true
                    }
                }
            }
        }
    }
    @IBAction func variablePress(_ sender: UIButton) {
        if !userIsTyping {
            screen.text = "M"
            userIsTyping = false
        }
    }
    
    @IBAction func setVariable(_ sender: UIButton) {
        if userIsTyping || displayValue == 0 {
            dict["M"] = displayValue
            let (result, _, _) = brain.evaluate(using: dict)
            displayValue = result!
    }
}


@IBAction func performOperation(_ sender: UIButton) {
    if screen.text == "M" {
        brain.setOperand(variable: "M")
        userIsTyping = false
        
    } else if userIsTyping || displayValue == 0  {
        brain.setOperand(displayValue)
        userIsTyping = false
    }
    
    if let mathmaticalSymbol = sender.currentTitle {
        brain.performOperation(mathmaticalSymbol)
    }
    
    if let result = brain.result { // cuz brain.result may be not set, so I shouldn't unwrap it here. Instead, use if let to check whethere it set.
        displayValue = result
    }
    
    if brain.description != "" {
        screenDiscription.text = brain.description + (brain.resultIsPending ? "..." : "=")
    }
    
}
}
