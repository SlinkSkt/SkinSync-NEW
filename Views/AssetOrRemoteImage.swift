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
        if let name = assetName, !name.isEmpty, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else if let urlStr = imageURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: placeholderSystemName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: placeholderSystemName)
                .resizable()
                .scaledToFit()
                .padding(12)
                .foregroundStyle(.secondary)
        }
    }
}
