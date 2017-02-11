//
//  SlidingSelectionTabBarController.swift
//  ThePost
//
//  Created by Andrew Robinson on 12/28/16.
//  Copyright © 2016 The Post. All rights reserved.
//

import UIKit
import Firebase

let openChatControllerNotificationKey = "kOpenChatControllerNotification"

class SlidingSelectionTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private var selectionBar: UIView?
    
    private var interactionViews: [UIView]?
    
    private var shadowLayer: CALayer!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.clipsToBounds = true
        tabBar.backgroundColor = UIColor.black
        delegate = self
        
        shadowLayer = CALayer()
        shadowLayer.frame = CGRect(x: -tabBar.frame.width / 2.0, y: tabBar.frame.origin.y, width: 2 * tabBar.frame.size.width, height: 10.0)
        shadowLayer.backgroundColor = #colorLiteral(red: 0.1411764706, green: 0.1647058824, blue: 0.2117647059, alpha: 1).cgColor
        shadowLayer.shadowRadius = 5.0
        shadowLayer.shadowColor = #colorLiteral(red: 0.02352941176, green: 0.04705882353, blue: 0.09019607843, alpha: 1).cgColor
        shadowLayer.shadowOpacity = 0.25
        
        tabBar.superview!.layer.insertSublayer(shadowLayer, at: 1)
        
        if let items = tabBar.items {
            items[2].image = #imageLiteral(resourceName: "NewPostTabBarIcon").withRenderingMode(.alwaysOriginal)
            
            for item in tabBar.items! {
                item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(openChatTab(notification:)), name: NSNotification.Name(rawValue: openChatControllerNotificationKey), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        interactionViews = tabBar.subviews.filter({$0.isUserInteractionEnabled})
        
        if selectionBar == nil {
            
            if let views = interactionViews {
                
                let circle = UIView()
                circle.isUserInteractionEnabled = false
                circle.frame = CGRect(x: views[2].frame.midX, y: views[2].frame.midY, width: 0, height: 0)
                circle.backgroundColor = #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.2784313725, alpha: 1)
                circle.roundCorners()
                circle.alpha = 0.0
                tabBar.insertSubview(circle, belowSubview: views[2])
                
                selectionBar = UIView()
                selectionBar!.frame = CGRect(x: tabBar.frame.width, y: tabBar.frame.height - 2, width: views[0].frame.width, height: 2)
                selectionBar!.backgroundColor = #colorLiteral(red: 0.8470588235, green: 0.337254902, blue: 0.2156862745, alpha: 1)
                selectionBar!.isUserInteractionEnabled = false
                selectionBar!.alpha = 0.0
                tabBar.insertSubview(selectionBar!, belowSubview: circle)
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.selectionBar!.alpha = 1.0
                    self.selectionBar!.frame = CGRect(x: 0, y: self.tabBar.frame.height - 2, width: views[0].frame.width, height: 2)
                    
                    circle.frame = CGRect(x: views[2].frame.origin.x - 6,
                                          y: views[2].frame.origin.y - 6,
                                          width: views[2].frame.width + 12,
                                          height: views[2].frame.height + 12)
                    
                    circle.roundCorners()
                    circle.alpha = 1.0
                })
                
            }
        }
        
    }
    
    // MARK: - Tab Bar overrides
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        let index = tabBar.items!.index(of: item)
        
        if index != 2 && FIRAuth.auth()?.currentUser != nil {
            if let views = interactionViews {
                let selectedFrame = views[index!].frame
                
                UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut, animations: {
                    self.selectionBar!.frame = CGRect(x: selectedFrame.origin.x, y: selectedFrame.height - 1, width: self.selectionBar!.frame.width, height: self.selectionBar!.frame.height)
                }, completion: nil)
            }
        }
    }
    
    // MARK: - Tab bar controller delegates
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        var shouldSelect = false
        
        if FIRAuth.auth()?.currentUser == nil {
            let storyboard = UIStoryboard(name: "SignInUp", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SignInUpPrompt")
            vc.modalPresentationStyle = .overCurrentContext
            
            present(vc, animated: false, completion: nil)
        } else if viewController.title == "addNewPostTabBarViewController" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "addNewPostViewController")
            vc.modalPresentationStyle = .overCurrentContext
            
            present(vc, animated: false, completion: nil)
        } else {
            shouldSelect = true
        }
        
        return shouldSelect
    }
    
    // MARK: - Show/hide shadow layer
    
    func showShadow() {
        shadowLayer.isHidden = false
    }
    
    func hideShadow() {
        shadowLayer.isHidden = true
    }
    
    // MARK: - Notifications
    
    @objc private func openChatTab(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: String] {
            if childViewControllers.count >= 1 {
                if let navBar = childViewControllers[1] as? UINavigationController {
                    if navBar.childViewControllers.count >= 1 {
                        if let conversationVC = navBar.childViewControllers[0] as? ChatConversationViewController {
                            let conversation = Conversation(id: "",
                                                            otherPersonId: userInfo["productOwnerID"]!,
                                                            otherPersonName: userInfo["productOwnerName"]!,
                                                            productID: userInfo["productID"]!)
                            
                            if let preMessage = userInfo["preformattedMessage"] {
                                conversation.firstMessage = preMessage
                            }
                            
                            conversationVC.newConversation = conversation

                            selectedIndex = 1
                            
                            // Move selection bar
                            if let views = interactionViews {
                                let selectedFrame = views[1].frame
                                UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut, animations: {
                                    self.selectionBar!.frame = CGRect(x: selectedFrame.origin.x, y: selectedFrame.height - 1, width: self.selectionBar!.frame.width, height: self.selectionBar!.frame.height)
                                }, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }

}
