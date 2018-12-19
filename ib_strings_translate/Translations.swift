//
//  Translations.swift
//  ib_strings_translate
//
//  Created by abc on 2018-12-18.
//  Copyright © 2018 abc. All rights reserved.
//

import Foundation

// dictionary of AppStore locale code -> Google language code
// only differences seem to be Chinese language related
let languageCodeConversions = ["en-AU": "en", "pt-BR": "pt", "en-CA": "en", "fr-CA": "fr", "da": "da", "nl-NL": "nl", "fi": "fi", "fr-FR": "fr", "de-DE": "de", "el": "el", "id": "id", "it": "it", "ja": "ja", "ko": "ko", "ms": "ms", "es-MX": "es", "no": "no", "pt-PT": "pt", "ru": "ru", "zh-Hans": "zh-CN", "es-ES": "es", "sv": "sv", "th": "th", "zh-Hant": "zh-TW", "tr": "tr", "en-UK": "en", "vi": "vi", "en-US": "en"]


struct Translation: Codable, Hashable {
  
  let id: String // the string identifier, will be the English text
  let lang: String // Google Language Code
  let text: String // the translated text
 
  // new Swift auto-hasher is great!
  // but if we don't remove the translated text from it, then new translations won't overwrite older ones
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(lang)
  }
  
}

class Translations: Codable {
  
  static let shared = Translations()

  var translations: Set<Translation> = [] // keep set of previous ones, to avoid doing again
  
  func saved(id: String, lang: String) -> String? {
    
    return nil
    
  }
  
  // MARK: Loading and Saving

  func load(name: String) {
  
    let url = URL(fileURLWithPath: name, isDirectory: false)
    
    do {
      
      let data = try Data(contentsOf: url)
      let loadedTranslations = try JSONDecoder().decode([Translation].self, from: data)
    
      translations.formUnion(loadedTranslations)
      print("Loaded \(loadedTranslations.count) saved translations")
      
    } catch {
      
      print("Error loading saved \(name) saved translations. \(error.localizedDescription)")
    
    }
    
  }
  
  func save(name: String) {
    
    guard translations.isEmpty == false else { return }
    
    do {
      
      let data = try JSONEncoder().encode(translations)
      
      let url = URL(fileURLWithPath: name, isDirectory: false)
      
      if FileManager.default.fileExists(atPath: name) {
        try FileManager.default.removeItem(at: url)
      }
      
      try data.write(to: url)
      
      print("Saved \(translations.count) translations to \(name)")
      
    } catch {
      
       print("Error saving translations. \(error.localizedDescription)")
    }
    
  }
  
}
