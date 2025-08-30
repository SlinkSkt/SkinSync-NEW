//
//  AssetOrRemoteImage.swift
//  SkinSync
//
//  Created by Zhen Xiao on 31/8/2025.
//
// Views/Shared/AssetOrRemoteImage.swift
import SwiftUI

struct AssetOrRemoteImage: View {
    let assetName: String?
    let imageURL: String?
    var placeholderSystemName: String = "photo"

    var body: some View {
        Group {
            if let name = assetName, !name.isEmpty, UIImage(named: name) != nil {
                Image(name).resizable().scaledToFill()
            } else if let urlStr = imageURL, let url = URL(string: urlStr) {
                AsyncRemoteImage(url: url, placeholderSystemName: placeholderSystemName)
            } else {
                Image(systemName: placeholderSystemName).resizable().scaledToFit().padding(12).foregroundStyle(.secondary)
            }
        }
    }
}
