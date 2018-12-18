//
//  TransactionDetailsViewController.swift
//  Neuron
//
//  Created by 晨风 on 2018/12/6.
//  Copyright © 2018 Cryptape. All rights reserved.
//

import UIKit
import SafariServices
import Social

class TransactionDetailsViewController: UITableViewController {
    @IBOutlet private weak var tokenIconView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var paymentAddressTitleLabel: UILabel!
    @IBOutlet private weak var paymentAddressLabel: UILabel!
    @IBOutlet private weak var receiptAddressTitleLabel: UILabel!
    @IBOutlet private weak var receiptAddressLabel: UILabel!
    @IBOutlet private weak var chainIconView: UIImageView!
    @IBOutlet private weak var blockchainBrowserLabel: UILabel!
    @IBOutlet private weak var hashTitleLabel: UILabel!
    @IBOutlet private weak var hashLabel: UILabel!
    @IBOutlet private weak var chainNetworkTitleLable: UILabel!
    @IBOutlet private weak var chainNetworkLabel: UILabel!
    @IBOutlet private weak var blockTitleLabel: UILabel!
    @IBOutlet private weak var blockLabel: UILabel!
    @IBOutlet private weak var gasFeeTitleLabel: UILabel!
    @IBOutlet private weak var gasFeeLabel: UILabel!
    @IBOutlet private weak var gasPriceTitleLabel: UILabel!
    @IBOutlet private weak var gasPriceLabel: UILabel!
    @IBOutlet private weak var gasUsedTitleLabel: UILabel!
    @IBOutlet private weak var gasUsedLabel: UILabel!
    @IBOutlet private weak var gasLimitTitleLabel: UILabel!
    @IBOutlet private weak var gasLimitLabel: UILabel!
    @IBOutlet private weak var statusWidthLayout: NSLayoutConstraint!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    var transaction: TransactionDetails! {
        didSet {
            if oldValue != nil && transaction != nil {
                setupUI()
            }
        }
    }
    private var paramBuilder: TransactionDetailsParamBuilder!

    private var hiddenItems = [(Int, Int)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transaction.Details.title".localized()
        paymentAddressTitleLabel.text = "Transaction.Details.paymentAddress".localized() + ":"
        receiptAddressTitleLabel.text = "Transaction.Details.receiptAddress".localized() + ":"
        blockchainBrowserLabel.text = "Transaction.Details.blockchainBrowserDesc".localized()
        hashTitleLabel.text = "Transaction.Details.hash".localized() + ":"
        chainNetworkTitleLable.text = "Transaction.Details.chainNetwork".localized() + ":"
        blockTitleLabel.text = "Transaction.Details.block".localized() + ":"
        gasFeeTitleLabel.text = "Transaction.Details.gasFee".localized() + ":"

        setupUI()
        setupTxFeeTitle()
    }

    func setupUI() {
        paramBuilder = TransactionDetailsParamBuilder(tx: transaction)
        setupTxStatus()
        tokenIconView.sd_setImage(with: URL(string: paramBuilder.tokenIcon), placeholderImage: UIImage(named: "eth_logo"))
        amountLabel.text = paramBuilder.amount
        dateLabel.text = paramBuilder.date
        paymentAddressLabel.text = paramBuilder.from
        receiptAddressLabel.text = paramBuilder.to

        if paramBuilder.txDetailsUrl == nil {
            hiddenItems.append((0, 3))    // block chain network
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = shareBarButtonItem
        }
        if let hash = paramBuilder.hash {
            hashLabel.text = hash
        } else {
            hiddenItems.append((1, 0))    // hash
        }
        chainNetworkLabel.text = paramBuilder.network
        if let block = paramBuilder.block {
            blockLabel.text = block
        } else {
            hiddenItems.append((1, 2))    // block
        }
        if let txFee = paramBuilder.txFee {
            gasFeeLabel.text = txFee
        } else {
            hiddenItems.append((1, 3))    // gas fee
        }
        if let gasPrice = paramBuilder.gasPrice {
            gasPriceLabel.text = gasPrice
        } else {
            hiddenItems.append((1, 4))    // gas price
        }
        if let gasUsed = paramBuilder.gasUsed {
            gasUsedLabel.text = gasUsed
        } else {
            hiddenItems.append((1, 5))    // gas used
        }
        if let gasLimit = paramBuilder.gasLimit {
            gasLimitLabel.text = gasLimit
        } else {
            hiddenItems.append((1, 6))    // gas limit
        }
    }

    func setupTxStatus() {
        switch transaction.status {
        case .success:
            statusLabel.text = transaction.isContractCreation ? "Transaction.Details.contractCreationSuccess".localized() : "TransactionStatus.success".localized()
            statusLabel.backgroundColor = UIColor(named: "secondary_color")?.withAlphaComponent(0.2)
            statusLabel.textColor = UIColor(named: "secondary_color")
        case .pending:
            statusLabel.text = transaction.isContractCreation ? "Transaction.Details.contractCreationPending".localized() : "TransactionStatus.pending".localized()
            statusLabel.backgroundColor = UIColor(named: "warning_bg_color")
            statusLabel.textColor = UIColor(named: "warning_color")
        case .failure:
            statusLabel.text = transaction.isContractCreation ? "Transaction.Details.contractCreationFailure".localized() : "TransactionStatus.failure".localized()
            statusLabel.backgroundColor = UIColor(hex: "FF706B", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "FF706B")
        }
        statusWidthLayout.constant = statusLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 20), limitedToNumberOfLines: 1).size.width + 24
    }

    func setupTxFeeTitle() {
        switch transaction.token.type {
        case .ether, .erc20:
            chainIconView.image = UIImage(named: "icon_tx_details_chain_eth")
            gasUsedTitleLabel.text = "Gas Used:"
            gasPriceTitleLabel.text = "Gas Price:"
            gasLimitTitleLabel.text = "Gas Limit:"
        case .appChain, .appChainErc20:
            chainIconView.image = UIImage(named: "icon_tx_details_chain_cita")
            gasUsedTitleLabel.text = "Quota Used:"
            gasPriceTitleLabel.text = "Quota Price:"
            gasLimitTitleLabel.text = "Quota Limit:"
        }
    }

    @IBAction func share(_ sender: Any) {
        let controller = UIActivityViewController(activityItems: [getTxDetailsURL()], applicationActivities: nil)
        controller.excludedActivityTypes = [.markupAsPDF, .mail, .openInIBooks, .print, .addToReadingList, .assignToContact]
        present(controller, animated: true, completion: nil)
    }
}

extension TransactionDetailsViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if hiddenItems.contains(where: { $0.0 == indexPath.section && $0.1 == indexPath.row }) {
            return 0.0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.isHidden = hiddenItems.contains(where: { $0.0 == indexPath.section && $0.1 == indexPath.row })
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return [(0, 1), (0, 2), (0, 3)].contains(where: { $0.0 == indexPath.section && $0.1 == indexPath.row })
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 1 {
            UIPasteboard.general.string = transaction.from
            Toast.showToast(text: "Wallet.QRCode.copySuccess".localized())
        } else if indexPath.section == 0 && indexPath.row == 2 {
            UIPasteboard.general.string = transaction.to
            Toast.showToast(text: "Wallet.QRCode.copySuccess".localized())
        } else if indexPath.section == 0 && indexPath.row == 3 {
            let safariController = SFSafariViewController(url: getTxDetailsURL())
            self.present(safariController, animated: true, completion: nil)
        }
    }
}

extension TransactionDetailsViewController {
    fileprivate func getTxDetailsURL() -> URL {
        let url: URL
        if transaction.token.type == .erc20 || transaction.token.type == .ether {
            url = EthereumNetwork().host().appendingPathComponent("/tx/\(transaction.hash)")
        } else if transaction.token.chainId == "1" {
            url = URL(string: "https://microscope.cryptape.com/#/transaction/\(transaction.hash)")!
        } else {
            fatalError()
        }
        return url
    }
}
