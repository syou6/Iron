//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import MessageUI

struct SettingsView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var mainSection: some View {
        Section {
            NavigationLink(destination: GeneralSettingsView(), isActive: $generalSelected) {
                Text("一般")
            }

            if HealthSettingsView.isSupported {
                NavigationLink(destination: HealthSettingsView()) {
                    Text("Apple Health")
                }
            }

            if WatchSettingsView.isSupported {
                NavigationLink(destination: WatchSettingsView()) {
                    Text("Apple Watch")
                }
            }

            NavigationLink(destination: BackupAndExportView()) {
                Text("バックアップ")
            }
        }
    }
    
    @State private var showSupportMailAlert = false // if mail client is not configured
    private var aboutRatingAndSupportSection: some View {
        Section {
            NavigationLink(destination: AboutView()) {
                Text("このアプリについて")
            }

            Button(action: {
                guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1479893244?action=write-review") else { return }
                UIApplication.shared.open(writeReviewURL)
            }) {
                HStack {
                    Text("Nan Ton?を評価")
                    Spacer()
                    Image(systemName: "star")
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Nan Ton?を評価")
            .accessibilityHint("App Storeでレビューを書く")

            Button(action: {
                guard MFMailComposeViewController.canSendMail() else {
                    self.showSupportMailAlert = true // fallback
                    return
                }

                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = MailCloseDelegate.shared
                mail.setToRecipients(["iron@ka.codes"])

                // TODO: replace this hack with a proper way to retreive the rootViewController
                guard let rootVC = UIApplication.shared.activeSceneKeyWindow?.rootViewController else { return }
                rootVC.present(mail, animated: true)
            }) {
                HStack {
                    Text("フィードバックを送信")
                    Spacer()
                    Image(systemName: "paperplane")
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("フィードバックを送信")
            .accessibilityHint("メールでフィードバックを送る")
            .alert(isPresented: $showSupportMailAlert) {
                Alert(title: Text("サポートメール"), message: Text("iron@ka.codes"))
            }
        }
    }
    
    #if DEBUG
    private var developerSettings: some View {
        Section {
            NavigationLink(destination: DeveloperSettings()) {
                Text("Developer")
            }
        }
    }
    #endif

    var body: some View {
        NavigationStack {
            Form {
                mainSection

                aboutRatingAndSupportSection

                #if DEBUG
                developerSettings
                #endif
            }
            .navigationBarTitle(Text("設定"))
        }
    }

    @State private var generalSelected = false
}

// hack because we can't store it in the View
private class MailCloseDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailCloseDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
