//
//  Translatable.swift
//  fastlane_metadata-google_translater
//
//  Created by abc on 2017-05-07.
//  Copyright © 2017 Cenk Bilgen. All rights reserved.
//

import Foundation

protocol Translatable {
  
  var description: String { get }
  
  var languageCode: String { get }
  
}

enum GoogleAPI {
  
  // MARK: Google API Key, assign here or specify on command line
  static var key: String? // = "Ijk35234aiOO"

}

// MARK: Extension

fileprivate typealias JSON = [String: Any]
fileprivate typealias JSONDictionary = [String: JSON]


// NOTE: This extension was written pre-Codable protocol

extension Translatable {
  
  func translate(languageCode targetLanguageCode: String, completion: @escaping (String?, Error?) -> Void) {
        
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    var error: Error?
    var result: String?
    
    guard let apiKey = GoogleAPI.key else {
      error = TranslationError.missingAPIKey
      return
    }
    
  
    guard let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=" + apiKey) else {
      error  = TranslationError.invalidAPIKey
      return
    }
    
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
    
    request.httpMethod = "POST"
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let json = ["q" : description, "source" : languageCode, "target" : targetLanguageCode, "format" : "text"]
    let body = try? JSONSerialization.data(withJSONObject: json, options: [])
    request.httpBody = body
  
    let task = session.dataTask(with: request) { (data, response, netError) in
//      print(request.debugDescription)
//      print(response.debugDescription)
      
      defer {
        completion(result, error)
      }
      
      guard netError == nil else {
        error = netError
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        error = TranslationError.nonHTTPResponse
        return
      }

//	if let data = data {
//		let body = String(data: data, encoding: .utf8)
//		print(body)
//	}
      
      guard httpResponse.statusCode == 200, let data = data else {
        let code = httpResponse.statusCode
        print("HTTP Response: \(code)")
        error = TranslationError.badHTTPResponse(code)
        return
      }
     
      guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? JSONDictionary else {
        error = TranslationError.badJSONResponse
        return
      }
      
      // not sure why api request specifies single target language, but response is in the form of an array of translations
      // only ever seen one entry in the array
      guard let translations = json["data"]?["translations"] as? [JSON] else {
        error = TranslationError.badJSONResponse
        return
      }
      
      if translations.count > 1 {
        print("Returned \(translations.count) translations. Using the first.")
      }
      
      guard let translation = translations.first?["translatedText"] as? String else {
        error = TranslationError.badJSONResponse
        return
      }
      
      result = translation
      
    }
    
    task.taskDescription = "Translate \(languageCode)"
  
    task.resume()
    
  }
  
}


// MARK: Translation Errors

enum TranslationError: Error {
  
  case missingAPIKey
  case invalidAPIKey
  case nonHTTPResponse
  case badHTTPResponse(Int)
  case badJSONResponse
  case badSource

}
