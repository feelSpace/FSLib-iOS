//
//  NavigationController.swift
//  FSLibIOs
//
//  Created by David on 10.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation


/**
 Enumeration of navigation states used by the navigation controller.
 
 If the navigation controller is connected to a belt the state of the navigation
 will be synchronized to the mode of the belt. If no belt is connected, the
 navigation controller can still switch between states including
 `FSNavigationState.navigating`.
 */
@objc public enum NavigationState: Int {
    
    /**
     The navigation is stopped, no direction or signal is defined.
     */
    case stopped;
    
    /**
     The navigation is paused and can be resumed with the current direction
     and signal type.
     */
    case paused;
    
    /**
     The navigation has been started with a direction and signal type.
     */
    case navigating;
    
}
