# SwiftOTP

This document lists the implemented x-callback-url actions in SwiftOTP, which can be used by other apps to integrate with SwiftOTP and fetch OTP codes.

For more information, please build and run the demo app target `OTPCallbackDemo`.

## `/fetch-code`

Fetches an OTP code from SwiftOTP. This method is also used request user authorization for the fetch operation.

### Discussion:

When asked for authorization, the user is also asked which token should be associated to this request. Thereafter, all subsequent `fetch-code` requests will complete without user interaction.

The first time `fetch-code` is invoked, it is done with the required parameters `client_id` and `client_app`, with the optional `client_detail` parameter, but *without* a `client_secret` parameter. This will cause SwiftOTP to request user authorization and for a token. If the user authorizes and picks a token correctly, the response callback will include the `code` and `client_secret` response parameters.

Subsequent `fetch-code` invocations should use the exact same values of `client_id`, `client_app`, and `client_detail` (if `client_detail` was not issued in the first call, it should **not** be included in subsequent calls), along with the `client_secret` parameter returned by the first successful invocation. If successful, the callback will only include the `code` response parameter.

### Request Parameters:

* `client_id`: String, required – A valid UUID string.
* `client_app`: String, required – The human-readable name of the App.
* `client_secret`: String, optional for first invocation – A secret to identify an authorization.
* `client_detail`: String, optional – A detail for the request, such as the account's email address (this is shown to the user).

### Response Parameters:

* `code`: String – The OTP code.
* `client_secret`: String – Included only in the first invocation if the authorization succeeds.

## Observations:

The following method can be used to generate a valid UUID string:

```swift
UUID().uuidString
```
