//
//  main.swift
//  ib_strings_translate
//
//  Created by abc on 2018-12-17.
//  Copyright © 2018 abc. All rights reserved.
//

import Foundation

let command = CommandLine.arguments.first!

guard CommandLine.argc >= 3 else {
  print("\n\n")
  print("Usage \(command) [source language] [target langauge] -f [strings file name] -k [Google api key]\n")
  
  print("Optional flags")
  print("\t-f string file name, default is ./[target language].lproj/Main.strings")
  print("\t-k Google API key, set here or directly at compile-time (in Translatable file), this overrides")
  print("\n")
  
  print("Make sure the localization is added to the project in Xcode first.")
  print("You will need generally need two files per language:")
  print("1. Main.strings (for strings in IB)")
  print("2. Localizable.strings (for strings in NSLocalizedString)")
  print("\n")
  print("1. To generate Main.strings (IB)")
  print("From the Project Info page")
  print("or from the menu Editor -> Add Localization -> German (for example).")
  print("\n")
  print("\nTo create a translated Main.strings files from the English original,")
  print("run from the project directory:")
  print("\(command) en de")
  print("\n")
  print("2. To generate a Localizable.strings")
  print("Use the genstrings command line file. Probably need to download it from Apple Developer website.")
  print("After you run genstrings it should generate a base Localizable.strings file.")
  print("Copy that file into all the languate directories you want translations for and ib_translate will update them, translated.")
  print("You need to create the directory de.lproj, for example, if you are not using IB at all and didnt' add the localization like above")
  print("\n")
  print("\nTo create a translated Localizable.strings files from the English original,")
  print("run from the project directory (specify UTF16 encoding for the output, it's what XCode expects):")
  print("\(command) en de -f Localizable.strings -u 16")
  print("\n\n")
  exit(1)
}

let sourceLanguage = CommandLine.arguments[1]
let targetLanguage = CommandLine.arguments[2]

// MARK: parse arguments

var arguments: [String: String] = [:]

var nextArgumentFlag: String?

for argument in CommandLine.arguments[3..<Int(CommandLine.argc)] {
  
  if argument.hasPrefix("-") {
    
    // token is a flag
    
    guard let flag = argument.last else { continue }
    
    switch flag {
      
    case "f":
      
      nextArgumentFlag = "f"
      
    case "u":
      
      nextArgumentFlag = "u"
      
    case "k":
      
      nextArgumentFlag = "k"
      
    default:
      
      print("Unrecongized argument flag: \(flag)")
      exit(3)
      
    }
    
  } else if nextArgumentFlag != nil {
    
    // token is a flag value
    
    if let flag = nextArgumentFlag {
      arguments[flag] = argument
      nextArgumentFlag = nil // reset
    }
    
  } else {
    
    // don't know what it is
    print("Check arguments.")
    exit(5)
    
  }
  
}

let file = arguments["f"] ?? "Main.strings"

GoogleAPI.key = arguments["k"] ?? GoogleAPI.key

// if specified -u 16 use UTF16 for output, only makes sense when output file specified
// otherwise if nil, use .UTF8 for Main.strings, and .UTF16 for Localizable (it's what XCode expects)
let encoding: String.Encoding = arguments["u"] == "16" ? .utf16 : .utf8

guard GoogleAPI.key != nil else {
  print("Google API Key must be specified at compile time or on command line with -k")
  exit(4)
}

let currentPath = FileManager.default.currentDirectoryPath
let currentURL = URL(fileURLWithPath: currentPath, isDirectory: true)

let url = URL(fileURLWithPath: targetLanguage + ".lproj/" + file, isDirectory: false, relativeTo: currentURL)
print("\(url.absoluteString)")

var output: [String] = []

do {
  
  let contents = try String(contentsOf: url)
  
  // regulate access to output, because translation requests can complete out of order
  // but we want to write the file out in order
  let semaphore = DispatchSemaphore(value: 0)
  
  let lines = contents.components(separatedBy: "\n")
  
  var count = 1
  
  for line in lines {
    
    defer { count += 1 }
    
    print(".", separator: "", terminator: "")
    fflush(UnsafeMutablePointer<FILE>(bitPattern: 0)) // STDOUT is file descriptor 0
    // TODO: new Swift Utility Package has nicer command line progress, use that
    
    if line.trimmingCharacters(in: CharacterSet.whitespaces).hasPrefix("/*") {
      output.append(line)
      continue
    }
    
    let parts = line.components(separatedBy: "\" = \"")

    // debugging
    //print(parts.joined(separator: "🔹"))
    
    if parts.count < 2 {
      output.append(line)
      continue
    }
    
    // check starts with """ and ends ";
    
    // NOTE: Assume the IB generated key for the UI Element (ie "HQ9-5l-duK.normalTitle") never contains
    // the string '" = "'
    // separating on that, the first is the key, all subsequent splits are the value
    
    let ibKey = parts.first! + "\""

    let string = "\"" + parts[1..<parts.endIndex].joined().dropLast()
    
    // print("\(ibKey) -> \(string)")
  
    output.append("/* \(line) */") // the original commented out900-p
    
    string.translate(languageCode: targetLanguage) { (translatedText, error) in
      
      defer { semaphore.signal() }
      
      guard error == nil else {
        print("Translation error for \(string). \(error!.localizedDescription)")
        return
      }
      
      guard let translatedText = translatedText else {
        print("Translated text for \(string) is nil.")
        return
      }
      
      let translatedLine = "\(ibKey) = \(translatedText)\n"
      
      output.append(translatedLine)
      
    }
    
    let _ = semaphore.wait(timeout: DispatchTime.now() + 30)   // some time past the network timeout time
    
  }
  
  let out = output.joined(separator: "\n")
  
  // print(out)
  
  // save a copy of the original (untranslated) strings file, if not already done
  
  let originalURL = url.appendingPathExtension("orig")
  if FileManager.default.fileExists(atPath: originalURL.path) == false {
    try FileManager.default.copyItem(at: url, to: originalURL)
  }

  // save a copy of the current strings copy as backup
  
  let backupURL = url.appendingPathExtension("bak")   
  if FileManager.default.fileExists(atPath: backupURL.path) {
    try FileManager.default.removeItem(at: backupURL)
  }
  try FileManager.default.copyItem(at: url, to: backupURL)
  
  // write out the new translated strings file
  
  try out.write(to: url, atomically: true, encoding: encoding)
  
  print("\nWrote \(url.absoluteString)")
  
} catch {
  
  print("Error: \(error.localizedDescription)")
  
  
  exit(6)
  
}

// waiting semaphore will keep program from exiting before it's done processing
//dispatchMain()

