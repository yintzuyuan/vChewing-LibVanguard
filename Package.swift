// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LibVanguard",
  platforms: buildSupportedPlatform {
    #if canImport(Darwin)
      /// Certain cross-platform features in Swift (e.g. Observation) are intentionally
      /// not supported on Apple platform releases prior to their official adoption.
      /// There’s no workaround for this limitation.
      SupportedPlatform.macOS(.v15) // Sonoma
      SupportedPlatform.macCatalyst(.v18) // Sonoma
      SupportedPlatform.iOS(.v18) // iOS 17
      SupportedPlatform.visionOS(.v2) // VisionOS v1
    #endif
  },
  products: buildProducts {
    Product.library(
      name: "LibVanguard",
      targets: ["LibVanguard"]
    )
    Product.library(
      name: "TrieKit",
      targets: ["TrieKit"]
    )
    Product.library(
      name: "Tekkon",
      targets: ["Tekkon"]
    )
    Product.library(
      name: "Homa",
      targets: ["Homa"]
    )
    // Basic components ---
    Product.library(
      name: "SharedCore",
      targets: ["SharedCore"]
    )
    Product.library(
      name: "CandidateKit",
      targets: ["CandidateKit"]
    )
  },
  // panda fork divergence: CSQLite3 inlined as Target (see end of file) instead of sub-package.
  // Reason: SPM rejects local sub-package deps when this package is consumed via stable-version
  // (.exact / from:) pin from bopomofo-keyboard (#471 Stage 3b). Upstream sync requires re-applying
  // this Package.swift patch.
  dependencies: buildPackageDependencies { },
  targets: buildTargets {
    Target.target(
      name: "LibVanguard",
      dependencies: buildTargetDependencies {
        "CandidateKit"
        "Tekkon"
        "Homa"
        "BrailleSputnik"
        "TrieKit"
        "LexiconKit"
        "SharedCore"
      }
    )
    Target.testTarget(
      name: "LibVanguardTests",
      dependencies: buildTargetDependencies {
        "LibVanguard"
      }
    )
    // Tekkon, the phonabet composer.
    Target.target(
      name: "Tekkon",
      path: "./Sources/_Modules/Tekkon"
    )
    Target.testTarget(
      name: "TekkonTests",
      dependencies: buildTargetDependencies {
        "Tekkon"
      },
      path: "./Tests/_Tests4Components/TekkonTests"
    )
    // Homa, the sentence Assembler.
    Target.target(
      name: "Homa",
      path: "./Sources/_Modules/Homa"
    )
    // Shared bundle for all Homa-related tests.
    Target.target(
      name: "HomaSharedTestComponents",
      dependencies: buildTargetDependencies {
        "Homa"
      },
      path: "./Tests/_Tests4Components/_HomaSharedTestComponents"
    )
    Target.testTarget(
      name: "HomaTests",
      dependencies: buildTargetDependencies {
        "Homa"
        "HomaSharedTestComponents"
      },
      path: "./Tests/_Tests4Components/HomaTests"
    )
    // Shared bundle for all tests using factory trie.
    Target.target(
      name: "SharedTrieTestDataBundle",
      path: "./Tests/_Tests4Components/_SharedTrieTestDataBundle",
      resources: buildResources {
        Resource.process("./Resources")
      }
    )
    // LexiconKit, the hub for all subsidiary language models.
    Target.target(
      name: "LexiconKit",
      dependencies: buildTargetDependencies {
        "TrieKit"
        "Homa"
      },
      path: "./Sources/_Modules/LexiconKit"
    )
    Target.testTarget(
      name: "LexiconKitTests",
      dependencies: buildTargetDependencies {
        "Homa"
        "HomaSharedTestComponents"
        "LexiconKit"
        "SharedTrieTestDataBundle"
        "Tekkon"
        "TrieKit"
      },
      path: "./Tests/_Tests4Components/LexiconKitTests"
    )
    // CandidateKit, the basic module for holding candidate pools.
    Target.target(
      name: "CandidateKit",
      dependencies: buildTargetDependencies {
        "SharedCore"
      },
      path: "./Sources/_Modules/CandidateKit"
    )
    Target.testTarget(
      name: "CandidateKitTests",
      dependencies: buildTargetDependencies {
        "CandidateKit"
      },
      path: "./Tests/_Tests4Components/CandidateKitTests"
    )
    // SharedCore, the basic module for holding common protocols.
    Target.target(
      name: "SharedCore",
      dependencies: buildTargetDependencies {
        "SwiftExtension"
      },
      path: "./Sources/_Modules/SharedCore"
    )
    Target.testTarget(
      name: "SharedCoreTests",
      dependencies: buildTargetDependencies {
        "SharedCore"
      },
      path: "./Tests/_Tests4Components/SharedCoreTests"
    )
    // BrailleSputnik, the Braille module.
    Target.target(
      name: "BrailleSputnik",
      dependencies: buildTargetDependencies {
        "Tekkon"
      },
      path: "./Sources/_Modules/BrailleSputnik"
    )
    Target.testTarget(
      name: "BrailleSputnikTests",
      dependencies: buildTargetDependencies {
        "BrailleSputnik"
      },
      path: "./Tests/_Tests4Components/BrailleSputnikTests"
    )
    // VanguardTrieSupport, the data structure for factory dictionary files.
    Target.target(
      name: "TrieKit",
      dependencies: buildTargetDependencies {
        "SwiftExtension"
        // panda fork divergence: was `Target.Dependency.product(name: "CSQLite3", package: "CSQLite3")`
        "CSQLite3"
      },
      path: "./Sources/_Modules/TrieKit"
    )
    Target.testTarget(
      name: "TrieKitTests",
      dependencies: buildTargetDependencies {
        "Homa"
        "Tekkon"
        "TrieKit"
      },
      path: "./Tests/_Tests4Components/TrieKitTests"
    )
    // Swift Extension
    Target.target(
      name: "SwiftExtension",
      path: "./Sources/_Modules/SwiftExtension"
    )
    // panda fork divergence: CSQLite3 inlined as Target (was sub-package via path:).
    // Sources are the existing ./CSQLite3/Sources/CSQLite3/ tree (sqlite3.c + headers, unchanged).
    // cSettings mirror ./CSQLite3/Package.swift buildCSQLiteSettings() but drop `.unsafeFlags(["-w"])`
    // because stable-version-tagged packages reject unsafeFlags. Consumer will see SQLite warnings
    // during build — functionally identical.
    Target.target(
      name: "CSQLite3",
      path: "./CSQLite3/Sources/CSQLite3",
      cSettings: pandaCSQLiteSettings()
    )
  }
)

// MARK: - panda fork divergence: inline CSQLite3 cSettings

func pandaCSQLiteSettings() -> [CSetting] {
  var settings: [CSetting] = [
    .define("SQLITE_THREADSAFE", to: "2"),
    .define("SQLITE_DEFAULT_CACHE_SIZE", to: "-64000"),
    .define("SQLITE_DEFAULT_PAGE_SIZE", to: "4096"),
    .define("SQLITE_DEFAULT_TEMP_CACHE_SIZE", to: "-32000"),
    .define("SQLITE_OMIT_DEPRECATED"),
    .define("SQLITE_OMIT_LOAD_EXTENSION"),
    .define("SQLITE_OMIT_SHARED_CACHE"),
    .define("SQLITE_OMIT_UTF16"),
    .define("SQLITE_OMIT_PROGRESS_CALLBACK"),
    .define("SQLITE_MAX_EXPR_DEPTH", to: "0"),
    .define("SQLITE_USE_ALLOCA"),
    .define("SQLITE_ENABLE_MEMORY_MANAGEMENT"),
    .define("SQLITE_ENABLE_FAST_SECURE_DELETE"),
  ]
  #if os(Windows)
    settings.append(.define("SQLITE_WIN32_MALLOC"))
    settings.append(.define("SQLITE_WIN32_MALLOC_VALIDATE"))
  #endif
  #if canImport(Darwin)
    settings.append(.define("SQLITE_ENABLE_LOCKING_STYLE", to: "1"))
  #endif
  return settings
}

// MARK: - ArrayBuilder

@resultBuilder
enum ArrayBuilder<Element> {
  static func buildEither(first elements: [Element]) -> [Element] {
    elements
  }

  static func buildEither(second elements: [Element]) -> [Element] {
    elements
  }

  static func buildOptional(_ elements: [Element]?) -> [Element] {
    elements ?? []
  }

  static func buildExpression(_ expression: Element) -> [Element] {
    [expression]
  }

  static func buildExpression(_: ()) -> [Element] {
    []
  }

  static func buildBlock(_ elements: [Element]...) -> [Element] {
    elements.flatMap { $0 }
  }

  static func buildArray(_ elements: [[Element]]) -> [Element] {
    Array(elements.joined())
  }
}

func buildTargets(@ArrayBuilder<Target?> targets: () -> [Target?]) -> [Target] {
  targets().compactMap { $0 }
}

func buildStrings(@ArrayBuilder<String?> strings: () -> [String?]) -> [String] {
  strings().compactMap { $0 }
}

func buildProducts(@ArrayBuilder<Product?> products: () -> [Product?]) -> [Product] {
  products().compactMap { $0 }
}

func buildTargetDependencies(
  @ArrayBuilder<Target.Dependency?> dependencies: () -> [Target.Dependency?]
)
  -> [Target.Dependency] {
  dependencies().compactMap { $0 }
}

func buildResources(
  @ArrayBuilder<Resource?> resources: () -> [Resource?]
)
  -> [Resource] {
  resources().compactMap { $0 }
}

func buildPackageDependencies(
  @ArrayBuilder<Package.Dependency?> dependencies: () -> [Package.Dependency?]
)
  -> [Package.Dependency] {
  dependencies().compactMap { $0 }
}

func buildSupportedPlatform(
  @ArrayBuilder<SupportedPlatform?> dependencies: () -> [SupportedPlatform?]
)
  -> [SupportedPlatform]? {
  let result = dependencies().compactMap { $0 }
  return result.isEmpty ? nil : result
}
