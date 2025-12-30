//
//  OnboardingView.swift
//  Nan Ton?
//
//  Created for Nan Ton? app
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "figure.strengthtraining.traditional",
            title: "Nan Ton?へようこそ",
            description: "シンプルで使いやすい筋トレ記録アプリです。毎日のトレーニングを記録して、成長を実感しましょう。"
        ),
        OnboardingPage(
            image: "list.clipboard",
            title: "ワークアウトを記録",
            description: "重量、レップ数、セット数を簡単に記録。前回の記録を参考にしながらトレーニングできます。"
        ),
        OnboardingPage(
            image: "chart.line.uptrend.xyaxis",
            title: "進捗を確認",
            description: "グラフで成長を可視化。1RMの推移や総ボリュームをチェックしてモチベーションを維持しましょう。"
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    showOnboarding = false
                }
            }) {
                Text(currentPage < pages.count - 1 ? "次へ" : "始める")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            if currentPage < pages.count - 1 {
                Button("スキップ") {
                    showOnboarding = false
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

private struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.image)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 16)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}
#endif
