//
//  IntervisionApp.swift
//  Intervision
//
//  Created by Reuben on 06/02/2024.
//

import SwiftUI

@main
struct IntervisionApp: App {
    
    @StateObject var screenSizeViewModel = ScreenSizeViewModel()
    
    var body: some Scene {
        
        #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        #endif
        
        WindowGroup {
            GeometryReader { geometry in
                ZStack {
                    HomeView()
                        .environmentObject(screenSizeViewModel)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .onAppear {
                            screenSizeViewModel.screenSize = geometry.size
                        }
                        .onChange(of: geometry.size) {
                            screenSizeViewModel.screenSize = geometry.size
                        }
                    
                    /*
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                        
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(.red)
                     */
                }
            }
        }
    }
}
