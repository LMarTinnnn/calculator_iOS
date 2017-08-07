//
//  calculatorBrain.swift
//  calculator
//
//  Created by 刘勇博 on 2017/7/20.
//  Copyright © 2017年 Magicarp. All rights reserved.
//

import Foundation

private struct PendingBinaryOperation {
    let operand_1: Double
    let function: (Double, Double) -> Double
    
    func performBinaryOperation(operand_2: Double) -> Double{
        return function(operand_1, operand_2)
    }
}

struct CalculatorBrain {
    //public properties
    var resultIsPending: Bool = false
    var accurate = 4
    var description: String?
    var shouldAppend = true
    var result: Double? {
        get {
            if accumulator != nil {
                return Double(String(format: "%.\(accurate)f", accumulator!))
            } else {
                return nil
            }
        }
    }
    
    //private property
    private var accumulator: Double?
    private var variable: String?
    private var pendingBinaryOperation: PendingBinaryOperation?
    private var operationArray = [Operation]()
    private var varDict: Dictionary<String, Double> = ["M": 0.0]
    
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
        "sin": Operation.unaryOperation(sin),
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
        if shouldAppend {
            operationArray.append(.constant(Operand))
        }
        shouldAppend = true
    }
    
    mutating func setOperand(variable named: String) {
        variable = named
        operationArray.append(.variable(named))
        accumulator = 0.0
    }
    
    
    
    func descriptionMaker(array: [String]) -> String {
        var definedArray = [String]()
        
        for (index,process) in array.enumerated() {
            switch process {
            case "=":
                if !isThereBracketsAtStartAndEnd(in: definedArray) {
                    addBracketsAtStartAndEnd(array: &definedArray)
                }
            case "开方":
                //判断根号和平方号的位置
                if (array[index - 1].thisStringIsDouble != nil) {
                    addSomethingBeforeAndAfterLastElement(
                        before: "√(", after: ")", in: &definedArray)
                    
                } else {
                    if !isThereBracketsAtStartAndEnd(in: definedArray) {
                        addBracketsAtStartAndEnd(array: &definedArray)
                    }
                    definedArray.insert("√", at: 0)
                }
            case "平方":
                if (array[index - 1].thisStringIsDouble != nil) {
                    addSomethingBeforeAndAfterLastElement(
                        before: "(", after: ")²", in: &definedArray)
                } else {
                    if !isThereBracketsAtStartAndEnd(in: definedArray) {
                        addBracketsAtStartAndEnd(array: &definedArray)
                    }
                    definedArray.append("²")
                }
            case "sin", "cos":
                if !isThereBracketsAtStartAndEnd(in: definedArray) {
                    addBracketsAtStartAndEnd(array: &definedArray)
                }
                definedArray.insert(process, at: 0)
            case "M":
                definedArray.append("M")
            default:
                // if double is pure int , then use it's int value
                //which means don't have  ".0"  as suffix
                if let intProcess = process.pureIntegerValueAsString {
                    definedArray.append(intProcess)
                } else {
                    definedArray.append(process)
                }
            }
        }
        
        return definedArray.joined()
    }
    
    func evaluate(using variables: Dictionary<String, Double>? = nil)
        -> (result: Double?, isPending: Bool, description: String) {
            var innerBrain = CalculatorBrain()
            var descriptionArray = [String]()
            
            for process in operationArray {
                switch process {
                case .constant(let operand):
                    innerBrain.setOperand(operand)
                    descriptionArray.append(String(operand))
                case .operationSymbol(let symbol):
                    if !(symbol == "=" && descriptionArray.last == "=") {
                        innerBrain.performOperation(symbol)
                        descriptionArray.append(symbol)
                    }
                case .variable(let named):
                    descriptionArray.append(named)
                    let operand = variables?[named] ?? 0.0
                    innerBrain.setOperand(operand)
                default:
                    break
                }
            }
            
            let description = descriptionMaker(array: descriptionArray)
            
            return (innerBrain.result, innerBrain.resultIsPending, description)
    }
    
    mutating func performPendingBinaryOperation() {
        if accumulator != nil && pendingBinaryOperation != nil {
            accumulator = pendingBinaryOperation?.performBinaryOperation(operand_2: accumulator!)
            pendingBinaryOperation = nil //no longer in the middle of pendingBinaryOperation
        }
    }
    
    mutating func performOperation(_ Symbol: String) {
        if let operation = operations[Symbol] {
            operationArray.append(.operationSymbol(Symbol))
            
            switch operation {
            case .constant(let value):
                accumulator = value
            case .unaryOperation(let function):
                if accumulator != nil {
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

public extension Double {
    /// SwiftRandom extension
    public static func random(lower: Double = 0, upper: Double = 100) -> Double {
        return (Double(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}

public extension String {
    var thisStringIsDouble: Double? {
        return Double(self)
    }
    
    var pureIntegerValueAsString: String? {
        if let double = Double(self) {
            return (double == floor(double) ? String(describing: Int(double)) : nil)
        }
        
        return nil
    }
}

func addBracketsAtStartAndEnd(array: inout [String]) {
    array.append(")")
    array.insert("(", at: 0)
}

func addSomethingBeforeAndAfterLastElement(before e1: String, after e2: String = ")", in array: inout [String]) {
    let length = array.count
    array.insert(e1, at: length - 1)
    array.append(e2)
}

func isThereBracketsAtStartAndEnd(in array: [String]) -> Bool {
    return array.starts(with: ["("]) && array[array.index(before: array.endIndex)] == ")"
}

