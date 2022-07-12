//
//  ClashRuleProvider.swift
//  ClashX Meta

import Foundation

class ClashRuleProviderResp: Codable {
    let allProviders: [ClashProxyName: ClashRuleProvider]

    init() {
        allProviders = [:]
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.js)
        return decoder
    }

    private enum CodingKeys: String, CodingKey {
        case allProviders = "providers"
    }
}

class ClashRuleProvider: Codable {
    let name: ClashProviderName
    let ruleCount: Int
    let behavior: String
    let type: String
    let updatedAt: String?
}
