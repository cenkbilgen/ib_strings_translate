# ib_strings_translate
Use Google Translate API to convert Xcode IB strings file to different languages.

For a good overview, see:

https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html#//apple_ref/doc/uid/10000171i-CH5-SW1

and specifically,

https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/MaintaingYourOwnStringsFiles/MaintaingYourOwnStringsFiles.html

## Usage 

Just specify the source and target language from the source directory, ie for English to German: 

`ib_strings_translate en de`

there are optional parameters if needed,
`ib_strings_translate [source language] [target langauge] -f [strings file name] -k [Google api key] -u [8/16]`

```
Optional flags
-f string file name, default is ./[target language].lproj/Main.strings
-k Google API key, set here or directly at compile-time (in Translatable file), this overrides
-u [8, 16], use UTF8 or UTF16 for output encoding
```

Make sure the localization is added to the project in Xcode first. You will generally need two files per language, they can be called whatever, but are by default:
1. `Main.strings` (for strings that appear in Interface Builder)
2. `Localizable.strings` (for strings in NSLocalizedString)

### 1. To generate Main.strings
From the Project Info page
or from the menu Editor -> Add Localization -> German (for example).

### 2. To generate Localizable.strings
By default only the `Main.strings` is translated when you run this, you need to specify `Localizable.strings` as the file name on the command-line to translate that instead. But first, use the `genstrings` command line file to generate the base file (need to download it from Apple Developer website, if it's not installed on your system).

After you run `genstrings` it should generate a base `Localizable.strings` file. 
Copy that file into all the language directories you want translations for and ib_translate will update them, translated.
You need to create the directory de.lproj, for example, if you are not using IB at all and didnt' add the localization like above.  NOTE: `genstrings` output will be UTF16 encoded, keep it that way or there's an option to convert it to UTF8 when importing into the project.

To create a translated Localizable.strings files from the English original,
run from the project directory (specifying UTF16 encoding for the output):
`ib_strings_translate en de -f Localizable.strings -u 16`


