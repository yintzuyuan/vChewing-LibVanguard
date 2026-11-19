// (c) 2025 and onwards The vChewing Project (LGPL v3.0 License or later).
// ====================
// This code is released under the SPDX-License-Identifier: `LGPL-3.0-or-later`.

import Testing

@testable import Homa

// MARK: - HomaTests4RefreshNodes

/// panda fork：`refreshNodes(containingKeys:)` 只重查含指定鍵的節點、清掉含它們的查詢快取。
struct HomaTests4RefreshNodes {
  final class StatefulLM {
    var sealed: Set<String> = []
    var queried: [[String]] = []

    func query(_ keyArray: [String]) -> [Homa.GramRAW] {
      queried.append(keyArray)
      let value = keyArray.map { sealed.contains($0) ? $0.uppercased() : $0 }.joined()
      return [Homa.GramRAW(keyArray: keyArray, value: value, probability: -Double(keyArray.count), previous: nil)]
    }
  }

  @Test("[Homa] Assembler_RefreshNodesRequeriesOnlySpansContainingChangedKeys")
  func testRefreshNodesRequeriesOnlyAffectedSpans() throws {
    let lm = StatefulLM()
    let assembler = Homa.Assembler(gramQuerier: { lm.query($0) })
    for key in ["a", "b", "c", "d", "e"] { try assembler.insertKey(key) }
    let untouched = assembler.segments[0][1]
    lm.sealed = ["d"]
    lm.queried.removeAll()

    #expect(assembler.refreshNodes(containingKeys: ["d"]))
    #expect(!lm.queried.isEmpty)
    #expect(lm.queried.allSatisfy { $0.contains("d") }, "只重查含 d 的 span：\(lm.queried)")
    #expect(assembler.segments[3][1]?.grams.first?.current == "D")
    #expect(assembler.segments[1][3]?.grams.first?.current == "bcD")
    #expect(assembler.segments[0][1] === untouched)
    #expect(assembler.segments[0][1]?.grams.first?.current == "a")
  }

  @Test("[Homa] Assembler_RefreshNodesPurgesCacheForKeysNotInGrid")
  func testRefreshNodesPurgesCacheForAbsentKeys() throws {
    let lm = StatefulLM()
    let assembler = Homa.Assembler(gramQuerier: { lm.query($0) })
    try assembler.insertKey("x")
    try assembler.dropKey(direction: .rear)
    lm.sealed = ["x"]
    #expect(!assembler.refreshNodes(containingKeys: ["x"]))
    try assembler.insertKey("x")
    #expect(assembler.segments[0][1]?.grams.first?.current == "X", "快取裡的舊結果要清掉")
  }
}
