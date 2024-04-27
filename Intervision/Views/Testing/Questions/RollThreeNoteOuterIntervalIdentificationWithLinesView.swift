//
//  RollThreeNoteOuterIntervalIdentificationWithLinesView.swift
//  Intervision
//
//  Created by Reuben on 27/04/2024.
//

import SwiftUI

struct RollThreeNoteOuterIntervalIdentificationWithLinesView: View {
    
    @StateObject var testingViewModel: TestingViewModel
    
    var body: some View {
        VStack {
            Text("RollThreeNoteOuterIntervalIdentificationWithLines")
            
            NextQuestionButton(testingViewModel: testingViewModel)
        }
    }
}

#Preview {
    RollThreeNoteOuterIntervalIdentificationWithLinesView(testingViewModel: TestingViewModel())
}
