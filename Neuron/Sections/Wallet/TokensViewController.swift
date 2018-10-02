//
//  TokensViewController.swift
//  Neuron
//
//  Created by Yate Fulham on 2018/08/28.
//  Copyright © 2018 Cryptape. All rights reserved.
//

import UIKit
import web3swift

protocol TokensViewControllerDelegate: class {
    func getCurrentCurrencyModel(currencyModel: LocalCurrency, totleCurrency: Double)
}

/// ERC-20 Token List
class TokensViewController: UITableViewController {
    var tokenArray: [TokenModel] = []
    let viewModel = SubController2ViewModel()
    var currentCurrencyModel = LocalCurrencyService().getLocalCurrencySelect()
    weak var delegate: TokensViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if tokenArray.count != (WalletRealmTool.getCurrentAppModel().currentWallet?.selectTokenList.count)! + WalletRealmTool.getCurrentAppModel().nativeTokenList.count {
            didGetTokenList()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        didGetTokenList()
        addNotify()
    }

    func addNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeLocalCurrency), name: .changeLocalCurrency, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .beginRefresh, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(switchWalletLoadToken), name: .switchWallet, object: nil)
    }

    @objc func changeLocalCurrency() {
        currentCurrencyModel = LocalCurrencyService().getLocalCurrencySelect()
        getCurrencyPrice(currencyModel: currentCurrencyModel)
    }

    @objc
    func refreshData() {
        getBalance(isRefresh: false)
    }

    @objc
    func switchWalletLoadToken() {
        didGetTokenList()
    }

    /// get token list from realm
    func didGetTokenList() {
        tokenArray.removeAll()
        let appModel = WalletRealmTool.getCurrentAppModel()
        tokenArray += appModel.nativeTokenList
        let walletModel = WalletRealmTool.getCurrentAppModel().currentWallet!
        for item in walletModel.selectTokenList {
            tokenArray.append(item)
        }
        getBalance(isRefresh: true)
    }

    func getCurrencyPrice(currencyModel: LocalCurrency) {
        var currencyTotle = 0.0
        for model in tokenArray {
            let currency = CurrencyService()
            let currencyToken = currency.searchCurrencyId(for: model.symbol)
            guard let tokenId = currencyToken?.id else {
                continue
            }
            currency.getCurrencyPrice(tokenid: tokenId, currencyType: currencyModel.short) { (result) in
                switch result {
                case .success(let price):
                    guard let balance = Double(model.tokenBalance) else {
                        return
                    }
                    guard balance != 0 else {
                        if currencyTotle == 0 {
                            self.delegate?.getCurrentCurrencyModel(currencyModel: currencyModel, totleCurrency: currencyTotle)
                        }
                        return
                    }
                    model.currencyAmount = String(format: "%.2f", price * balance)
                    currencyTotle += Double(model.currencyAmount) ?? 0
                    self.delegate?.getCurrentCurrencyModel(currencyModel: currencyModel, totleCurrency: currencyTotle)
                    self.tableView.reloadData()
                case .error(let error):
                    Toast.showToast(text: error.localizedDescription)
                }
            }
        }
    }

    func getBalance(isRefresh: Bool) {
        let group = DispatchGroup()
        if isRefresh {
            Toast.showHUD()
        }
        let walletModel = WalletRealmTool.getCurrentAppModel().currentWallet!
        for tm in tokenArray {
            if tm.chainId == NativeChainId.ethMainnetChainId {
                group.enter()
                viewModel.didGetTokenForCurrentwallet(walletAddress: walletModel.address) { (balance, error) in
                    if error == nil {
                        tm.tokenBalance = balance!
                    } else {
                        Toast.showToast(text: (error?.localizedDescription)!)
                    }
                    group.leave()
                }
            } else if tm.chainId != "" && tm.chainId != NativeChainId.ethMainnetChainId {
                group.enter()
                viewModel.getNervosNativeTokenBalance(walletAddress: walletModel.address) { (balance, error) in
                    if error == nil {
                        tm.tokenBalance = balance!
                    } else {
                        Toast.showToast(text: (error?.localizedDescription)!)
                    }
                    group.leave()
                }
            } else if tm.address.count != 0 {
                group.enter()
                viewModel.didGetERC20BalanceForCurrentWallet(wAddress: walletModel.address, ERC20Token: tm.address) { (erc20Balance, error) in
                    if error == nil {
                        let balance = Web3.Utils.formatToPrecision(erc20Balance!, numberDecimals: tm.decimals, formattingDecimals: 6, fallbackToScientific: false)
                        tm.tokenBalance = balance!
                    } else {
                        Toast.showToast(text: (error?.localizedDescription)!)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.tableView.reloadData()
            NotificationCenter.default.post(name: .endRefresh, object: self, userInfo: nil)
            self.getCurrencyPrice(currencyModel: self.currentCurrencyModel)
            if isRefresh {
                Toast.hideHUD()
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tokenTableviewcell") as! TokenTableViewCell
        let model = tokenArray[indexPath.row]
        cell.tokenImage.sd_setImage(with: URL(string: model.iconUrl!), placeholderImage: UIImage(named: "eth_logo"))
        cell.balance.text = model.tokenBalance
        cell.token.text = model.symbol
        cell.network.text = (model.chainName?.isEmpty)! ? "Ethereum Mainnet": model.chainName
        if model.currencyAmount.count != 0 {
            cell.currency.text = currentCurrencyModel.symbol + model.currencyAmount
        } else {
            cell.currency.text = ""
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let transactionViewController = UIStoryboard(name: "Transaction", bundle: nil).instantiateViewController(withIdentifier: "transactionViewController") as! TransactionViewController
        let model = tokenArray[indexPath.row]
        transactionViewController.tokenModel = model
        if model.isNativeToken {
            if model.chainId == NativeChainId.ethMainnetChainId {
                transactionViewController.tokenType = .ethereumToken
            } else {
                transactionViewController.tokenType = .nervosToken
            }
        } else {
            transactionViewController.tokenType = .erc20Token
        }
        navigationController?.pushViewController(transactionViewController, animated: true)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offset = scrollView.contentOffset.y
        if #available(iOS 11.0, *) {
            offset += scrollView.adjustedContentInset.top
        } else {
            offset += scrollView.contentInset.top
        }
        tableView.isScrollEnabled = offset > 0
    }
}
