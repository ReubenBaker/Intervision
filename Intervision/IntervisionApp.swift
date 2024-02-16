//
//  IntervisionApp.swift
//  Intervision
//
//  Created by Reuben on 06/02/2024.
//

import SwiftUI

@main
struct IntervisionApp: App {
    var body: some Scene {
        
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        let testBVM1 = BarViewModel(
            bar: Bar(
                chords: [
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.C,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.twoLine,
                            duration: Note.Duration.quarter,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: true,
                            hasAccent: false
                        ),
                        Note(
                            pitch: Note.Pitch.F,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.oneLine,
                            duration: Note.Duration.quarter,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: true,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.F,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.twoLine,
                            duration: Note.Duration.eighth,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: true,
                            hasAccent: false
                        ),
                        Note(
                            pitch: Note.Pitch.B,
                            accidental: nil,
                            octave: Note.Octave.twoLine,
                            duration: Note.Duration.eighth,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: true,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: nil,
                            accidental: nil,
                            octave: nil,
                            duration: Note.Duration.sixteenth,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: true,
                            isDotted: false,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.C,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.small,
                            duration: Note.Duration.eighth,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: false,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: nil,
                            accidental: nil,
                            octave: nil,
                            duration: Note.Duration.eighth,
                            durationValue: 0,
                            timeModification: nil,
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: true,
                            isDotted: false,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.B,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.oneLine,
                            duration: Note.Duration.sixteenth,
                            durationValue: 0,
                            timeModification: .custom(actual: 3, normal: 2),
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: false,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.C,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.twoLine,
                            duration: Note.Duration.sixteenth,
                            durationValue: 0,
                            timeModification: .custom(actual: 3, normal: 2),
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: false,
                            hasAccent: false
                        )
                    ]),
                    Chord(notes: [
                        Note(
                            pitch: Note.Pitch.D,
                            accidental: Note.Accidental.Sharp,
                            octave: Note.Octave.twoLine,
                            duration: Note.Duration.sixteenth,
                            durationValue: 0,
                            timeModification: .custom(actual: 3, normal: 2),
                            dynamic: nil,
                            graceNotes: nil,
                            tie: nil,
                            isRest: false,
                            isDotted: false,
                            hasAccent: false
                        )
                    ])
                ],
                tempo: Bar.Tempo.quarter(bpm: 120),
                clef: Bar.Clef.Treble,
                timeSignature: Bar.TimeSignature.custom(beats: 4, noteValue: 4),
                repeat: nil,
                doubleLine: false,
                volta: nil,
                keySignature: Bar.KeySignature.CMajor
            ),
            gaps: 4,
            step: BarViewModel.Step.Tone
        )
        
        WindowGroup {
//            MainWindowView()
            BarView(barViewModel: testBVM1)
                .frame(width: 1500, height: 500)
        }
    }
}
