# web_auth

- Install lib
```
  web_auth: 
```

- Example
```
// Present the dialog to the user
// https://developer.okta.com/docs/reference/api/oidc/#authorize
final String result = await WebAuth.open(context, authorizationUrl, redirectUri);

// Extract token from resulting url
final Uri token = Uri.parse(result);
// Just for easy parsing
final String normalUrl = 'http://website/index.html?${token.fragment}';
final String accessToken = Uri.parse(normalUrl).queryParameters['access_token'];
print('token');
print(accessToken);
```