//
//  GuideService.swift
//  Neuron
//
//  Created by 晨风 on 2018/10/11.
//  Copyright © 2018 Cryptape. All rights reserved.
//

import Foundation
import RealmSwift

class GuideService {
    static let shared = GuideService()
    var controller: UIViewController?
    private var notificationToken: NotificationToken?

    private init() {
        notificationToken = WalletRealmTool.realm.objects(AppModel.self).observe { [weak self](change) in
            guard let self = self else { return }
            switch change {
            case .update(let values, deletions: _, insertions: _, modifications: _):
                if values.first?.wallets.count == 0 || values.count == 0 {
                    self.showGuide()
                } else {
                    self.hideGuide()
                }
            default:
                break
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

    func register() {
        guard WalletRealmTool.getCurrentAppModel().wallets.count == 0 else { return }
        showGuide()
    }

    private func showGuide() {
        guard controller == nil else { return }
        let guideController: GuideViewController = UIStoryboard(name: .guide).instantiateViewController()
        controller = BaseNavigationController(rootViewController: guideController)
        UIApplication.shared.keyWindow?.rootViewController?.present(controller!, animated: true, completion: nil)
    }

    private func hideGuide() {
        controller?.dismiss(animated: true, completion: nil)
        controller = nil
    }
}