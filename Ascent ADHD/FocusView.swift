//
//  FocusView.swift
//  Ascent ADHD
//
//  The focus (Pomodoro-style) session — delay-aversion chunking. A duration picker starts a
//  session; a full-screen overlay counts down work/break phases with a depleting ring, chunk
//  counter, and break-time micro-reward. Ported from the focus setup dialog + overlay in MainApp.
//

import SwiftUI
import Combine

// MARK: - Setup (duration picker)

struct FocusSetupSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var taskLabel: String = ""
    @State private var minutes = 25

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Break it into footholds")
                    .font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
                Text("Work in a short timed chunk, then a 5-minute break. Each chunk is its own small win.")
                    .font(AscentFont.bodyMedium).foregroundColor(TextMuted).multilineTextAlignment(.center)

                if !taskLabel.isEmpty {
                    Text(taskLabel).font(AscentFont.titleMedium).foregroundColor(RidgelineBlue)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(IceBlueAccent))
                }

                Text("Chunk length").font(AscentFont.labelMedium).foregroundColor(TextMuted)
                HStack(spacing: 10) {
                    ForEach([10, 15, 25], id: \.self) { m in
                        let selected = minutes == m
                        Text("\(m) min").font(AscentFont.titleSmall)
                            .foregroundColor(selected ? PureWhite : MidnightSlate)
                            .padding(.horizontal, 18).padding(.vertical, 12)
                            .background(Capsule().fill(selected ? RidgelineBlue : NeutralFill))
                            .onTapGesture { minutes = m }
                    }
                }

                Button {
                    store.startFocus(taskLabel: taskLabel, minutes: minutes)
                    dismiss()
                } label: {
                    Text("Start focus").fontWeight(.bold).foregroundColor(PureWhite)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(RidgelineBlue))
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

// MARK: - Full-screen overlay

struct FocusOverlay: View {
    @EnvironmentObject var store: AppStore
    let session: FocusSession

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isWork: Bool { session.phase == FOCUS_PHASE_WORK }
    private var totalSeconds: Int { isWork ? session.workMinutes * 60 : FOCUS_BREAK_MINUTES * 60 }
    private var fraction: Double { totalSeconds > 0 ? Double(session.secondsLeft) / Double(totalSeconds) : 0 }

    var body: some View {
        ZStack {
            (isWork ? RidgelineBlue : MidnightSlate).ignoresSafeArea()
            VStack(spacing: 0) {
                Text(isWork ? "FOCUS" : "BREAK").font(AscentFont.labelLarge).foregroundColor(PureWhite.opacity(0.7))
                Spacer().frame(height: 8)
                if !session.taskLabel.isEmpty {
                    Text(session.taskLabel).font(AscentFont.titleLarge).foregroundColor(PureWhite)
                        .multilineTextAlignment(.center).lineLimit(2)
                    Spacer().frame(height: 24)
                } else {
                    Spacer().frame(height: 8)
                }

                // Depleting ring.
                ZStack {
                    Circle().stroke(PureWhite.opacity(0.18), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    Circle().trim(from: 0, to: CGFloat(min(max(fraction, 0), 1)))
                        .stroke(isWork ? IceBlueAccent : MistBlue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text(String(format: "%d:%02d", session.secondsLeft / 60, session.secondsLeft % 60))
                            .font(AscentFont.displayMedium).foregroundColor(PureWhite)
                        if session.chunksCompleted > 0 {
                            Text("\(session.chunksCompleted) chunk\(session.chunksCompleted == 1 ? "" : "s") done")
                                .font(AscentFont.labelMedium).foregroundColor(PureWhite.opacity(0.7))
                        }
                    }
                }
                .frame(width: 240, height: 240)

                if !isWork, let reward = store.focusChunkReward {
                    Spacer().frame(height: 20)
                    Text("🎁 Take your break: \(reward)")
                        .font(AscentFont.bodyMedium).foregroundColor(PureWhite).multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(PureWhite.opacity(0.15)))
                }

                Spacer().frame(height: 32)

                HStack(spacing: 16) {
                    Button { store.toggleFocusPause() } label: {
                        Text(session.isPaused ? "Resume" : "Pause").fontWeight(.bold).foregroundColor(PureWhite)
                            .padding(.horizontal, 24).padding(.vertical, 12).background(Capsule().fill(PureWhite.opacity(0.2)))
                    }
                    Button { store.stopFocus() } label: {
                        Text("Stop").fontWeight(.bold).foregroundColor(RidgelineBlue)
                            .padding(.horizontal, 24).padding(.vertical, 12).background(Capsule().fill(PureWhite))
                    }
                }

                if !isWork {
                    Spacer().frame(height: 12)
                    Button { store.skipBreak() } label: {
                        Text("Skip break").fontWeight(.bold).foregroundColor(PureWhite.opacity(0.8))
                    }
                }
            }
            .padding(32)
        }
        .onReceive(ticker) { _ in store.tickFocus() }
    }
}
