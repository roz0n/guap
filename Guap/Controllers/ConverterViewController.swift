//
//  ConverterViewController.swift
//  Guap
//
//  Created by Arnaldo Rozon on 1/31/21.
//

import UIKit

// TODO: This could be named better
enum CurrencyType: String {
    case base = "base"
    case target = "target"
}

protocol ConverterControllerDelegate {
    func didGetPairConversion(_ sender: ConverterViewController?, responseData: ERPairConversionModel, result: Double?)
}

class ConverterViewController: UIViewController {
    
    var delegate: ConverterControllerDelegate?
    let statusBar = ConverterStatusBar()
    
    var allPanels = [ConverterPanelUIModel]()
    var converterBase: ConverterPanelUIModel?
    var converterTarget: ConverterPanelUIModel?
    
    let baseValuePanel = ConverterPanel()
    let baseValueButton = ConverterPanelButton()
    let baseValueField = ConverterPanelTextField()
    var baseValue: Int?
    
    let targetValuePanel = ConverterPanel()
    let targetValueButton = ConverterPanelButton()
    let targetValueField = ConverterPanelTextField()
    
    private let panelStack: UIStackView = {
        let view = UIStackView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray4
        view.axis = .vertical
        view.distribution = .fillEqually
        view.spacing = K.spacers.panels.stack
        
        return view
    }()
    
    init(baseBg baseBackground: UIColor, baseCurr baseCurrency: String, targetBg targetBackground: UIColor, targetCurr targetCurrency: String) {
        super.init(nibName: nil, bundle: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        baseValuePanel.bgColor = baseBackground
        baseValueButton.title = baseCurrency
        baseValueButton.type = .base
        baseValueField.isEnabled = false
        
        targetValuePanel.bgColor = targetBackground
        targetValueButton.title = targetCurrency
        targetValueButton.type = .target
        targetValueField.isEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayout()
        configureGestures()
    }
    
    func calculatePair(base: Double, rate: Double) -> Double {
        return (base * rate).rounded()
    }
    
    func resetValues() {
        baseValue = nil
        baseValueField.text = ""
        targetValueField.text = ""
    }
    
}

// MARK: - Data fetching methods

extension ConverterViewController {
    
    func getPairedConversionData() {
        guard let base = baseValue else { return }
        
        baseValueField.isEnabled.toggle()
        
        DispatchQueue.global().async {
            ERDataManager.shared.getPairConversion(base: K.defaults.BaseCurrency, target: K.defaults.TargetCurrency) { [weak self] (response, error) in
                if error != nil {
                    print("Error: \(String(describing: error))")
                    return
                }
                
                if let response = response {
                    let conversionResult = self?.calculatePair(base: Double(base), rate: response.conversionRate)
                    self?.delegate?.didGetPairConversion(self, responseData: response, result: conversionResult)
                }
            }
        }
        
        baseValueField.isEnabled.toggle()
    }
    
}

// MARK: - Gesture handlers

extension ConverterViewController {
    
    func configureGestures() {
        setCurrencySelectionGesture()
    }
    
    func setCurrencySelectionGesture() {
        for panel in allPanels {
            let tap = UITapGestureRecognizer(target: self, action: #selector(openCurrencySelectionScreen))
            
            if let button = panel.button {
                button.addGestureRecognizer(tap)
            }
        }
    }
    
    @objc func openCurrencySelectionScreen(_ sender: UITapGestureRecognizer) {
        let button = sender.view as? ConverterPanelButton
        let type = button?.type
        
        if let type = type {
            let vc = UINavigationController(rootViewController: CurrencySelectorViewController(type: type))
            
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true, completion: nil)
        }
    }
    
}

// MARK: - Layout

/**
 This extension handles adding each "panel" (or row) containing the various UI elements that compose the greater currency converter UI component.
 First, it creates a data structure that contains the aforementioned UI elements and adds them to homogeneous array. Later, this makes adding constraints trivial and far less repetitive.
 Second, it adds each panel to the UIStackView defied at the top of the class. Third, it lays out each panel's UI elements dynamically within a loop.
 Finally, it applies basic constraints to the panelStack view itself. Each method is called sequentially by the `configureLayout` method in `viewDidLoad` in an effort to keep their usage contained to the extension.
 */


// TODO: Getting the feeling that the panels code should probably reside inside the panels view :\
extension ConverterViewController {
    
    private func configureLayout() {
        createPanels()
        configurePanels()
        configureSubviews()
    }
    
    private func createPanels() {
        converterBase = ConverterPanelUIModel(panel: baseValuePanel, button: baseValueButton, field: baseValueField)
        converterTarget = ConverterPanelUIModel(panel: targetValuePanel, button: targetValueButton, field: targetValueField)
    }
    
    private func configurePanels() {
        allPanels = [converterBase!, converterTarget!]
        
        guard !allPanels.isEmpty else { return }
        
        for converterPanel in allPanels {
            panelStack.addArrangedSubview(converterPanel.panel!)
            
            if let panel = converterPanel.panel, let button = converterPanel.button, let field = converterPanel.field {
                panel.stack.addArrangedSubview(field)
                panel.stack.addArrangedSubview(button)
            }
        }
    }
    
    private func configureSubviews() {
        view.addSubview(statusBar)
        view.addSubview(panelStack)
        
        NSLayoutConstraint.activate([
            statusBar.topAnchor.constraint(equalTo: view.topAnchor),
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: K.heights.converter.statusBar),
            
            panelStack.topAnchor.constraint(equalTo: statusBar.bottomAnchor),
            panelStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            panelStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            panelStack.heightAnchor.constraint(equalToConstant: K.heights.converter.container)
        ])
    }
    
}
