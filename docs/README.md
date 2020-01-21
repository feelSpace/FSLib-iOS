# FSLib-iOS Documentation

FSLib-iOS is an iOS library to control the feelSpace naviBelt from your application.

# Content

* [Copyright and license notice](#copyright-and-license-notice)
* [Introduction to the feelSpace belt](#introduction-to-the-feelspace-belt)
  * [Belt buttons and modes](#belt-buttons-and-modes)
  * [Bluetooth communication](#bluetooth-communication)
  * [Main features of the belt](#main-features-of-the-belt)
* [FSLib for iOS](#fslib-for-ios)
  * [Structure of the repository](#structure-of-the-repository)
  * [Integration of the FSLib in a XCode project](#integration-of-the-fslib-in-a-xcode-project)
  * [Setup of your project](#setup-of-your-project)
  * [Structure of the FSLib module](#structure-of-the-fslib-module)
* [Navigation API](#navigation-api)
  * [Introduction](#introduction)
  * [Navigation state and belt mode](#navigation-state-and-belt-mode)
  * [Belt button press](#belt-button-press)
  * [Continuous and repeated vibration signals](#continuous-and-repeated-vibration-signals)
  * [Vibration notifications](#vibration-notifications)
  * [Vibration intensity](#vibration-intensity)
  * [Belt orientation](#belt-orientation)
  * [Belt battery level](#belt-battery-level)
  * [Compass accuracy signal](#compass-accuracy-signal)
* [General purpose API](#general-purpose-api)
  * [Connection management](#connection-management)
    * [Connection manager and delegate](#connection-manager-and-delegate)
    * [Scanning for a belt](#scanning-for-a-belt)
    * [Connecting to a belt](#connecting-to-a-belt)
    * [Disconnecting a belt](#disconnecting-a-belt)
  * [Command manager and delegate](#command-manager-and-delegate)
  * [Belt status, events and parameters](#belt-status-events-and-parameters)
    * [Belt mode](#belt-mode)
    * [Button press events](#button-press-events)
    * [Belt battery status](#belt-battery-status)
    * [Belt orientation](#belt-orientation)
    * [Firmware version](#firmware-version)
  * [Control of the vibration](#control-of-the-vibration)
    * [Vibration intensity](#vibration-intensity)
    * [Simple vibration signals](#simple-vibration-signals)
    * [Special vibration signals](#special-vibration-signals)
    * [Vibration-channel configuration](#vibration-channel-configuration)
    * [Stop vibration](#stop-vibration)

## Copyright and license notice

Copyright 2017-2019, feelSpace GmbH.

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0

**Note on using feelSpace Trademarks and Copyrights:**

*Attribution:* You must give appropriate credit to feelSpace GmbH when you use feelSpace products in a publicly disclosed derived work. For instance, you must reference feelSpace GmbH in publications, conferences or seminars when a feelSpace product has been used in the presented work.

*Endorsement or Sponsorship:* You may not use feelSpace name, feelSpace products’ name, and logos in a way that suggests an affiliation or endorsement by feelSpace GmbH of your derived work, except if it was explicitly communicated by feelSpace GmbH.

# Introduction to the feelSpace belt

## Belt buttons and modes

The front panel of the belt’s control box has four buttons (see image below).

![Belt buttons](img/control_box_buttons.svg)

The belt has seven “modes” of operation that are controlled by button press or changed by a connected device.

| Mode | Description |
| --- | --- |
| *standby* | In standby, all components of the belt, including Bluetooth, are switched-off. The belt only reacts to a long press on the power button that starts the belt and put it in wait mode. Since Bluetooth connection is not possible in standby mode, the Bluetooth connection is closed after a notification of the standby mode. |
| *wait* | In wait mode, the belt waits for a user input, either a button-press or a command from a connected device. A periodic vibration signal indicates that the belt is active. This wait signal is a single pulse when no device is connected, a double pulse when a device is connected, and a succession of short pulses when the belt is in pairing mode. |
| *compass* | In compass mode, the belt vibrates towards magnetic North. From the wait and app modes, the compass mode is obtained by a press on the compass button of the belt. |
| *crossing* | In crossing mode, the belt vibrates towards an initial heading direction. From the wait and app modes, the crossing mode is obtained by a double press on the compass button of the belt. |
| *app-mode* | The app-mode is the mode in which the vibration is controlled by the connected device. The app-mode is only accessible when the device is connected. If the device is unexpectedly disconnected in app-mode, the belt switches automatically to the wait mode. |
| *pause* | In pause mode, the vibration is stopped. From the wait, compass and app modes, the pause mode is obtained by a press on the pause button. Another press on the pause button in pause mode returns to the previous mode. In pause mode, the user can change the (default) vibration intensity by pressing the home button (increase intensity) or compass button (decrease intensity). |
| *calibration* | The calibration mode is used for the calibration procedure of the belt. |

## Bluetooth communication

The belt contains a Bluetooth low-energy module. The communication is based on custom GATT services. To identify the belt, it is advertised with a name starting with “naviGuertel” (available in scan response packet). The advertisement packet also contains the service UUID: `65333333-A115-11E2-9E9A-0800200CA100`. The FSLib will automatically find belts with those characteristics.

A smartphone must support Bluetooth low-energy, version 4.0 or higher, to connect to the belt. iPhones support Bluetooth low-energy since the iPhone 4S version, released in October 2011. iPhones that were released before the 4S version do not support Bluetooth low-energy and will not be able to connect to the belt.

## Main features of the belt

The belt and the FSLib API propose a large set of features to cover multiple domains and use cases (e.g., navigation, VR, simulation, research experiment, outdoor and video-games, attention feedback).

* 16 vibration motors
* Up to 6 simultaneous vibrations
* Configurable vibration intensity
* Pre-defined and customizable vibration patterns
* Vibration orientation can be relative to magnetic North or relative to the body
* 8+ hours of battery autonomy when continuously vibrating
* Compass and crossing functions that does not require any additional device
* Wireless connection (Bluetooth Low Energy) for your application
* Reading of the belt orientation, battery level, and belt button events from your application

:construction: Some features of the belt may not be implemented in the FSLib. We will progressively add new features to the FSLib, but if you have a specific request please let us know by submitting an [issue](https://github.com/feelSpace/FSLib-iOS/issues).

# FSLib for iOS

## Structure of the repository

The repository contains one XCode workspace with three modules:
* **FSLibIOs**: The FSLib framework to be use for connecting and controlling a belt from an app. The module is implemented in Swift 4.
* **FSLibIOsDemo**: A demo application for iPhone that illustrates how to use the FSLib framework. The module is implemented in Swift 4.
* **FSLibIOsObjcDemo**: A demo application for iPhone that illustrate how to use the FSLib framework in an Objective-C project. :construction: This Objective-C module is under development.

## Integration of the FSLib in a XCode project

### Using CocoaPods
To add the last version of FSLib to your project using CocoaPods, first install and configure CocoaPods for your project (see [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)). Then, add the following dependency to your Podfile:

```
    pod 'FSLibIOs', '~> 2.0.3'
```


### Using source on git
You can clone the FSLib git repository and link it to your project. First clone the FSLib-iOS repository, then add the `FSLibIOs` project to your workspace as a "Linked Framework". This can be done in the "General" configuration pane of your XCode project.

## Setup of your project

To use the FSLib, the project must be configured to support Bluetooth functionalities. 
* In the `Info.plist` configuration file of your project, an entry must be added in the `Required background modes` with the value `bluetooth-central`. This configuration is detailed in the apple developer guide: [Core Bluetooth Background Processing for iOS Apps](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html).
* In the `Info.plist` configuration file of your project, an entry must be added to explain why Bluetooth is used by your application. The key `NSBluetoothPeripheralUsageDescription` must be added with the description of Bluetooth usage as value. If your app has a deployment target earlier than iOS 13, you must also add the key `NSBluetoothAlwaysUsageDescription` with the same description in value. Details are given in the developer guide: [Core Bluetooth Overview](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothOverview/CoreBluetoothOverview.html#//apple_ref/doc/uid/TP40013257-CH2-SW1).

## Structure of the FSLib module

The FSLib proposes two approaches for connecting and controlling a belt:

* **The navigation API:** It is the recommended approach. The navigation API provides simple methods to connect and control a belt. The main class to start developing with the navigation API is the `FSNavigationController`.
* **The general API:** The general API provides a large set of methods to control the belt for complex applications. Your application must manage the mode of the belt and the belt's button events. The main classes of the general API are the `FSConnectionManager`, and the `FSCommandManager`. In any case it is recommended to look at the implementation of the FSNavigationController before you start using the general API.

# Navigation API

## Introduction

The navigation API provides simple methods to connect and control a belt. Although the term "navigation" is used, this API can be used in different scenarios to control the orientation of a vibration signal. The orientation of the vibration can be a magnetic bearing (i.e. an angle relative to magnetic North) or a position on the belt (e.g. 90 degrees for the right side of the belt). It is also possible to use the navigation API for complex vibration signals by extending the `FSNavigationController`.

The main class to connect a belt and control the vibration is the `FSNavigationController`. You must also implement a `FSNavigationControllerDelegate` to handle the callback of the navigation controller.

It is recommended to look at the demo application that illustrates how to use the navigation controller. The relevant part of the code is located in the `ViewController` class of the `FSLibIOsDemo` module.

## Connection and disconnection of a belt

To manage the connection and control the belt, you must implement the `FSNavigationControllerDelegate` and register your class as delegate of the `FSNavigationController`.

```swift
class MyClass: FSNavigationControllerDelegate {
    
    // Navigation controller
    var beltController: FSNavigationController! = FSNavigationController()
	
    init() {
        // Register as delegate
        beltController.delegate = self
        // ...
    }
    
    // Implementation of the delegate methods
    // ...
    
}
```

To search and connect a belt, call the method `searchAndConnectBelt()`.

```swift
beltController.searchAndConnectBelt()
```

If you implemented your own scan procedure you can call `connectBelt()` with the belt in parameter.

```swift
beltController.searchAndConnectBelt(belt)
```

To disconnect, call `disconnectBelt()`.

```swift
beltController.disconnectBelt()
```

The connection events are notified via the delegate method `onBeltConnectionStateChanged()`. You should only look at the `.connected` and `.notConnected` states. The other states are not relevent for most applications. The connection state of the belt is also available with the read-only property `connectionState` of the navigation controller.

If a problem occurs with the connection, the following delegate methods are called:
* **`onBluetoothNotAvailable()`:** The smartphone has no compatible Bluetooth service.
* **`onBluetoothPoweredOff()`:** The Bluetooth is switched off, your application should ask the user to switch on Bluetooth on the device.
* **`onBeltConnectionFailed()`:** The connection with the belt failed. Your application should propose to retry the connection.
* **`onBeltConnectionLost()`:** The connection with the belt has been lost. Your application should propose to reconnect the belt.
* **`onNoBeltFound()`:** No belt has been found. Your application should ask the user to verify if the belt is powered-on.

## Navigation state and belt mode

The `FSNavigationController` has three states: `.stopped`, `.paused` and `.navigating`. When a belt is connected and the state is `.navigating`, the vibration of the belt is controlled by the application.

Note that the state of the navigation controller can be changed even when no belt is connected. As soon as a belt is connected, the mode of the belt is automatically changed to match the state of the navigation controller (i.e. if the state is `.navigating` and a belt is connected, the mode of belt is automatically changed to app mode with the vibration signal defined by the navigation controller).

Your application control the navigation state by calling the methods `startNavigation()`, `stopNavigation()` and `pauseNavigation()`. However, if a belt is connected, the state can change when the user press a button on the belt. For instance, if the state is `.navigating` and the user press the pause button on the belt, the navigation controller automatically switch to `.paused` state.

## Belt button press

The navigation controller already manages most of the behavior on button press and mode change. The application must only define a behavior when the home button is pressed, and the navigation is started or stopped. The callback to handle home-button press is `onBeltHomeButtonPressed()`.

The detailed behavior of the navigation controller on button press is the following:

* **Home button:** If the navigation is stopped or started, the delegate is informed of the button press via `onBeltHomeButtonPressed()`. If the navigation is paused and the belt is not in pause mode, the navigation is resumed automatically. If the navigation is paused and the belt is in pause mode, the vibration intensity is changed.
* **Power button:** On short press, the battery level vibration is started without callback to the application. On long press, the belt is switched off and the delegate is informed of the disconnection via `onBeltConnectionStateChanged()`.
* **Pause button:** If the navigation is started when the pause button is pressed, the navigation is automatically paused. If the belt was in pause mode from navigation, the navigation is automatically resumed.
* **Compass button:** If the navigation is started when the compass button is pressed, the navigation is paused automatically and the belt goes to compass, crossing or calibration mode according to the type of press. In case the belt is in pause mode, the vibration intensity is changed.

## Continuous and repeated vibration signals

To start the vibration when a belt is connected your application must call `startNavigation()`. The parameters determine the type of vibration signal, the direction and type of orientation of the signal. The vibration signal can be updated by calling `updateNavigationSignal()`.

```swift
// Start a continuous signal towards East
beltController.startNavigation(direction: 90, isMagneticBearing: true, signal: .continuous)
```

To stop the vibration while staying in `.navigating` state, pass `nil` as signal type.

```swift
// Stop the vibration if in `.navigating` state
beltController.updateNavigationSignal(direction: 0, isMagneticBearing: true, signal: nil)
```

## Vibration notifications

In addition to continuous or repeated vibration signals, some temporary vibration signals can be started.

* **notifyDestinationReached():** Starts a single iteration of the destination reached signal. Using this method, it is possible to stop the navigation when the signal is performed.
* **notifyDirection():** Starts a temporary vibration in a given direction.
* **notifyWarning():** Starts a warning vibration signal.
* **notifyBeltBatteryLevel():** Starts the battery level signal of the belt.

Exemple of temporary signal:

```swift
// Starts a temporary vibration on the left
beltController.notifyDirection(direction: 270, isMagneticBearing: false)
```

## Vibration intensity

For all vibration signals except the operation warning, the default vibration intensity of the belt is used. When a belt is connected, the default intensity can be retrieved with the property `defaultVibrationIntensity`. To change the default vibration intensity the method `changeDefaultVibrationIntensity()` must be used. When a belt is connected, the delegate is informed of vibration intensity changes via the callback `onBeltDefaultVibrationIntensityChanged()`. Note that the vibration intensity can also be changed using the buttons of the belt.

## Belt orientation

The orientation of the belt (relative to magnetic North) is notified to the delegate via the callback `onBeltOrientationUpdated()`. The orientation is updated every 500 milliseconds. The last orientation value can also be retrieved with the property `beltHeading`. In addition, the property `beltOrientationAccurate` indicates if the orientation is accurate.

## Belt battery level

The battery level of the belt is notified to the delegate via the callback `onBeltBatteryLevelUpdated()`. The last known value of the belt battery level can also be retrieved with the property `beltBatteryLevel`, and the power status via the property `beltPowerStatus`.

## Compass accuracy signal

The belt emits a vibration signal to indicate that the internal compass is inaccurate. This may happen when the belt is used indoor or in a place with magnetic interferences. This compass accuracy signal is performed in compass mode, crossing mode and in application mode (the mode used in navigation). For some applications it is preferable to disable the compass accuracy signal, for instance, because vibration signals are not relative to magnetic North or orientation accuracy is not critical.

You can retrieve the compass accuracy signal state via the property `compassAccuracySignalEnabled`. However, the value may be unknown for a short period after connection. The state of the compass accuracy signal can be changed when a belt is connected using the method `setCompassAccuracySignal(enable: Bool, persistent: Bool)`. Any update to the parameter (including the first reading of the parameter after connection) is notified to listeners via the callback `onCompassAccuracySignalStateUpdated(enabled: Bool)`.

:warning: The accuracy signal state setting can be temporary, i.e. defined for the current power cycle of the belt and reset when the belt is powered-off, or the setting can be persistent and saved on the belt. In case the setting is saved on the belt, it is important to inform the user of this new configuration as it will also impact the compass and crossing mode when no app is connected to the belt.

# General purpose API

:warning: It is not possible to use at the same time the navigation API and the general purpose API. The navigation API is a layer on top of the general purpose API. The navigation controller must register as connection delegate and command delegate to work properly.

## Connection management

### Connection manager and delegate

#### In short

```swift
// Import the FSLib
import FSLibIOs
// Implement the connection delegate protocol
class MyBeltConnectionDelegate: FSConnectionDelegate {
    var connectionManager: FSConnectionManager
    init() {
        // Retrieve connection manager
        connectionManager = FSConnectionManager.instance
        // Register as delegate
        connectionManager.delegate = self
        // ...
    }
}
```

### In details

The `FSConnectionManager` class is responsible for scan and connection procedures. A singleton of this class is available as static property `FSConnectionManager.instance`.


```swift
// Retrieve connection manager
var connectionManager: FSConnectionManager 
connectionManager = FSConnectionManager.instance
```

A delegate of the connection manager must be defined in order to manage scan and connection events. The connection delegate implements the `FSConnectionDelegate` protocol and is assigned to the `delegate` property of the connection manager.

```swift
// Import the FSLib
import FSLibIOs
// Implement the connection delegate protocol
class MyBeltConnectionDelegate: FSConnectionDelegate {
    // Connection manager
    var connectionManager: FSConnectionManager
    init() {
        // Retrieve connection manager
        connectionManager = FSConnectionManager.instance
        // Register as delegate
        connectionManager.delegate = self
        // ...
    }
}
```

### Scanning for a belt

#### In short

```swift
// Start the scan procedure
connectionManager.scanForBelt()
```

```swift
// Callback of the connection manager for scan results
func onBeltFound(device: CBPeripheral) {
    // ... Do something with the belt 
    // (e.g. ask the user a confirmation to connect to the belt or 
    // present the belt in a list of nearby belts)
}
// Callback of the connection manager for the termination of the scan procedure
func onBeltScanFinished(cause: FSScanTerminationCause) {
    // ... Do something according to the termination cause
}
```

```swift
// Method for stopping the scan procedure
connectionManager.stopScan()
```

#### In details

To search for nearby belts the method `scanForBelt()` of the connection manager must be called.

```swift
// Start the scan procedure
connectionManager.scanForBelt()
```

For each belt found, a callback informs the connection delegate that a belt has been found:

```swift
// Callback of the connection manager for scan results
func onBeltFound(device: CBPeripheral) {
    // ... Do something with the belt 
    // (e.g. ask the user a confirmation to connect to the belt or 
    // present the belt in a list of nearby belts)
}
```

The scan procedure stops after a timeout period or if the connection procedure is started. It can be also stopped with a call to `stopScan()`. In any case, a callback informs the delegate that the scan procedure is finished.

```swift
// Callback of the connection manager for the termination of the scan procedure
func onBeltScanFinished(cause: FSScanTerminationCause) {
    // ... Do something according to the termination cause
}
```

#### Custom implementation of the scan procedure

For a custom implementation of the scan procedure, the belt can be identified with the service UUID advertised by the belt and the prefix of the belt’s name (provided in the scan response packet). The advertised service UUID and the belt prefix are two static fields of the connection manager: `FSConnectionManager.ADVERTISED_SERVICE_UUID`, `FSConnectionManager.BELT_NAME_PREFIX`.

### Connecting to a belt

#### In short

```swift
// Connect the belt `device: CBPeripheral`
connectionManager.connectBelt(device)
```

```swift
// Callback of the connection manager to inform of a connection state change
func onConnectionStateChanged(previousState: FSConnectionState,
                              newState: FSConnectionState,
                              event: FSConnectionEvent) {
    // ... Update of the app according to the new state
}
```

```swift
// Disconnect the belt
connectionManager.disconnectBelt()
```

#### In details

The method `connectBelt()` of the connection manager is used to start the connection to a belt.

```swift
// Connect the belt `device: CBPeripheral`
connectionManager.connectBelt(device)
```

The connection procedure goes through different steps before an effective connection. For each state change the connection delegate is informed with the callback `onConnectionStateChanged`.

```swift
// Callback of the connection manager to inform of a connection state change
func onConnectionStateChanged(previousState: FSConnectionState,
                              newState: FSConnectionState,
                              event: FSConnectionEvent) {
    // ... Update of the app according to the new state
}
```

The connection states are the following:

+ `FSConnectionState.notConnected`: The belt is not connected.
+ `FSConnectionState.connecting`: The connection procedure has been started and the device tries to establish a connection with the belt.
+ `FSConnectionState.discoveringServices`: A Bluetooth connection has been established and services are being discovered.
+ `FSConnectionState.hanshake`: The services and characteristics have been discovered, and the smartphone read some parameters of the belt to prepare the command manager.
+ `FSConnectionState.connected`: The belt is connected and ready.

It is not necessary for the app to have distinct behavior for the states `connecting`, `discoveringServices` and `handshake`. These three states may be considered as a global `connecting` state.

During service discovery, iOS may automatically ask the user to authorize a Bluetooth connection. The default timeout period for the connection is relatively large because it includes such a user interaction.

### Disconnecting a belt

The method `disconnectBelt()` of the connection manager disconnect the belt. The disconnection is notified to the delegate by the callback `onConnectionStateChanged()`.

```swift
// Disconnect the belt
connectionManager.disconnectBelt()
```

## Command manager and delegate

#### In short

```swift
// Import the FSLib
import FSLibIOs
// Implement the command delegate protocol
class MyBeltCommandDelegate: FSComandDelegate {
    var commandManager: FSCommandManager
    init() {
        // Retrieve connection manager
        commandManager = FSConnectionManager.instance.commandManager
        // Register as delegate
        commandManager.delegate = self
        // ...
    }
}
```

#### In details

When a connection with a belt is established, a `FSCommandManager` object is used to control the belt. The command manager can be retrieved from the connection manager in its `commandManager` property. Note that is it not necessary to establish a connection for retrieving the command manager.

```swift
// Retrieve command manager
var commandManager: FSCommandManager
commandManager = connectionManager.commandManager
```

The notifications from the belt are transmitted to a `FSCommandDelegate`. The command delegate implements the `FSCommandDelegate` protocol and is assigned to the `delegate` property of the command manager.

```swift
// Import the FSLib
import FSLibIOs
// Implement the command delegate protocol
class MyBeltCommandDelegate: FSComandDelegate {
    var commandManager: FSCommandManager
    init() {
        // Retrieve command manager
        commandManager = FSConnectionManager.instance.commandManager
        // Register as delegate
        commandManager.delegate = self
        // ...
    }
}
```

## Belt status, events and parameters

### Belt mode

#### In short

```swift
// Mode of the belt
var currentMode: FSBeltMode = commandManager.mode
```

```swift
// Request the mode `requestedMode: FSBeltMode`
commandManager.changeBeltMode(requestedMode)
```

```swift
// Callbacks for mode change
func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
    // ... Handle mode change
}
func onBeltButtonPressed(button: FSBeltButton,
                         pressType: FSPressType,
                         previousMode: FSBeltMode,
                         newMode: FSBeltMode) {
    // ... Handle button press and mode change
}
```

#### In details

The mode of the belt is stored in the `mode` property of the command manager. The value is `FSBeltMode.unknown` when no connection is established.

```swift
// Mode of the belt
var currentMode: FSBeltMode = commandManager.mode
```

The method `changeBeltMode()` of the command manager can be used to change the mode of the belt.

```swift
// Request the mode `requestedMode: FSBeltMode`
commandManager.changeBeltMode(requestedMode)
```

A notification is sent by the belt when the mode is changed. The change can be the result of an application request or a button pressed on the belt. The command delegate is informed of the new mode with the `onBeltModeChanged()` method or `onBeltButtonPressed()` method.

```swift
// Callbacks for mode change
func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
    // ... Handle mode change
}
func onBeltButtonPressed(button: FSBeltButton,
                         pressType: FSPressType,
                         previousMode: FSBeltMode,
                         newMode: FSBeltMode) {
    // ... Handle button press and mode change
}
```

:warning: Only one of the two callbacks `onBeltModeChanged()` and `onBeltButtonPressed()` is called when the mode of the belt is changed. If a button on the belt is pressed and result in a mode change, only the method `onBeltButtonPressed()` is called and the current mode of the belt can be retrieved with the parameter `newMode`.

### Button press events

Some button-press events are notified through the delegate method `onBeltButtonPressed()`. When a button-press results in a mode change, the event is systematically notified and the parameters `previousMode` and `newMode` inform about the mode change.

```swift
// Callbacks for button-press
func onBeltButtonPressed(button: FSBeltButton,
                         pressType: FSPressType,
                         previousMode: FSBeltMode,
                         newMode: FSBeltMode) {
    // ... Handle button press and mode change
}
```

### Belt battery status

The last known belt-battery status is available in the `beltBatteryStatus` property of the command manager. Updates of the battery status are notified with the delegate method `onBeltBatteryStatusUpdated()`.

```swift
// Current battery status of the belt
let currentBeltBatteryStatus = commandManager.beltBatteryStatus
```

```swift
// Update of the battery status
func onBeltBatteryStatusUpdated(status: FSBatteryStatus) {
	// ... Behavior on belt-battery status update
}
```

`FSBatteryStatus` is a structure with the following properties:
* `powerStatus`: The power-supply status of the battery (charging, on battery, external power supply, or unknown).
* `batteryLevel`: The battery level in percent, or the value `-1` if the battery level is unknown.
* `batteryTteTtf`: The time-to-empty or time-to-full in seconds. This property indicates the time-to-full when charging, and time-to-empty when the belt is on battery. The value is `-1` if the time-to-empty or time-to-full is unknown.

### Belt orientation

The belt can send notifications with its orientation. To receive orientation-notifications the method `startOrientationNotifications()` of the command manager must be called. Notifications can be stopped with the method `stopOrientationNotifications()`. The command delegate is notified of orientation updates with the method `onBeltOrientationNotified()`. The last known orientation is also available in the `beltOrientation` property of the command Manager.

### Firmware version

When a belt is connected, the firmware version is available in the `firmwareVersion` property of the command manager.

## Control of the vibration

### Vibration intensity

#### In short

```swift
// Current default vibration intensity
let currentIntensity = commandManager.defaultIntensity
```

```swift
// Change the default vibration intensity
commandManager.changeDefaultIntensity(newIntensity)
```

```swift
// Callback for default intensity change
func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        // ... Behavior on default intensity change
}
```

#### In details

A default vibration intensity is defined for the compass signal and for vibration commands. This default intensity can be changed directly on the belt (in pause mode, by pressing compass or home buttons) or via the command manager. The current default intensity is stored in the `defaultIntensity` property of the command manager.

```swift
// Current default vibration intensity
let currentIntensity = commandManager.defaultIntensity
```

The value can be changed with the method `changeDefaultIntensity()` of the command manager.

```swift
// Change the default vibration intensity
commandManager.changeDefaultIntensity(newIntensity)
```

When the default intensity has been changed by either an app request or a button press, the `onDefaultIntensityChanged()` callback is used to inform the delegate of the new default intensity.

```swift
// Callback for default intensity change
func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        // ... Behavior on default intensity change
}
```

### Simple vibration signals

A vibration signal can be started, in app mode, with the methods `vibrateAtMagneticBearing()` and `vibrateAtAngle()` of the command manager.

:warning: Continuous or repeated vibration signals can only be started in app-mode.

With the method `vibrateAtMagneticBearing()`, the orientation of the vibration is relative to the magnetic North. For instance, a direction value of 90° makes the belt vibrates towards East.

```swift
// Start a continuous vibration signal toward East
commandManager.vibrateAtMagneticBearing(direction: 90, signal: .continuous)
```

For the method `vibrateAtAngle()`, the orientation of the vibration is defined as an angle from the front vibromotor of the belt. For instance, an angle of 270° makes the belt vibrates on the left.

```swift
// Start a continuous vibration signal on the left
commandManager.vibrateAtAngle(direction: 90, signal: .continuous)
```

### Special vibration signals

To start a special vibration signal, such as a warning signal, the method `signal()` of the command manager can be used. Contrary to continuous or repeated vibration signals, a special signal may be started in other modes than the app-mode.

```swift
// Start the warning signal (single iteration of the vibration pattern)
commandManager.signal(signalType: .warning)
```

### Vibration-channel configuration

A vibration-channel configuration allows to define all parameters of a vibration signal. The method `configureVibrationChannel()` of the command manager sends channel-configuration commands to the belt.

:warning: A vibration-channel configuration is accepted by the belt if the belt is in App-mode, or if 1) the channel index is 0 and 2) the number of iteration is limited and 3) the other channels are not cleared. These conditions avoid conflicts with the vibration managed by the belt (e.g. wait signal or compass signal).

The parameters of a vibration-channel configuration are the following:
* `channelIndex`: The channel index to configure. The belt has four channels (index 0 to 3).
* `pattern`: The vibration pattern to use.
* `intensity`: The vibration intensity in range \[0-100\] or -1 to use the default vibration intensity.
* `orientationType`: The type of orientation value.
* `orientation`: The orientation value.
* `patternIterations`: The number of iterations of the vibration pattern or -1 to repeat indefinitively the vibration pattern. The maximum value is 255 iterations.
* `patternPeriod`: The duration in milliseconds of one pattern iteration. The maximum period is 65535 milliseconds.
* `patternStartTime`: The starting time in milliseconds of the first pattern iteration.
* `exclusiveChannel`: `true` to suspend other channels as long as this vibration-channel is used.
* `clearOtherChannels`: `true` to stop and clear other channels when this vibration-channel configuration is applied.

Some example of vibration-channel configuration:

```swift
// Start a custom vibration: 5 pulses on left
commandManager.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.singleLong,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.angle,
            orientation: 270,
            patternIterations: 5,
            patternPeriod: 1000,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true);

// Start a custom vibration: 3 seconds continuous on East
commandManager.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.continuous,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.magneticBearing,
            orientation: 90,
            patternIterations: 1,
            patternPeriod: 3000,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true)
	    
// Start a custom vibration: Continuous pulse on front and back
commandManager.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.singleShort,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.binaryMask,
            orientation: 0b0000000100000001,
            patternIterations: -1,
            patternPeriod: 750,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true)
```

### Stop vibration

To stop the vibration in app-mode, the method `stopVibration()` can be used.







