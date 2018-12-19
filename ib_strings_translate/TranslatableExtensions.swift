//
//  Extensions.swift
//  fastlane_metadata-google_translater
//
//  Created by abc on 2017-05-09.
//  Copyright © 2017 Cenk Bilgen. All rights reserved.
//

import Foundation

// MARK: String, translates description

extension String: Translatable { // conforms just by being CustomStringConvertible
  
  var languageCode: String { return sourceLanguage }
  
}


// MARK: URL is CustomStringConvertible, but we want the contents of the file URL

extension URL {
  
  func translateContents(languageCode: String, completion: @escaping (String?, Error?) -> Void) {
    
    var isContentsAcceptable = false
    
    defer {
      if isContentsAcceptable == false {
        completion(nil, TranslationError.badSource)
      }
    }
    
    guard self.isFileURL else { return }
    guard let data = try? Data(contentsOf: self) else { return }
    guard let contents = String(data: data, encoding: .utf8) else { return }
    isContentsAcceptable = true
    
    contents.translate(languageCode: languageCode, completion: completion)
    
  }
  
}
