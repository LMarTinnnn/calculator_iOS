//
//  calculatorBrain.swift
//  calculator
//
//  Created by 刘勇博 on 2017/7/20.
//  Copyright © 2017年 Magicarp. All rights reserved.
//

import Foundation



public extension Double {
    /// SwiftRandom extension
    public static func random(lower: Double = 0, upper: Double = 100) -> Double {
        return (Double(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}

private struct PendingBinaryOperation {
    let operand_1: Double
    let function: (Double, Double) -> Double
    
    func performBinaryOperation(operand_2: Double) -> Double{
        return function(operand_1, operand_2)
    }
}

func doubleOperandToString (operand: Double) -> String {
    if doubleValIsInt(operand) {
        return String(Int(operand))
    } else {
        return String(operand)
    }
}

//cuz inset will change the length of the arrya
//the element with smaller index should be put in front of the one with larger index in the elementAndIndices array
func inserts(elementAndIndices: [(String, Int)], into array: inout [String]) {
    for (str, index) in elementAndIndices {
        array.insert(str, at: index)
    }
    
}



struct CalculatorBrain {
    //property
    var resultIsPending: Bool = false
    var accurate = 4

    var varDict: Dictionary<String, Double> = ["M": 0.0]
    
    var result: Double? {
        get {
            if accumulator != nil {
                return Double(String(format: "%.\(accurate)f", accumulator!))
            } else {
                return nil
            }
        }
    }
    
    var description: String {
        get {
            return descriptionArray.joined()
        }
        set {
            return descriptionArray = [newValue]
        }
    }
    
    //private property
    private var accumulator: Double? {
        didSet {
            if accumulator != nil && shouldAppend {
                descriptionArray.append(doubleOperandToString(operand: accumulator!))
            } else if resultIsPending {
                shouldAppend = true
            }
        }
    }
    
    private var variable: String?
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private var descriptionArray = [String]()
    
    private var operationArray = [Operation]()
    
    private var shouldAppend = true
    
    private enum Operation {
        case constant(Double)
        case variable(String)
        case operationSymbol(String)
        case rand
        case unaryOperation((Double) -> Double)// 一元操作符
        case binaryOperation((Double, Double) -> Double)
        case equals
    }
    
    private var operations: Dictionary<String, Operation> = [
        "π": Operation.constant(Double.pi),
        "Rand": Operation.rand,
        "开方": Operation.unaryOperation(sqrt),
        "cos": Operation.unaryOperation(cos),
        "平方": Operation.unaryOperation({ $0 * $0 }),
        "±": Operation.unaryOperation({ -$0 }),
        //Operation.unaryOperation(changeSign) // math functions are in the "math.swift" in Supporting,
        "×": Operation.binaryOperation({ $0 * $1 }),        //closure
        "÷": Operation.binaryOperation({ $0 / $1 }),
        "+": Operation.binaryOperation({ $0 + $1 }),     // that the swift way to deal with function
        "-": Operation.binaryOperation({ $0 - $1 }),
        "=": Operation.equals
    ]
    
    //public APIs
    
    mutating func setOperand(_ Operand: Double) {
        accumulator = Operand
        operationArray.append(.constant(Operand))
    }
    
    mutating func setOperand(variable named: String) {
        variable = named
        operationArray.append(.variable(named))
        descriptionArray.append("M")
        shouldAppend = false
        accumulator = 0.0
    }
    
    func evaluate(using variables: Dictionary<String, Double>? = nil)
        -> (result: Double?, isPending: Bool, description: String) {
        var innerBrain = CalculatorBrain()
        for process in operationArray {
            switch process {
            case .constant(let operand):
                innerBrain.setOperand(operand)
            case .operationSymbol(let symbol):
                innerBrain.performOperation(symbol)
            case .variable(let named):
                let operand = variables?[named] ?? 0.0
                innerBrain.setOperand(operand)
            default:
                break
            }
        }
        
        innerBrain.performPendingBinaryOperation()
        return (innerBrain.result, innerBrain.resultIsPending, description)
    }
    
    mutating func performPendingBinaryOperation() {
        shouldAppend = false
        if accumulator != nil && pendingBinaryOperation != nil {
            inserts(elementAndIndices: [(")", descriptionArray.count), ("(", 0)], into: &descriptionArray)
            accumulator = pendingBinaryOperation?.performBinaryOperation(operand_2: accumulator!)
            pendingBinaryOperation = nil //no longer in the middle of pendingBinaryOperation
        }
    }
    
    mutating func performOperation(_ Symbol: String) {
        if let operation = operations[Symbol] {
            operationArray.append(.operationSymbol(Symbol))
            
            switch operation {
            case .constant(let value):
                shouldAppend = false
                accumulator = value
                
                // set description
                if isPureInt(string: descriptionArray.last!) {
                    descriptionArray.removeLast()
                }
                
                descriptionArray.append(Symbol)
            case .unaryOperation(let function):
                if accumulator != nil {
                    // set description
                    if !resultIsPending {
                        
                        inserts(elementAndIndices: [(")", descriptionArray.count),("(", 0)], into:&descriptionArray)
                        
                        switch Symbol {
                        case "平方":
                            descriptionArray.append("²")
                        case "开方":
                            descriptionArray.insert("√", at: 0)
                        default:
                            break
                        }
                    } else {
                        //remove the accumulator operated by the unaryOperation
                        if isPureInt(string: descriptionArray.last!) {
                            descriptionArray.removeLast()
                        }
                        
                        switch Symbol {
                        case "平方":
                            descriptionArray.append("(\(doubleOperandToString(operand: accumulator!)))²")
                        case "开方":
                            descriptionArray.append("√(\(doubleOperandToString(operand: accumulator!)))")
                        default:
                            break
                        }
                    }
                    shouldAppend = false
                    
                    // perform unary operation
                    accumulator = function(accumulator!)
                }
                
            case .binaryOperation(let function):
                if accumulator != nil {
                    // perform operation first
                    if resultIsPending {
                        performPendingBinaryOperation() // if there already is a pendingBinaryOperation instance, then perform it with num in the accumulator
                    }
                    pendingBinaryOperation = PendingBinaryOperation(operand_1: accumulator!, function: function)
                    accumulator = nil
                    resultIsPending = true
                    shouldAppend = true
                    
                    // set the description
                    
                    descriptionArray.append(Symbol)
                }
            case .rand:
                accumulator = Double.random(lower: 0, upper: 1)
            case .equals:
                performPendingBinaryOperation()
                resultIsPending = false
            default:
                break
            }
        }
    }
}
