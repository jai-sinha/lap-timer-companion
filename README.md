# Lap Timer Companion

This is the companion app for my [lap-timer](https://github.com/jai-sinha/lap-timer) Garmin app. It is written in Swift and uses the Connect IQ iOS SDK to communicate with the lap-timer app over Bluetooth.

## Goals

- Save and display sessions recorded by the watch app
- Send track coordinates to the watch app

## Notes

- This project borrows from [this example's](https://github.com/dougw/Garmin-ExampleApp-Swift) Swift implementation of the Connect IQ iOS SDK. (Thanks, Doug!)
- You will need the ConnectIQ.framework for development/testing. Download it from the [Connect IQ iOS SDK repo](https://github.com/garmin/connectiq-companion-app-sdk-ios), but don't add the package to your project as a dependency. Instead, just drag the ConnectIQ.framework `/ConnectIQ.xcframework/ios-arm64/ConnectIQ.framework` file into your project at the top level.
