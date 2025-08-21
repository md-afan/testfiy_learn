import axios from "axios";
import * as functions from "firebase-functions";

const generateCashfreeToken = functions.https.onCall(async (req, context) => {
    try {
        const { orderId, amount, uid, email, phone } = req.data;

        const response = await axios.post("https://sandbox.cashfree.com/pg/orders", {
            order_id: orderId,
            order_amount: amount,
            order_currency: "INR",
            customer_details: {
                customer_id: uid,
                customer_email: email,
                customer_phone: phone
            }
        }, {
            headers: {
                "Content-Type": "application/json",
                "x-client-id": process.env.CASHFREE_APP_ID,
                "x-client-secret": process.env.CASHFREE_SECRET_KEY,
                "x-api-version": "2022-09-01"
            }
        });

        return response.data;
    } catch (error) {
        console.error("Cashfree Token Error:", error.response?.data || error.message);
        throw new functions.https.HttpsError("internal", "Failed to generate token");
    }
});


export default generateCashfreeToken;