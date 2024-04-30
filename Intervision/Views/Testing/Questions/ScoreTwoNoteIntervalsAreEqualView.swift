//
//  ScoreTwoNoteIntervalsAreEqualView.swift
//  Intervision
//
//  Created by Reuben on 27/04/2024.
//

import SwiftUI

struct ScoreTwoNoteIntervalsAreEqualView: View {
    
    @StateObject var testingViewModel: TestingViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("ScoreTwoNoteIntervalsAreEqual")
                    .font(.title)
                
                if let session = testingViewModel.testSession {
                    let question = session.questions[testingViewModel.currentQuestion]
                    
                    if let questionData = testingViewModel.generateQuestionData(question: question),
                       let barViewModel = questionData.0,
                       let answer = questionData.3 {
                        
                        HStack {
                            Spacer()
                            
                            BarView(barViewModel: barViewModel)
                                .frame(width: geometry.size.width / 2, height: geometry.size.height / 5)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Material.ultraThickMaterial)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .shadow(radius: 10)
                                )
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            
                            Text(String(describing: answer))
                            
                            Spacer()
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Text("Do these two chords contain the same interval?")
                        .font(.title2)
                    
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    
                    Text("\(testingViewModel.currentQuestion + 1)/\(testingViewModel.questionCount)")
                        .font(.title3)
                    
                    Spacer()
                }
                
                Spacer()
                
                NextQuestionButton(testingViewModel: testingViewModel)
            }
        }
    }
}

#Preview {
    ScoreTwoNoteIntervalsAreEqualView(testingViewModel: TestingViewModel())
}
