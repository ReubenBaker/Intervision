//
//  TestingRegistrationView.swift
//  Intervision
//
//  Created by Reuben on 26/04/2024.
//

import SwiftUI

struct TestingRegistrationView: View {
    
    @StateObject var testingViewModel: TestingViewModel
    
    @State private var showTesterIdInformation = false
    @State private var isSliding = false
    @State private var showTutorialAlert = false
    @State private var showPracticeAlert = false
    
    @FocusState private var testerIdFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Tester ID")
                    .font(.title)
                    .padding()
                
                HStack {
                    TextField("Tester ID", text: $testingViewModel.testerId, prompt: Text(showTesterIdInformation ? "If you have completed any tests before input your Tester ID here, OTHERWISE LEAVE BLANK!" : "Example: 12345678-abcd-4ef0-9876-0123456789ab"))
                        .focused($testerIdFieldFocused)
                    
                    Button {
                        testerIdFieldFocused = false
                        showTesterIdInformation.toggle()
                    } label: {
                        Image(systemName: "questionmark")
                    }
                }
                
                Text("Competencies")
                    .font(.title)
                    .padding()
                
                HStack {
                    Text("Perfomer")
                    
                    Spacer()
                    
                    Picker("", selection: $testingViewModel.performerSkillLevel) {
                        ForEach(Tester.SkillLevel.allCases, id: \.self) { skillLevel in
                            Text(String(describing: skillLevel))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: geometry.size.width / 1.5)
                    .onChange(of: testingViewModel.performerSkillLevel) {
                        testerIdFieldFocused = false
                    }
                }
                
                HStack {
                    Text("Composer")
                    
                    Spacer()
                    
                    Picker("", selection: $testingViewModel.composerSkillLevel) {
                        ForEach(Tester.SkillLevel.allCases, id: \.self) { skillLevel in
                            Text(String(describing: skillLevel))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: geometry.size.width / 1.5)
                    .onChange(of: testingViewModel.composerSkillLevel) {
                        testerIdFieldFocused = false
                    }
                }
                
                HStack {
                    Text("Theorist")
                    
                    Spacer()
                    
                    Picker("", selection: $testingViewModel.theoristSkillLevel) {
                        ForEach(Tester.SkillLevel.allCases, id: \.self) { skillLevel in
                            Text(String(describing: skillLevel))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: geometry.size.width / 1.5)
                    .onChange(of: testingViewModel.theoristSkillLevel) {
                        testerIdFieldFocused = false
                    }
                }
                
                HStack {
                    Text("Music Educator")
                    
                    Spacer()
                    
                    Picker("", selection: $testingViewModel.educatorSkillLevel) {
                        ForEach(Tester.SkillLevel.allCases, id: \.self) { skillLevel in
                            Text(String(describing: skillLevel))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: geometry.size.width / 1.5)
                    .onChange(of: testingViewModel.educatorSkillLevel) {
                        testerIdFieldFocused = false
                    }
                }
                
                HStack {
                    Text("Software Developer")
                    
                    Spacer()
                    
                    Picker("", selection: $testingViewModel.developerSkillLevel) {
                        ForEach(Tester.SkillLevel.allCases, id: \.self) { skillLevel in
                            Text(String(describing: skillLevel))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: geometry.size.width / 1.5)
                    .onChange(of: testingViewModel.developerSkillLevel) {
                        testerIdFieldFocused = false
                    }
                }
                
                Text("Question Count - \(testingViewModel.questionCount)")
                    .font(.title)
                    .padding()
                
                Slider(
                    value: Binding(
                        get: { Double(testingViewModel.questionCount) },
                        set: { testingViewModel.questionCount = Int($0) }
                    ),
                    in: Double(Question.QuestionType.allCases.count)...Double(5 * Question.QuestionType.allCases.count),
                    step: Double(Question.QuestionType.allCases.count)
                ) {
                    Text("")
                } minimumValueLabel: {
                    Text(String(describing: Question.QuestionType.allCases.count))
                } maximumValueLabel: {
                    Text(String(describing: 5 * Question.QuestionType.allCases.count))
                } onEditingChanged: { sliding in
                    isSliding = sliding
                }
                .onChange(of: testingViewModel.questionCount) {
                    testerIdFieldFocused = false
                }
                
                Spacer()
                
                Button {
                    testerIdFieldFocused = false
                    
                    withAnimation(.easeInOut) {
                        showTutorialAlert = true
                    }
                } label: {
                    Text("Start Tests")
                        .font(.title2)
                }
                .alert("Would you like to view the tutorial first?", isPresented: $showTutorialAlert) {
                    Button {
                        testingViewModel.tutorial = true
                    } label: {
                        Text("Yes")
                    }
                    
                    Button {
                        testingViewModel.tutorial = false
                        
                        withAnimation(.easeInOut) {
                            showPracticeAlert = true
                        }
                    } label: {
                        Text("No")
                    }
                }
                .alert("Would you like to complete some practice questions?", isPresented: $showPracticeAlert) {
                    Button {
                        testingViewModel.practice = true
                    } label: {
                        Text("Yes")
                    }
                    
                    Button {
                        testingViewModel.practice = false
                        
                        withAnimation(.easeInOut) {
                            testingViewModel.presentedView = .Questions
                        }
                    } label: {
                        Text("No")
                    }
                }
            }
            .padding()
            .padding(.horizontal, geometry.size.width / 20)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    testerIdFieldFocused = false
                }
            )
            .onExitCommand {
                testerIdFieldFocused = false
            }
        }
    }
}

#Preview {
    TestingRegistrationView(testingViewModel: TestingViewModel())
}
