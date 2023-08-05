# 🌌 Constellation

Starline security system API wrapper

```swift
var client = ApiClient(appId: appId, appSecret: appSecret, userLogin: userLogin, userPassword: userPassword)
await client.auth() { result in
    // Handle result
}
```
