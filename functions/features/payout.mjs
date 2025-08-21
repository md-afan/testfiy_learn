import axios from "axios";
import { onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";



// const CASHFREE_ENV = "TEST";

// const BASE_URL = CASHFREE_ENV === "PROD"
//   ? "https://payout-api.cashfree.com"
//   : "https://payout-gamma.cashfree.com";


async function getCashfreeToken() {
  try {
    const resp = await axios.post(
      'https://payout-gamma.cashfree.com/payout/v1/authorize',
      {},
      {
        headers: {
          'X-Client-Id': process.env.CASHFREE_APP_ID_PAYOUT,
          'X-Client-Secret': process.env.CASHFREE_SECRET_KEY_PAYOUT,
          "Content-Type": "application/json",
          "x-api-version": "2022-09-01"
        }
      }
    );

    console.log('API Response:', resp.data);

    if (resp.data.status === 'SUCCESS') {
      const token = resp.data.data?.token;
      if (!token) {
        throw new Error('Token missing in success response');
      }
      return token; // Returns "Bearer <actual_token>"
    } else {
      throw new Error(`Authorization failed: ${resp.data.message || 'Unknown error'}`);
    }
  } catch (error) {
    console.error('Error getting token:', error.response?.data || error.message);
    throw new Error(`Cashfree auth failed: ${error.message}`);
  }
}
const cashfreePayToPhone = onCall(async (data, context) => {
  const { phone, name, amount, transferId, remarks } = data;
  try {
    const token = await getCashfreeToken();
    console.log(data);
    const resp = await axios.post('https://payout-gamma.cashfree.com/payout/v1.2/directTransfer', {
      amount: amount,

      transferId,
      transferMode: 'phone',

      remarks,
      beneDetails: { name, phone }
    }, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      }
    });
    console.log(resp)
    return resp.data;
  } catch (error) {
    console.error('Cashfree error:', error.response?.data || error.message);
    throw new functions.https.HttpsError('unknown', 'Payout failed', error.response?.data || null);
  }
});

export default cashfreePayToPhone;