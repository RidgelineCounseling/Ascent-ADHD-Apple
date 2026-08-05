//
//  OnboardingView.swift
//  Ascent ADHD
//
//  First-launch wizard — collects the personal reward bank (small + medium) and marks setup
//  complete. Ported from the onboarding dialog in MainApp.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore

    @State private var step = 0
    @State private var small: [String] = []
    @State private var medium: [String] = []
    @State private var smallInput = ""
    @State private var mediumInput = ""

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case 0: welcome
            case 1: rewardStep(
                title: "Small rewards",
                blurb: "Quick treats — under 5 minutes. Add at least 5 things you'd enjoy.",
                examples: "Examples: a square of chocolate, 5 min of stretching, one funny short, a hot drink, step outside…",
                placeholder: "e.g. a piece of chocolate",
                items: $small, input: $smallInput, minCount: 5,
                buttonTitle: "Next", buttonColor: RidgelineBlue) { step = 2 }
            default: rewardStep(
                title: "Medium rewards",
                blurb: "Bigger treats — 15 minutes or more. Add at least 3 things worth working toward.",
                examples: "Examples: an episode of a show, a walk in the park, a hot bath, a gaming session, calling a friend…",
                placeholder: "e.g. an episode of my show",
                items: $medium, input: $mediumInput, minCount: 3,
                buttonTitle: "Start climbing", buttonColor: SuccessGreen) { finish() }
            }
        }
        .padding(24)
        .background(SkyGray.ignoresSafeArea())
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("⛰️").font(.system(size: 80))
            Text("Welcome to your climb").font(AscentFont.headlineMedium).foregroundColor(MidnightSlate)
                .multilineTextAlignment(.center)
            Text("First, let's pick some rewards you actually want.")
                .font(AscentFont.bodyLarge).foregroundColor(MidnightSlate.opacity(0.8))
                .multilineTextAlignment(.center)
            Spacer()
            Button { step = 1 } label: {
                Text("Let's go").fontWeight(.bold).foregroundColor(PureWhite)
                    .frame(maxWidth: .infinity).frame(height: 54).background(Capsule().fill(RidgelineBlue))
            }
        }
    }

    private func rewardStep(title: String, blurb: String, examples: String, placeholder: String,
                            items: Binding<[String]>, input: Binding<String>, minCount: Int,
                            buttonTitle: String, buttonColor: Color, next: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
            Text(blurb).font(AscentFont.bodyMedium).foregroundColor(MidnightSlate.opacity(0.7))
            Text(examples).font(AscentFont.bodySmall).italic().foregroundColor(MidnightSlate.opacity(0.5))

            HStack(spacing: 8) {
                TextField(placeholder, text: input)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Capsule().fill(PureWhite))
                    .overlay(Capsule().stroke(BorderGray.opacity(0.5), lineWidth: 1))
                    .onSubmit { add(input, into: items) }
                Button { add(input, into: items) } label: {
                    Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundColor(PureWhite)
                        .frame(width: 48, height: 48).background(Circle().fill(RidgelineBlue))
                }
            }
            Text("\(items.wrappedValue.count) / \(minCount)+ added").font(AscentFont.labelMedium)
                .foregroundColor(items.wrappedValue.count >= minCount ? MetricGreen : MidnightSlate.opacity(0.5))

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(items.wrappedValue.enumerated()), id: \.offset) { idx, item in
                        HStack {
                            Text(item).font(AscentFont.bodyMedium).foregroundColor(MidnightSlate)
                            Spacer()
                            Image(systemName: "xmark").font(.system(size: 15)).foregroundColor(MidnightSlate.opacity(0.6))
                                .onTapGesture { items.wrappedValue.remove(at: idx) }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(NeutralFill))
                    }
                }
            }
            .frame(maxHeight: .infinity)

            Button(action: next) {
                Text(buttonTitle).fontWeight(.bold).foregroundColor(PureWhite)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Capsule().fill(items.wrappedValue.count >= minCount ? buttonColor : Color.gray))
            }
            .disabled(items.wrappedValue.count < minCount)
        }
    }

    private func add(_ input: Binding<String>, into items: Binding<[String]>) {
        let t = input.wrappedValue.trimmed
        guard !t.isEmpty else { return }
        items.wrappedValue.append(t)
        input.wrappedValue = ""
    }

    private func finish() {
        store.rewardBank = RewardBank(small: small, medium: medium)
        store.hasCompletedSetup = true
    }
}
