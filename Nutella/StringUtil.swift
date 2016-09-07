//
//  StringUtil.swift
//  Nutella
//
//  Created by Anthony Perritano on 9/6/16.
//  Copyright © 2016 ltg.evl.uic.edu. All rights reserved.
//

import Foundation


extension String {
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = range.lowerBound.samePosition(in: utf16view)
        let to = range.upperBound.samePosition(in: utf16view)
        return NSMakeRange(utf16view.distance(from: utf16view.startIndex, to: from),
                           utf16view.distance(from: from, to: to))
    }
}
