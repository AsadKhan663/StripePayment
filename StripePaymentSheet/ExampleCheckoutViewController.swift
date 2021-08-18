//
//  ExampleCheckoutViewController.swift
//  StripePaymentSheet
//
//  Created by Asad Khan on 6/14/21.
//
import Foundation
import Stripe
import UIKit

class ExampleCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    var paymentSheet: PaymentSheet?
    //var paymentAPI:DoPaymentAPI?
    let backendCheckoutUrl = URL(string: "https://api/doPayment")!  // An example backend endpoint

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false
        let parameters = ["amount":"500"]
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
                request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
                guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    return
                }
                request.httpBody = httpBody
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        as? [String: Any],
                    let result = json["result"] as? NSDictionary,
                    let customerEphemeralKeySecret = result["ephemeralKey"] as? String,
                    let paymentIntentClientSecret = result["paymentIntent"] as? String,
                    let cust_id = result["customer"] as? String,
                   // let publishableKey = json["publishableKey"] as? String,
                    let self = self
                else {
                    // Handle error
                    return
                }
                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = "pk_test_51EuJ1FDVK2M8mum3eEhPXYQuY82dJS3jKXrIfpeu7ExLYXcrBXlxWzcTGXn5S7IvMrmiKMqAvN0nDSKLAOEEBngP00HiCK3Nxb"

                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "com.foo.example", merchantCountryCode: "US")
                configuration.customer = .init(
                    id: cust_id, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration)

                DispatchQueue.main.async {
                    self.buyButton.isEnabled = true
                }
            })
        task.resume()
    }

    @objc
    func didTapCheckoutButton() {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.displayAlert("Your order is confirmed!")
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print(error)
                self.displayAlert("Payment failed: \n\(error.localizedDescription)")
            }
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
