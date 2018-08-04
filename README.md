# SwiftOTP

OTP App with Siri Integration, support for Shortcuts, and for x-callback-url.

<a href="Screenshots/ScreenShot1.png"><img src="Screenshots/ScreenShot1.png" width="120" alt="Screenshot 1"></a>
<a href="Screenshots/ScreenShot2.png"><img src="Screenshots/ScreenShot2.png" width="120" alt="Screenshot 2"></a>
<a href="Screenshots/ScreenShot3.png"><img src="Screenshots/ScreenShot3.png" width="120" alt="Screenshot 3"></a>
<a href="Screenshots/ScreenShot4.png"><img src="Screenshots/ScreenShot4.png" width="120" alt="Screenshot 4"></a>

**⚠️ Note:** This app is still a work in progress. It might never make it into production level! There might be bugs and security issues not yet found. **Therefore I strongly advise against using this App for your own personal OTP codes.** Instead, you should use test (fake) OTP tokens, which you can generate from sites like [www.xanxys.net/totp](http://www.xanxys.net/totp/) and [authenticator.ppl.family](https://authenticator.ppl.family).

## About

SwiftOTP is a modern second-factor authentication (TOTP and HOTP) application for iOS written in Swift.

This app is partly based on [RedHat's FreeOTP](https://github.com/freeotp/freeotp-ios), from which the OTP model classes were used. However, everything else is original work.

## Motivation

Although FreeOTP is a good App, it is still not updated for the latest iPhones, and it lacks support for the latest and coolest iOS features, such as Siri and Shortcuts integration.

This means that you can setup Siri to reply to a prompt such as "Hey Siri, OTP code for Google" with "The OTP code for Google is 123456"; and also integrate it into Shortcuts, for whatever use case you might have.

This was also an opportunity for me to play with the x-callback-url protocol integration, which this apps uses to allow other apps to fetch OTP codes. This requires a user to authorize each app individually, and they can also revoke authorizations for each authorized app.

## How to Use

### Siri Intent

Every time you tap the "eye" icon on a token cell to show its code, SwiftOTP donates a Siri intent to the system. After that is done, you can go to the Settings App and navigate to "Siri & Search > More Shortcuts". There all the recent donations that all Apps made to iOS, including the SwiftOTP ones (one intent for each OTP token donated). Tap any donation to record a voice prompt that you can use to get Siri to run that intent for you. After the intent runs (in the background), Siri will show you and say the OTP code out loud.

### Shortcuts

Shortcuts can't pass data between apps. Therefore SwiftOTP can place the OTP code for the intent on the pasteboard for 3 seconds. This is disabled by default. To enable it, from inside SwiftOTP, navigate to "Preferences > Security" and enable the toggle next to "Also Place in Clipboard".

### x-callback-url

The documentation for the x-callback-api implemented by SwiftOTP can be found [here](https://github.com/brunophilipe/SwiftOTP/blob/master/SwiftOTP/Supporting%20Files/SwiftOTP.md). You can also build and run the OTPCallbackDemo target (included in the app project) to get a working demo of the integration.

## Security Considerations

### Why support x-callback-url? Tokens are supposed to be secret!

This is true! OTP Codes are sensitive, and SwiftOTP stores them in the device keychain so that no other apps can access them (**unless the device is jailbroken!**).

This doesn't mean there are no use cases where a user might want another App to access the OTP code for one of their accounts. Although there aren't many use cases for this currently, it is possible that by creating these facilities, and by implementing them correctly, novel use cases might be brought to light.

On top of that, OTP codes can do more than just being used to authorize a login operation. One interesting (albeit a bit extreme) example is [otp-ssh](https://github.com/deamwork/otp-ssh). This utility changes the port a server uses to listen to SSH connections every 30 seconds by using iptables rerouting.

The potential for innovative and curious uses of OTP codes is currently very much unexplored.

### Why integrate with Siri? They'll say your codes out loud!

That is not the case if the device is set to silent mode, or has earphones connected. Considering many people use earphones to listen to music or make calls during the day while sitting at their desk anyway, integrating Siri so they can say the codes without having to manually operate the phone can cause a big efficiency improvement.

### Why did you do X??? Security!

Once again, this app is a work in progress, and pretty much a proof-of-concept. I'm not telling anyone to replace their current OTP apps with SwiftOTP (actually, I do the exact opposite of that in the beginning of this readme). I imagined what it would be like to create these integrations and decided to build them.

## License

SwiftOTP is licensed under the Apache License Version 2.0. See LICENSE.

```
Copyright 2018 Bruno Philipe

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```