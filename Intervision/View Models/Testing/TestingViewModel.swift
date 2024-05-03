//
//  TestingViewModel.swift
//  Intervision
//
//  Created by Reuben on 26/04/2024.
//

import Foundation
import SwiftUI
import Combine

class TestingViewModel: ObservableObject {
    var tester: Tester?
    var testSession: TestSession?

    @Published var testerId = ""
    
    @Published var performerSkillLevel = Skill.SkillLevel.None
    @Published var composerSkillLevel = Skill.SkillLevel.None
    @Published var theoristSkillLevel = Skill.SkillLevel.None
    @Published var educatorSkillLevel = Skill.SkillLevel.None
    @Published var developerSkillLevel = Skill.SkillLevel.None
    
    @Published var rollRowsViewType = BarRowsView.ViewType.Piano
    @Published var showPiano = false
    
    @Published var tutorial = false {
        didSet {
            if tutorial {
                withAnimation(.easeInOut) {
                    self.presentedView = .Tutorial
                }
            }
        }
    }
    
    @Published var practice = false
    @Published var random = false
    @Published var presentedView: PresentedView = .Registration
    @Published var presentedQuestionView: PresentedQuestionView = .CountdownTimer
    @Published var showSavingErrorAlert = false
    @Published var showSavingSuccessAlert = false
    
    @Published var countdown = 1
    @Published var progress = 1.0
    private let totalSeconds = 1
    private var countdownTimer: AnyCancellable?
    
    var isFirstQuestion = true
    
    var isLastQuestion: Bool {
        self.calculateIsLastQuestion()
    }
    
    @Published var currentQuestionIndex = 0 {
        didSet {
            if currentQuestionIndex == 0 {
                self.isFirstQuestion = true
            }
            
            if self.practice || self.random {
                self.randomlyGenerateQuestionData(question: self.testSession?.questions[currentQuestionIndex])
            } else {
                self.getTestQuestionData(currentQuestionIndex)
            }
            
            self.questionResults = []
            self.questionMarked = false
        }
    }
    
    @Published var currentQuestionData: (BarViewModel?, (RollViewModel, IntervalLinesViewModel)?, [Answer]?)?
    @Published var questionResults: [Bool] = []
    @Published var questionMarked = false
    @Published var questionVisible = false
    
    @Published var answerTime = 0.0
    @Published var answerProgress = 1.0
    let maximumAnswerTime = 60.0
    private var answerTimer: AnyCancellable?
}

extension TestingViewModel {
    enum PresentedView {
        case Registration
        case Tutorial
        case Questions
        case Results
    }
    
    enum PresentedQuestionView {
        case CountdownTimer
        case Question
    }
    
    enum Answer: String, CaseIterable {
        case Minor2nd = "Min. 2nd"
        case Major2nd = "Maj. 2nd"
        case Minor3rd = "Min. 3rd"
        case Major3rd = "Maj. 3rd"
        case Perfect4th = "Perf. 4th"
        case Tritone = "Tritone"
        case Perfect5th = "Perf. 5th"
        case Minor6th = "Min. 6th"
        case Major6th = "Maj. 6th"
        case Minor7th = "Min. 7th"
        case Major7th = "Maj. 7th"
        case Octave = "Octave"
        
        case True = "True"
        case False = "False"
        
        var isBoolQuestion: Bool {
            switch self {
            case .True, .False:
                    return true
            default:
                    return false
            }
        }
        
        init?(semitones: Int? = nil, boolValue: Bool? = nil) {
            if let boolValue = boolValue {
                self = boolValue ? .True : .False
                
                return
            }

            if let semitones = semitones {
                switch semitones {
                    case 1:
                        self = .Minor2nd
                    case 2:
                        self = .Major2nd
                    case 3:
                        self = .Minor3rd
                    case 4:
                        self = .Major3rd
                    case 5:
                        self = .Perfect4th
                    case 6:
                        self = .Tritone
                    case 7:
                        self = .Perfect5th
                    case 8:
                        self = .Minor6th
                    case 9:
                        self = .Major6th
                    case 10:
                        self = .Minor7th
                    case 11:
                        self = .Major7th
                    case 12:
                        self = .Octave
                    default:
                        return nil
                }
                
                return
            }

            return nil
        }
    }
}

extension TestingViewModel {
    func startTests() {
        var testerSkills: [Skill] = []
        
        testerSkills.append(Skill(type: .Performer, level: self.performerSkillLevel))
        testerSkills.append(Skill(type: .Composer, level: self.composerSkillLevel))
        testerSkills.append(Skill(type: .Theorist, level: self.theoristSkillLevel))
        testerSkills.append(Skill(type: .Educator, level: self.educatorSkillLevel))
        testerSkills.append(Skill(type: .Developer, level: self.developerSkillLevel))
        
        let testerId: UUID = UUID(uuidString: self.testerId) ?? UUID()
        
        self.tester = Tester(skills: testerSkills, id: testerId)
        
        if let tester = self.tester {
            if self.practice {
                self.testSession = TestSession(tester: tester, questionCount: 30)
            } else {
                self.testSession = TestSession(tester: tester, questionCount: 30)
            }
        }
    
        self.currentQuestionIndex = 0
        self.goToNextQuestion()
    }
    
    func startCountdown() {
        self.countdown = self.totalSeconds
        self.progress = 1.0
        
        if self.isFirstQuestion {
            self.isFirstQuestion = false
        } else {
            self.currentQuestionIndex += 1
        }
        
        self.countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            if self.countdown > 0 {
                withAnimation(.easeInOut) {
                    self.countdown -= 1
                    self.progress = CGFloat(self.countdown) / CGFloat(self.totalSeconds)
                }
            } else {
                self.countdownTimer?.cancel()
                self.countdownTimer = nil
                self.goToQuestion()
            }
        }
    }
    
    func startAnswerTimer() {
        self.answerTime = 0.0
        self.answerProgress = 1.0
        
        self.answerTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            if self.answerTime < self.maximumAnswerTime {
                self.answerTime += 0.01
                self.answerProgress = CGFloat(self.answerTime) / CGFloat(self.maximumAnswerTime)
            } else {
                self.stopAnswerTimer()
                
                if !self.questionMarked {
                    self.markQuestion()
                }
            }
        }
    }
    
    func stopAnswerTimer() {
        self.answerTimer?.cancel()
        self.answerTimer = nil
    }
    
    func goToQuestion() {
        withAnimation(.easeInOut) {
            self.presentedView = .Questions
            self.presentedQuestionView = .Question
            self.questionVisible = true
            self.startAnswerTimer()
        }
    }
    
    func goToNextQuestion() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.presentedView = .Questions
                self.presentedQuestionView = .CountdownTimer
            }
        }
    }
    
    func goToResults() {
        withAnimation(.easeInOut) {
            self.presentedView = .Results
        }
    }
    
    private func calculateIsLastQuestion() -> Bool {
        return self.currentQuestionIndex + 1 == self.testSession?.questionCount
    }
    
    func randomlyGenerateQuestionData(question: Question?) {
        guard let question = question else { self.currentQuestionData = nil; return }
        
        let key: Bar.KeySignature = Bar.KeySignature.allCases.randomElement() ?? .CMajor
        let bar = Bar(chords: [Chord(notes: [])], clef: .Treble, timeSignature: .custom(beats: 4, noteValue: 4), repeat: nil, doubleLine: false, keySignature: key)
        let lowestStartingNote = Note(
            pitch: question.type.isScoreQuestion ? .B : .C,
            octave: question.type.isScoreQuestion ? .small : .subContra,
            duration: .quarter,
            isRest: false,
            isDotted: false,
            hasAccent: false
        )
        
        let quarterRest = Note(
            duration: .quarter,
            isRest: true,
            isDotted: false,
            hasAccent: false
        )
        
        let halfRest = Note(
            duration: .half,
            isRest: true,
            isDotted: false,
            hasAccent: false
        )
        
        switch question.type {
        case .ScoreTwoNoteIntervalIdentification, .RollTwoNoteIntervalIdentification:
            let lowestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNoteSemitoneIncrease = Int.random(in: 0...12)
            let highestNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 1)...(lowestNoteSemitoneIncrease + 12))
            let answer = Answer(semitones: highestNoteSemitoneIncrease - lowestNoteSemitoneIncrease)
            
            for _ in 0..<lowestNoteSemitoneIncrease {
                lowestNote.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNoteSemitoneIncrease {
                highestNote.increaseSemitone(sharps: key.sharps)
            }
            
            if question.type.isScoreQuestion {
                bar.chords[0].notes.append(lowestNote)
                bar.chords[0].notes.append(highestNote)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: [halfRest]))
                
                let barViewModel = BarViewModel(
                    bar: bar,
                    ledgerLines: 5,
                    showClef: true,
                    showKey: true,
                    showTime: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (barViewModel, nil, [answer])
                } else {
                    self.currentQuestionData = nil
                }
            } else {
                bar.chords[0].notes.append(quarterRest)
                bar.chords.append(Chord(notes: []))
                bar.chords[1].notes.append(lowestNote)
                bar.chords[1].notes.append(highestNote)
                bar.chords.append(Chord(notes: [halfRest]))
                
                let rollViewModel = RollViewModel(scoreManager: ScoreManager(), parts: [Part(bars: [[bar]])], octaves: 3)
                rollViewModel.parts = [Part(bars: [[bar]])]
                
                let intervalLinesViewModel = IntervalLinesViewModel(
                    segments: rollViewModel.segments ?? [],
                    parts: rollViewModel.parts ?? [], 
                    groups: rollViewModel.partGroups,
                    harmonicIntervalLinesType: .all,
                    showMelodicIntervalLines: false,
                    barIndex: 0, barWidth: .zero,
                    rowWidth: .zero,
                    rowHeight: .zero,
                    harmonicIntervalLineColors: question.intervalLinesType == .InvertedLines ? RollViewModel.invertedHarmonicIntervalLineColors : RollViewModel.harmonicIntervalLineColors,
                    melodicIntervalLineColors: [],
                    viewableMelodicLines: [],
                    showInvertedIntervals: question.intervalLinesType == .InvertedLines,
                    showZigZags: question.intervalLinesType == .InvertedLines, 
                    testing: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (nil, (rollViewModel, intervalLinesViewModel), [answer])
                } else {
                    self.currentQuestionData = nil
                }
            }
        case .ScoreThreeNoteInnerIntervalsIdentification, .RollThreeNoteInnerIntervalsIdentification:
            let lowestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let middleNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNoteSemitoneIncrease = Int.random(in: 0...12)
            let highestNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 4)...(lowestNoteSemitoneIncrease + 12))
            let middleNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 1)...(highestNoteSemitoneIncrease - 1))
            let answer1 = Answer(semitones: middleNoteSemitoneIncrease - lowestNoteSemitoneIncrease)
            let answer2 = Answer(semitones: highestNoteSemitoneIncrease - middleNoteSemitoneIncrease)
            
            for _ in 0..<lowestNoteSemitoneIncrease {
                lowestNote.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<middleNoteSemitoneIncrease {
                middleNote.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNoteSemitoneIncrease {
                highestNote.increaseSemitone(sharps: key.sharps)
            }
            
            if question.type.isScoreQuestion {
                bar.chords[0].notes.append(lowestNote)
                bar.chords[0].notes.append(middleNote)
                bar.chords[0].notes.append(highestNote)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: [halfRest]))
                
                let barViewModel = BarViewModel(
                    bar: bar,
                    ledgerLines: 5,
                    showClef: true,
                    showKey: true,
                    showTime: true
                )
                
                if let answer1 = answer1,
                   let answer2 = answer2 {
                    self.currentQuestionData = (barViewModel, nil, [answer1, answer2])
                } else {
                    self.currentQuestionData = nil
                }
            } else {
                bar.chords[0].notes.append(quarterRest)
                bar.chords.append(Chord(notes: []))
                bar.chords[1].notes.append(lowestNote)
                bar.chords[1].notes.append(middleNote)
                bar.chords[1].notes.append(highestNote)
                bar.chords.append(Chord(notes: [halfRest]))
                
                let rollViewModel = RollViewModel(scoreManager: ScoreManager(), parts: [Part(bars: [[bar]])], octaves: 3)
                rollViewModel.parts = [Part(bars: [[bar]])]
                
                let intervalLinesViewModel = IntervalLinesViewModel(
                    segments: rollViewModel.segments ?? [],
                    parts: rollViewModel.parts ?? [],
                    groups: rollViewModel.partGroups,
                    harmonicIntervalLinesType: .all,
                    showMelodicIntervalLines: false,
                    barIndex: 0, barWidth: .zero,
                    rowWidth: .zero,
                    rowHeight: .zero,
                    harmonicIntervalLineColors: question.intervalLinesType == .InvertedLines ? RollViewModel.invertedHarmonicIntervalLineColors : RollViewModel.harmonicIntervalLineColors,
                    melodicIntervalLineColors: [],
                    viewableMelodicLines: [],
                    showInvertedIntervals: question.intervalLinesType == .InvertedLines,
                    showZigZags: question.intervalLinesType == .InvertedLines,
                    testing: true
                )
                
                if let answer1 = answer1,
                   let answer2 = answer2 {
                    self.currentQuestionData = (nil, (rollViewModel, intervalLinesViewModel), [answer1, answer2])
                } else {
                    self.currentQuestionData = nil
                }
            }
        case .ScoreThreeNoteOuterIntervalIdentification, .RollThreeNoteOuterIntervalIdentification:
            let lowestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let middleNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNoteSemitoneIncrease = Int.random(in: 0...12)
            let highestNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 4)...(lowestNoteSemitoneIncrease + 12))
            let middleNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 1)...(highestNoteSemitoneIncrease - 1))
            let answer = Answer(semitones: highestNoteSemitoneIncrease - lowestNoteSemitoneIncrease)
            
            for _ in 0..<lowestNoteSemitoneIncrease {
                lowestNote.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<middleNoteSemitoneIncrease {
                middleNote.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNoteSemitoneIncrease {
                highestNote.increaseSemitone(sharps: key.sharps)
            }
            
            if question.type.isScoreQuestion {
                bar.chords[0].notes.append(lowestNote)
                bar.chords[0].notes.append(middleNote)
                bar.chords[0].notes.append(highestNote)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: [halfRest]))
                
                let barViewModel = BarViewModel(
                    bar: bar,
                    ledgerLines: 5,
                    showClef: true,
                    showKey: true,
                    showTime: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (barViewModel, nil, [answer])
                } else {
                    self.currentQuestionData = nil
                }
            } else {
                bar.chords[0].notes.append(quarterRest)
                bar.chords.append(Chord(notes: []))
                bar.chords[1].notes.append(lowestNote)
                bar.chords[1].notes.append(middleNote)
                bar.chords[1].notes.append(highestNote)
                bar.chords.append(Chord(notes: [halfRest]))
                
                let rollViewModel = RollViewModel(scoreManager: ScoreManager(), parts: [Part(bars: [[bar]])], octaves: 3)
                rollViewModel.parts = [Part(bars: [[bar]])]
                
                let intervalLinesViewModel = IntervalLinesViewModel(
                    segments: rollViewModel.segments ?? [],
                    parts: rollViewModel.parts ?? [],
                    groups: rollViewModel.partGroups,
                    harmonicIntervalLinesType: .all,
                    showMelodicIntervalLines: false,
                    barIndex: 0, barWidth: .zero,
                    rowWidth: .zero,
                    rowHeight: .zero,
                    harmonicIntervalLineColors: question.intervalLinesType == .InvertedLines ? RollViewModel.invertedHarmonicIntervalLineColors : RollViewModel.harmonicIntervalLineColors,
                    melodicIntervalLineColors: [],
                    viewableMelodicLines: [],
                    showInvertedIntervals: question.intervalLinesType == .InvertedLines,
                    showZigZags: question.intervalLinesType == .InvertedLines,
                    testing: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (nil, (rollViewModel, intervalLinesViewModel), [answer])
                } else {
                    self.currentQuestionData = nil
                }
            }
        case .ScoreChordsAreInversions, .RollChordsAreInversions:
            let lowestNote1 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let middleNote1 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote1 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNote2 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let middleNote2 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote2 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNoteSemitoneIncrease = Int.random(in: 0...12)
            let highestNoteSemitoneIncrease = ((lowestNoteSemitoneIncrease + 6)...(lowestNoteSemitoneIncrease + 12)).filter { $0 != lowestNoteSemitoneIncrease + 12 }.randomElement() ?? Int.random(in: (lowestNoteSemitoneIncrease + 6)...(lowestNoteSemitoneIncrease + 12))
            let middleNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 3)...(highestNoteSemitoneIncrease - 3))
            
            for _ in 0..<lowestNoteSemitoneIncrease {
                lowestNote1.increaseSemitone(sharps: key.sharps)
                lowestNote2.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<middleNoteSemitoneIncrease {
                middleNote1.increaseSemitone(sharps: key.sharps)
                middleNote2.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNoteSemitoneIncrease {
                highestNote1.increaseSemitone(sharps: key.sharps)
                highestNote2.increaseSemitone(sharps: key.sharps)
            }
            
            if question.type.isScoreQuestion {
                bar.chords[0].notes.append(lowestNote1)
                bar.chords[0].notes.append(middleNote1)
                bar.chords[0].notes.append(highestNote1)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: []))
            } else {
                bar.chords[0].notes.append(quarterRest)
                bar.chords.append(Chord(notes: []))
                bar.chords[1].notes.append(lowestNote1)
                bar.chords[1].notes.append(middleNote1)
                bar.chords[1].notes.append(highestNote1)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: []))
            }
            
            if Bool.random() { // Apply 1st or 2nd inversion
                lowestNote2.increaseOctave()
            } else {
                lowestNote2.increaseOctave()
                middleNote2.increaseOctave()
            }
            
            let answer = Answer(boolValue: Bool.random())
            
            if answer == .False {
                let semitonesToAdjust = Int.random(in: 1...2) * (Bool.random() ? 1 : -1)
                
                if Bool.random() { // Adjust lowest note
                    if semitonesToAdjust > 0 {
                        for _ in 0..<semitonesToAdjust {
                            lowestNote2.increaseSemitone(sharps: key.sharps)
                        }
                    } else {
                        for _ in 0..<abs(semitonesToAdjust) {
                            lowestNote2.decreaseSemitone(sharps: key.sharps)
                        }
                    }
                } else { // Adjust middle note
                    if semitonesToAdjust > 0 {
                        for _ in 0..<semitonesToAdjust {
                            middleNote2.increaseSemitone(sharps: key.sharps)
                        }
                    } else {
                        for _ in 0..<abs(semitonesToAdjust) {
                            middleNote2.decreaseSemitone(sharps: key.sharps)
                        }
                    }
                }
            }
            
            if question.type.isScoreQuestion {
                bar.chords[2].notes.append(lowestNote2)
                bar.chords[2].notes.append(middleNote2)
                bar.chords[2].notes.append(highestNote2)
                bar.chords.append(Chord(notes: [quarterRest]))
                
                let barViewModel = BarViewModel(
                    bar: bar,
                    ledgerLines: 5,
                    showClef: true,
                    showKey: true,
                    showTime: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (barViewModel, nil, [answer])
                } else {
                    self.currentQuestionData = nil
                }
            } else {
                bar.chords[3].notes.append(lowestNote2)
                bar.chords[3].notes.append(middleNote2)
                bar.chords[3].notes.append(highestNote2)
                
                let rollViewModel = RollViewModel(scoreManager: ScoreManager(), parts: [Part(bars: [[bar]])], octaves: 3)
                rollViewModel.parts = [Part(bars: [[bar]])]
                
                let intervalLinesViewModel = IntervalLinesViewModel(
                    segments: rollViewModel.segments ?? [],
                    parts: rollViewModel.parts ?? [],
                    groups: rollViewModel.partGroups,
                    harmonicIntervalLinesType: .all,
                    showMelodicIntervalLines: false,
                    barIndex: 0, barWidth: .zero,
                    rowWidth: .zero,
                    rowHeight: .zero,
                    harmonicIntervalLineColors: question.intervalLinesType == .InvertedLines ? RollViewModel.invertedHarmonicIntervalLineColors : RollViewModel.harmonicIntervalLineColors,
                    melodicIntervalLineColors: [],
                    viewableMelodicLines: [],
                    showInvertedIntervals: question.intervalLinesType == .InvertedLines,
                    showZigZags: question.intervalLinesType == .InvertedLines,
                    testing: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (nil, (rollViewModel, intervalLinesViewModel), [answer])
                } else {
                    self.currentQuestionData = nil
                }
            }
        case .ScoreTwoNoteIntervalsAreEqual, .RollTwoNoteIntervalsAreEqual:
            let lowestNote1 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote1 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNote2 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let highestNote2 = Note(
                pitch: lowestStartingNote.pitch,
                octave: lowestStartingNote.octave,
                duration: .quarter,
                isRest: false,
                isDotted: false,
                hasAccent: false
            )
            
            let lowestNoteSemitoneIncrease = Int.random(in: 0...12)
            let highestNoteSemitoneIncrease = Int.random(in: (lowestNoteSemitoneIncrease + 3)...(lowestNoteSemitoneIncrease + 12))
            
            for _ in 0..<lowestNoteSemitoneIncrease {
                lowestNote1.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNoteSemitoneIncrease {
                highestNote1.increaseSemitone(sharps: key.sharps)
            }
            
            if question.type.isScoreQuestion {
                bar.chords[0].notes.append(lowestNote1)
                bar.chords[0].notes.append(highestNote1)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: []))
            } else {
                bar.chords[0].notes.append(quarterRest)
                bar.chords.append(Chord(notes: []))
                bar.chords[1].notes.append(lowestNote1)
                bar.chords[1].notes.append(highestNote1)
                bar.chords.append(Chord(notes: [quarterRest]))
                bar.chords.append(Chord(notes: []))
            }
            
            let answer = Answer(boolValue: Bool.random())
            let lowestNote2SemitoneIncrease = (0...12).filter { $0 != lowestNoteSemitoneIncrease }.randomElement() ?? Int.random(in: 0...12)
            let highestNote2SemitoneIncrease = lowestNote2SemitoneIncrease + highestNoteSemitoneIncrease - lowestNoteSemitoneIncrease
            
            for _ in 0..<lowestNote2SemitoneIncrease {
                lowestNote2.increaseSemitone(sharps: key.sharps)
            }
            
            for _ in 0..<highestNote2SemitoneIncrease {
                highestNote2.increaseSemitone(sharps: key.sharps)
            }
            
            if answer == .False {
                let semitonesToAdjust = Int.random(in: 1...2) * (Bool.random() ? 1 : -1)
                
                if semitonesToAdjust > 0 {
                    for _ in 0..<semitonesToAdjust {
                        highestNote2.increaseSemitone(sharps: key.sharps)
                    }
                } else {
                    for _ in 0..<abs(semitonesToAdjust) {
                        highestNote2.decreaseSemitone(sharps: key.sharps)
                    }
                }
            }
            
            if question.type.isScoreQuestion {
                bar.chords[2].notes.append(lowestNote2)
                bar.chords[2].notes.append(highestNote2)
                bar.chords.append(Chord(notes: [quarterRest]))
                
                let barViewModel = BarViewModel(
                    bar: bar,
                    ledgerLines: 5,
                    showClef: true,
                    showKey: true,
                    showTime: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (barViewModel, nil, [answer])
                } else {
                    self.currentQuestionData = nil
                }
            } else {
                bar.chords[3].notes.append(lowestNote2)
                bar.chords[3].notes.append(highestNote2)
                
                let rollViewModel = RollViewModel(scoreManager: ScoreManager(), parts: [Part(bars: [[bar]])], octaves: 3)
                rollViewModel.parts = [Part(bars: [[bar]])]
                
                let intervalLinesViewModel = IntervalLinesViewModel(
                    segments: rollViewModel.segments ?? [],
                    parts: rollViewModel.parts ?? [],
                    groups: rollViewModel.partGroups,
                    harmonicIntervalLinesType: .all,
                    showMelodicIntervalLines: false,
                    barIndex: 0, barWidth: .zero,
                    rowWidth: .zero,
                    rowHeight: .zero,
                    harmonicIntervalLineColors: question.intervalLinesType == .InvertedLines ? RollViewModel.invertedHarmonicIntervalLineColors : RollViewModel.harmonicIntervalLineColors,
                    melodicIntervalLineColors: [],
                    viewableMelodicLines: [],
                    showInvertedIntervals: question.intervalLinesType == .InvertedLines,
                    showZigZags: question.intervalLinesType == .InvertedLines,
                    testing: true
                )
                
                if let answer = answer {
                    self.currentQuestionData = (nil, (rollViewModel, intervalLinesViewModel), [answer])
                } else {
                    self.currentQuestionData = nil
                }
            }
        }
    }
    
    func getTestQuestionData(_ currentQuestionIndex: Int) {
        /*
         case ScoreTwoNoteIntervalIdentification
         case ScoreThreeNoteInnerIntervalsIdentification
         case ScoreThreeNoteOuterIntervalIdentification
         case ScoreChordsAreInversions
         case ScoreTwoNoteIntervalsAreEqual

         case RollTwoNoteIntervalIdentification
         case RollThreeNoteInnerIntervalsIdentification
         case RollThreeNoteOuterIntervalIdentification
         case RollChordsAreInversions
         case RollTwoNoteIntervalsAreEqual
         */
    }
    
    func submitAnswer(questionData: (BarViewModel?, (RollViewModel, IntervalLinesViewModel)?, [Answer]?), answer: Answer, answerIndex: Int) {
        guard let answers = questionData.2 else { self.questionMarked = true; return }
        
        self.questionResults.append(answer.rawValue == answers[answerIndex].rawValue)
        
        if self.questionResults.count == answers.count {
            self.markQuestion()
        }
    }
    
    func markQuestion() {
        self.stopAnswerTimer()
        
        withAnimation(.easeInOut) {
            self.questionMarked = true
        }
        
        if let question = self.testSession?.questions[self.currentQuestionIndex] {
            let answeredCorrectly = self.questionResults.isEmpty ? false : self.questionResults.allSatisfy( { $0 == true } )
            let timeTaken = self.questionResults.isEmpty ? -1 : self.answerTime
            
            self.testSession?.results.append(TestResult(question: question, answeredCorrectly: answeredCorrectly, timeTaken: timeTaken))
        }
    }
    
    func saveTestSession() {
        guard let testSession = testSession else { self.showSavingErrorAlert = true; return }

        #if os(macOS)
        let panel = NSSavePanel()
        
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(testSession.id).json"

        panel.begin { response in
            if response == .OK, let fileURL = panel.url {
                do {
                    let encoder = JSONEncoder()
                    
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    
                    let jsonData = try encoder.encode(testSession)
                    try jsonData.write(to: fileURL)
                    
                    DispatchQueue.main.async {
                        self.showSavingSuccessAlert = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showSavingErrorAlert = true
                    }
                }
            }
        }
        #elseif os(iOS)
        #endif
    }
    
    static let quarterRest = Note(
        duration: .quarter,
        isRest: true,
        isDotted: false,
        hasAccent: false
    )
    
    static let halfRest = Note(
        duration: .half,
        isRest: true,
        isDotted: false,
        hasAccent: false
    )
    
    static let questions: [(Bar, [Answer])] = [
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .BMajor
        ), []), // S2II 1
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .AMajor
        ), []), // S2II 2
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .BFlatMajor
        ), []), // S2II 3
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .AMajor
        ), []), // S3II 1
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .GMajor
        ), []), // S3II 2
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .AFlatMajor
        ), []), // S3II 3
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .FMajor
        ), []), // S3OI 1
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .EMajor
        ), []), // S3OI 2
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .E,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .FMajor
        ), []), // S3OI 3
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .AMajor
        ), []), // SCAI 1
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .twoLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .EMajor
        ), []), // SCAI 2
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .BFlatMajor
        ), []), // SCAI 3
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Flat,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CFlatMajor
        ), []), // S2SI 1
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .great,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .oneLine,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .EMajor
        ), []), // S2SI 2
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: .Flat,
                        octave: .small,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .GFlatMajor
        ), []), // S3SI 3
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R2II NL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R2II WL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R2II IL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3II NL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3II WL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3II IL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: .Sharp,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3OI NL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .E,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3OI WL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    halfRest
                ])
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R3OI IL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // RCAI NL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // RCAI WL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // RCAI IL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .F,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .C,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R2SI NL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .D,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), []), // R2SI WL
        (Bar(
            chords: [
                Chord(notes: [
                    Note(
                        pitch: .C,
                        accidental: .Sharp,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .A,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
                Chord(notes: [
                    Note(
                        pitch: .B,
                        accidental: nil,
                        octave: .subContra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    ),
                    Note(
                        pitch: .G,
                        accidental: nil,
                        octave: .contra,
                        duration: .quarter,
                        isRest: false,
                        isDotted: false,
                        hasAccent: false
                    )
                ]),
                Chord(notes: [
                    quarterRest
                ]),
            ],
            clef: .Treble,
            timeSignature: .custom(beats: 4, noteValue: 4),
            repeat: nil,
            doubleLine: false,
            keySignature: .CMajor
        ), [])  // R3SI IL
    ]
}
