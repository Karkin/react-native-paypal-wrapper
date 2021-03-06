
# react-native-paypal-wrapper

React Native PayPal wrapper for iOS and Android

## Getting started

`$ yarn add react-native-paypal-wrapper`

### Installation

`$ react-native link react-native-paypal-wrapper`

Extra steps for iOS 🙄 [see here](https://github.com/paypal/PayPal-ios-SDK#with-or-without-cocoapods)

## Usage
```javascript
import PayPal from 'react-native-paypal-wrapper';

// 3 env available: NO_NETWORK, SANDBOX, PRODUCTION
PayPal.initialize(PayPal.NO_NETWORK, "<your-client-id>");
PayPal.pay({
  price: '40.70',
  currency: 'MYR',
  description: 'Your description goes here',
}).then(confirm => console.log(confirm))
  .catch(error => console.log(error));
```

### Disclaimer

This project is created solely to suit our requirements, no maintenance/warranty are provided. Feel free to send in pull requests.

### Acknowledgement

This project is inspired by [MattFoley](https://github.com/MattFoley/react-native-paypal) (which does not support both Android and iOS simultaneously, and [shovelapps](https://github.com/shovelapps/react-native-paypal) a fork of the former repo (which we had some problems trying to integrate due to React Native version).
