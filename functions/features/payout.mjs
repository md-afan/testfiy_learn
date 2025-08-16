import axios from "axios";
import * as functions from "firebase-functions";

const CASHFREE_CLIENT_ID = process.env.CASHFREE_APP_ID;
const CASHFREE_CLIENT_SECRET = process.env.CASHFREE_SECRET_KEY;

const CASHFREE_ENV = "TEST"; // or "PROD"

export const getPayoutToken = functions.https.onCall(async (req, context) => {
  try {
    const res = await axios.post(
      "https://payout-gamma.cashfree.com/payout/v1/authorize",

      {},
      {
        headers: {
          "X-Client-Id": CASHFREE_CLIENT_ID,
          "X-Client-Secret": CASHFREE_CLIENT_SECRET,
          "Content-Type": "application/json",
        },
      }
    );
    console.log(res, res.data);
    console.log(CASHFREE_CLIENT_ID, CASHFREE_CLIENT_SECRET);
    return res.data;
  } catch (error) {
    throw new functions.https.HttpsError("unknown", error.message);
  }
});

export const requestWithdrawal = functions.https.onCall(async (req, context) => {
  const { token, beneficiaryId, amount } = req.data;
  try {
    const res = await axios.post(
      "https://payout-gamma.cashfree.com/payout/v1/requestTransfer",
      {
        beneId: beneficiaryId,
        amount: amount,
        transferId: `TXN_${Date.now()}`,
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );
    return res.data;
  } catch (error) {
    throw new functions.https.HttpsError("unknown", error.message);
  }
});
