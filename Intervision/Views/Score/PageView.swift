//
//  PageView.swift
//  Intervision
//
//  Created by Reuben on 06/02/2024.
//

import SwiftUI

struct PageView: View {
    
    @Binding var geometry: GeometryProxy
    @Binding var zoomLevel: CGFloat
    let pageNumber: Int
    let aspectRatio: CGFloat = 8.27 / 11.69 // A4 paper aspect ratio
    
    var body: some View {
        ZStack {
            let width = geometry.size.height * aspectRatio * zoomLevel
            let height = geometry.size.height * zoomLevel
            
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: width, height: height)
                .padding()
            
            Text("Page \(pageNumber + 1)")
                .font(.title)
                .foregroundColor(Color.black)
        }
    }
}

#Preview {
    GeometryReader { geometry in
        PageView(geometry: Binding.constant(geometry), zoomLevel: Binding.constant(1.0), pageNumber: 1)
    }
}
