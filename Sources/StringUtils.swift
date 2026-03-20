//
//  StringUtils.swift
//  Navigator
//
//  Utility for converting Swift camelCase identifiers to kebab-case URL segments.
//

/// Convert a camelCase string to kebab-case.
///
/// Examples:
/// - `"userProfile"` -> `"user-profile"`
/// - `"gettingStarted"` -> `"getting-started"`
/// - `"home"` -> `"home"`
/// - `"APIReference"` -> `"api-reference"`
public func camelToKebab(_ input: String) -> String {
    guard !input.isEmpty else { return input }

    var result = ""
    var previousWasUppercase = false
    var previousWasLetter = false

    for (index, char) in input.enumerated() {
        if char.isUppercase {
            if previousWasLetter && !previousWasUppercase {
                // Transition from lowercase to uppercase: insert hyphen
                result += "-"
            } else if previousWasUppercase {
                // Check if next char is lowercase (end of acronym)
                let nextIndex = input.index(input.startIndex, offsetBy: index + 1, limitedBy: input.endIndex)
                if let nextIndex = nextIndex, nextIndex < input.endIndex, input[nextIndex].isLowercase {
                    if !result.isEmpty {
                        result += "-"
                    }
                }
            }
            result += char.lowercased()
            previousWasUppercase = true
            previousWasLetter = true
        } else {
            result += String(char)
            previousWasUppercase = false
            previousWasLetter = char.isLetter
        }
    }

    return result
}
