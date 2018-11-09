//
//  MainViewController.swift
//  Neuron
//
//  Created by XiaoLu on 2018/5/18.
//  Copyright © 2018年 cryptape. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        applyBarStyle()

        determineWalletViewController()
        NotificationCenter.default.addObserver(self, selector: #selector(determineWalletViewController), name: .allWalletsDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(determineWalletViewController), name: .firstWalletCreated, object: nil)

        addNativeTokenMsgToRealm()
    }

    // get native token for nervos  'just temporary'
    func addNativeTokenMsgToRealm() {
        let appModel = WalletRealmTool.getCurrentAppModel()
        let ethModel = TokenModel()
        ethModel.address = ""
        ethModel.chainId = NativeChainId.ethMainnetChainId
        ethModel.chainName = ""
        ethModel.decimals = NativeDecimals.nativeTokenDecimals
        ethModel.iconUrl = ""
        ethModel.isNativeToken = true
        ethModel.name = "ethereum"
        ethModel.symbol = "ETH"
        ethModel.chainidName = NativeChainId.ethMainnetChainId + ""
        try? WalletRealmTool.realm.write {
            WalletRealmTool.realm.add(ethModel, update: true)
            if !appModel.nativeTokenList.contains(ethModel) {
                appModel.nativeTokenList.append(ethModel)
                WalletRealmTool.addObject(appModel: appModel)
            }
        }
    }

    private func applyBarStyle() {
        UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -4)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColor.newThemeColor], for: .selected)

        let navigationBarBackImage = UIImage(named: "nav_darkback")!.withRenderingMode(.alwaysOriginal)
        UINavigationBar.appearance().backIndicatorImage = navigationBarBackImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = navigationBarBackImage

        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: .highlighted)
    }

    @objc
    private func determineWalletViewController() {
        let walletViewController: UIViewController
        if WalletRealmTool.hasWallet() {
            walletViewController = UIStoryboard(name: "Wallet", bundle: nil).instantiateInitialViewController()!
        } else {
            walletViewController = UIStoryboard(name: "AddWallet", bundle: nil).instantiateViewController(withIdentifier: "AddWallet")
        }
        (viewControllers![1] as! BaseNavigationController).viewControllers = [walletViewController]
    }
}