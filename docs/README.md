# FSLib-iOS Documentation

FSLib-iOS is an iOS library to control the feelSpace naviBelt from your application.

# Content

* [Copyright and license notice](#copyright-and-license-notice)
* [Introduction to the feelSpace belt](#introduction-to-the-feelspace-belt)
  * [Belt buttons and modes](#belt-buttons-and-modes)
  * [Bluetooth communication](#bluetooth-communication)
* [FSLib for iOS](#fslib-for-ios)
  * [Structure of the repository](#structure-of-the-repository)
  * [Structure of the FSLib framework](#structure-of-the-fslib-framework)
  * [Integration of the FSLib in a XCode project](#integration-of-the-fslib-in-a-xcode-project)
* [Navigation API](#navigation-api)
  * [Introduction](#introduction)
  * [Connection and disconnection of a belt](#connection-and-disconnection-of-a-belt)
  * [Vibration for the navigation](#vibration-for-the-navigation)
  * [Vibration for navigation events](#vibration-for-navigation-events)
  * [Home-button press event](#home-button-press-event)
  * [Belt orientation](#belt-orientation)
  * [Belt battery level](#belt-battery-level)
  * [Belt heading offset](#belt-heading-offset)
* [General purpose API](#general-purpose-api)
  * [Overview](#overview)
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

Copyright feelSpace GmbH, 2017-2019.

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

# FSLib for iOS

## Structure of the repository

The repository contains one XCode workspace with four modules:
* **FSLibIOs**: The FSLib framework to be use for connecting and controlling a belt from an app. The module is implemented in Swift 3.
* **FSLibIOsDemo**: A demo application for iPhone that illustrates how to use the FSLib framework. The module is implemented in Swift 3.
* **FSLibIOsNaviDemo**: A demo application for iPhone that illustrate the navigation features of the FSLib interface for navigation apps.
* **FSLibIOsObjcNaviDemo**: An objectice-C demo for iPhone that illustrate the navigation features of the FSLib interface for navigation apps.

Only the two modules `FSLibIOs` and `FSLibIOsDemo` are relevant to use the belt in a general-purpose application.

## Integration of the FSLib in a XCode project

The `FSLibIOs` framework can be added in your XCode project as a "Linked Framework". This can be done in the "General" configuration pane of your XCode project. You can also create a local Pod with the `FSLibIOs` framework.

:warning: To use the FSLib, the project must be configured to support Bluetooth functionalities. In the `Info.plist` configuration file of your project, an entry must be added in the `Required background modes` with the value `bluetooth-central`. This configuration is detailed in the apple developer guide: [Core Bluetooth Background Processing for iOS Apps](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html).

## Structure of the FSLib framework

In the `FSLibIOs` framework, four files are exposed for the integration of FSLib in an application. The other classes or protocols are intern to the module and are more likely to change in future versions of the FSLib.
* `FSConnectionManager.swift`: The class used for retrieving, scanning and connecting to a belt.
* `FSConnectionDelegate.swift`: The protocol containing callbacks to scan and connection events.
* `FSCommandManager.swift`: The class used to send command to the belt.
* `FSCommandDelegate.swift`: The protocol containing callbacks of the command manager and callback for belt events.

# Navigation API

## Introduction

*TODO*
Principle and limits. Files. Demo.

## Connection and disconnection of a belt

*TODO*

## Vibration for the navigation

*TODO*

## Vibration for navigation events

*TODO*

## Home-button press event

*TODO*

## Belt orientation

*TODO*

## Belt battery level

*TODO*

## Belt heading offset

*TODO*

# General purpose API

## Overview

*TODO*
Principle and limits. Files. Demo.

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







