//
//  UIImage+PixelColor.swift
//  Crazy
//
//  Created by 調 原作 on 2018/05/09.
//  Copyright © 2018年 Monogs. All rights reserved.
//

import UIKit

let pixelDataByteSize = 4

extension UIImage {
    
    func getColor(pos: CGPoint) -> (red: Int, green: Int, blue: Int, alpha: Double)/*UIColor*/ {
        
        //let imageData = CGDataProviderCopyData(CGImageGetDataProvider(self.cgImage!)!)
        guard let imageData = CGDataProvider(data: (self.cgImage!.dataProvider?.data)!)?.data else {
            return (red: Int(255), green: Int(255), blue: Int(255), alpha: Double(0.0))//UIColor.clear
        }
        let data : UnsafePointer = CFDataGetBytePtr(imageData)
        let scale = UIScreen.main.scale
        let address : Int = ((Int(self.size.width) * Int(pos.y * scale)) + Int(pos.x * scale)) * pixelDataByteSize
        let r = CGFloat(data[address])
        let g = CGFloat(data[address+1])
        let b = CGFloat(data[address+2])
        let a = CGFloat(data[address+3])
        
        //return UIColor(red: r, green: g, blue: b, alpha: a)
        return (red: Int(r), green: Int(g), blue: Int(b), alpha: Double(a))
    }
}
