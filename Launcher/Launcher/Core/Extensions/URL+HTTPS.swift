//
//  URL+HTTPS.swift
//  Launcher
//
//  URL extension for converting HTTP to HTTPS
//

import Foundation

extension URL {

  /// Returns a new URL with HTTPS scheme if the current scheme is HTTP
  /// Usage: URL(string: "http://example.com")?.s
  var s: URL {
    guard scheme == "http" else {
      return self
    }

    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    components?.scheme = "https"

    return components?.url ?? self
  }
}
