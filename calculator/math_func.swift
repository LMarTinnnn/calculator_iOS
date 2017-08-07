//
//  math.swift
//  calculator
//
//  Created by 刘勇博 on 2017/7/22.
//  Copyright © 2017年 Magicarp. All rights reserved.
//

import Foundation



func changeSign(operand: Double) -> Double {
    return -1 * operand
}


func abs(operand: Double) -> Double {
    return operand >= 0 ? operand : -operand
}

func doubleValIsInt(_ val:Double) -> Bool {
    return String(val).components(separatedBy: ".")[1] == "0"
}

func isPureInt(string: String) -> Bool {
    
    let scan: Scanner = Scanner(string: string)
    
    var val:Int = 0
    
    return scan.scanInt(&val) && scan.isAtEnd
    
}
