//
//  TestingHomeView.swift
//  Intervision
//
//  Created by Reuben on 26/04/2024.
//

import SwiftUI

struct TestingHomeView: View {
    
    @EnvironmentObject var screenSizeViewModel: ScreenSizeViewModel
    @StateObject var testingViewModel: TestingViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    switch testingViewModel.presentedView {
                    case .Registration:
                        TestingRegistrationView(testingViewModel: testingViewModel)
                    case .Tutorial:
                        TutorialView(testingViewModel: testingViewModel)
                            .frame(width: geometry.size.width / 3)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Material.ultraThickMaterial)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.2))
                                    }
                            )
                            .shadow(radius: 10)
                    case .Questions:
                        QuestionsView(testingViewModel: testingViewModel)
                    case .Results:
                        ResultsView(testingViewModel: testingViewModel)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .environmentObject(screenSizeViewModel)
    }
}

#Preview {
    TestingHomeView(testingViewModel: TestingViewModel())
        .environmentObject(ScreenSizeViewModel())
}
