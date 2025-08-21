import { onSchedule } from "firebase-functions/v2/scheduler";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { PubSub } from "@google-cloud/pubsub";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import * as functions from "firebase-functions";
import admin from "firebase-admin";
import dotenv from "dotenv";
dotenv.config();

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});
const db = admin.firestore();
const pubsub = new PubSub();

setGlobalOptions({ maxInstances: 10 });

export { default as generateCashfreeToken } from './features/payment.mjs';
export { default as cashfreePayToPhone } from './features/payout.mjs';


// 🔁 Scheduled Function (every 1 min)
export const sendQuizNotificationAndUpdateStatus = onSchedule(
  "every 1 minutes",
  async () => {
    const now = new Date();
    const quizzesSnapshot = await db
      .collection("quizzes")
      .where("isPublished", "==", true)
      .get();

    for (const doc of quizzesSnapshot.docs) {
      const quiz = doc.data();
      const quizId = doc.id;
      const title = quiz.title || "Untitled Quiz";
      const startTime = quiz.testDateTime?.toDate();
      const duration = parseInt(quiz.duration || "0");
      const teacherId = quiz.createdBy;
      const coachingCode = quiz.coachingCode;
      const endTime = startTime
        ? new Date(startTime.getTime() + duration * 60000)
        : null;

      if (!startTime || !endTime) continue;

      const notifications = [];
      const diffMinutes = Math.floor((startTime - now) / 60000);
      let newStatus = quiz.status;

      // 🟡 Check if quiz is running but not yet marked as "live"
      if (
        now >= startTime &&
        now <= endTime &&
        quiz.status !== "live"
      ) {
        const enrollmentSnapshot = await db
          .collection("quizzes")
          .doc(quizId)
          .collection("enrolledStudents")
          .get();

        const enrolledStudentCount = enrollmentSnapshot.size;

        if (enrolledStudentCount >= 10) {
          newStatus = "live";
          notifications.push("live");
        } else if (quiz.status !== "pending") {
          newStatus = "pending";
          notifications.push("insufficient_enrollment");
        }
      }

      // 🟥 If quiz has ended
      if (now > endTime && quiz.status !== "completed" && quiz.status !== "pending") {
        newStatus = "completed";
      }

      // 📝 Update Firestore if status has changed
      if (newStatus !== quiz.status) {
        await doc.ref.update({
          status: newStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (newStatus === "live") notifications.push("live");
      }

      // ⏰ Send reminders based on time difference
      if (diffMinutes === 1440) notifications.push("1d");
      if (diffMinutes === 60) notifications.push("1h");
      if (diffMinutes === 10) notifications.push("10m");

      // 📤 Publish all queued notifications
      for (const type of notifications) {
        await pubsub.topic("quizNotifications").publishMessage({
          json: { quizId, title, teacherId, coachingCode, timeType: type },
        });
      }
    }
  }
);

// 📨 Pub/Sub Worker Function
export const sendQuizNotificationWorker = onMessagePublished(
  "quizNotifications",
  async (event) => {
    const { quizId, title, teacherId, coachingCode, timeType } = event.data.message.json;
    console.log(teacherId, coachingCode);
    console.log(event.data.message.json, teacherId, coachingCode);

    const titles = {
      "1d": ["Quiz Tomorrow", "Upcoming Quiz Reminder"],
      "1h": ["Quiz in 1 Hour", "1 Hour Left"],
      "10m": ["Quiz in 10 Minutes", "10 Minutes Reminder"],
      "live": ["Quiz Started", "Quiz is Live"],
      "insufficient_enrollment": ["Quiz Not Started", "Quiz Not Live"],
    };

    const bodies = {
      "1d": [
        `Your quiz "${title}" is tomorrow. Be prepared!`,
        `The quiz "${title}" is scheduled for tomorrow.`,
      ],
      "1h": [
        `Reminder: Your quiz "${title}" starts in 1 hour.`,
        `The quiz "${title}" will start in 1 hour.`,
      ],
      "10m": [
        `Hurry! Your quiz "${title}" starts in 10 minutes.`,
        `The quiz "${title}" will begin shortly.`,
      ],
      "live": [
        `Your quiz "${title}" is now live! Join quickly.`,
        `The quiz "${title}" is now live. Monitor activity.`,
      ],
      "insufficient_enrollment": [
        `The quiz "${title}" could not start due to low enrollment. It wil
l be rescheduled.`,
        `Quiz "${title}" could not go live. Not enough students enrolled.`,
      ],
    };

    const [notifTitleStudent, notifTitleTeacher] = titles[timeType];
    const [notifBodyStudent, notifBodyTeacher] = bodies[timeType];

    const quizRef = db.collection("quizzes").doc(quizId);
    const enrolledSnapshot =
      await quizRef.collection("enrolledStudents").get();

    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    const notifDataStudent = {
      title: notifTitleStudent,
      body: notifBodyStudent,
      senderId: coachingCode,
      senderType: "coachingCodes",
      read: false,
      data: { id: quizId, type: "quiz", timeType: timeType, coachingCode },
      createdAt: timestamp,
    };

    const notifDataTeacher = {
      title: notifTitleTeacher,
      body: notifBodyTeacher,
      senderId: coachingCode,
      senderType: "coachingCodes",
      read: false,
      data: { id: quizId, type: "quiz", timeType: timeType, coachingCode },
      createdAt: timestamp,
    };

    for (const doc of enrolledSnapshot.docs) {
      const studentId = doc.id;
      await db.collection("students").doc(studentId)
        .collection("notifications").add(notifDataStudent);
    }

    if (teacherId) {
      await db.collection("teachers").doc(teacherId)
        .collection("notifications").add(notifDataTeacher);
    }

    try {
      await admin.messaging().send({
        topic: `quiz_${quizId}_${timeType}_students`,
        notification: {
          title: notifTitleStudent,
          body: notifBodyStudent,
        },
        data: {
          id: quizId,
          type: "quiz",
          timeType: timeType,
          coachingCode
        },
      });

      if (teacherId) {
        await admin.messaging().send({
          topic: `quiz_${quizId}_${timeType}_teacher`,
          notification: {
            title: notifTitleTeacher,
            body: notifBodyTeacher,
          },
          data: { id: quizId, type: "quiz", timeType: timeType, coachingCode },
        });
      }
    } catch (error) {
      console.log("FCM error", error);
    }
  },
);


export const generateLeaderboard =
  onDocumentUpdated("quizzes/{testId}", async (event) => {
    // Revenue distribution percentages
    const STUDENT_POOL_PERCENT = 65;
    const TEACHER_SHARE_PERCENT = 15;
    const APP_SHARE_PERCENT = 20;

    // Top 3 rank reward percentages from student pool
    const RANK_PERCENTS = { rank1: 8, rank2: 5, rank3: 3 };

    const before = event.data.before.data();
    const after = event.data.after.data();
    const testId = event.params.testId;

    // Only run when status changes to completed
    if (before.status === after.status
      || after.status !== "completed") return;

    const fee = after.fee || 0;
    const quizTitle = after.title || "Untitled";
    const createdBy = after.createdBy || null;
    const coachingCode = after.coachingCode || null;

    const messaging = admin.messaging();

    // Fetch all submissions
    const submissionsSnap = await db
      .collection("quizzes")
      .doc(testId)
      .collection("submissions")
      .get();

    if (submissionsSnap.empty) {
      console.log(`No submissions found for quiz: ${testId}`);
      return;
    }

    const submissions = [];
    submissionsSnap.forEach((doc) => {
      const data = doc.data();
      submissions.push({
        uid: doc.id,
        name: data.name || "Anonymous",
        score: data.score || 0,
        timeTaken:
          typeof data.timeTaken === "string"
            ? parseInt(data.timeTaken, 10)
            : data.timeTaken || Number.MAX_SAFE_INTEGER,
      });
    });

    // Sort by score desc, timeTaken asc
    submissions.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return a.timeTaken - b.timeTaken;
    });

    const enrolledRef = admin.firestore()
      .collection('quizzes')
      .doc(quizId)
      .collection('enrolledStudents');

    const snapshot = await
      enrolledRef.where('isPresent', '==', true).get();
    const presentCount = snapshot.size;
    const totalRevenue = presentCount * fee;

    const studentPool = totalRevenue * (STUDENT_POOL_PERCENT / 100);
    const teacherShare = totalRevenue * (TEACHER_SHARE_PERCENT / 100);
    const appShare = totalRevenue * (APP_SHARE_PERCENT / 100);

    const totalWinners = Math.floor(totalStudents * 0.4);
    const lowerRankCount = Math.max(0, totalWinners - 3);

    const rank1Base = studentPool * (RANK_PERCENTS.rank1 / 100);
    const rank2Base = studentPool * (RANK_PERCENTS.rank2 / 100);
    const rank3Base = studentPool * (RANK_PERCENTS.rank3 / 100);
    const rank3Cap = rank3Base;

    const remainingPool =
      studentPool - (rank1Base + rank2Base + rank3Base);
    let eachLowerRankReward =
      lowerRankCount > 0 ? remainingPool / lowerRankCount : 0;
    if (eachLowerRankReward > rank3Cap) {
      eachLowerRankReward = rank3Cap;
    }

    const actualLowerRankRewardTotal = eachLowerRankReward * lowerRankCount;
    const baseTotalUsed =
      rank1Base + rank2Base + rank3Base + actualLowerRankRewardTotal;
    const surplus = studentPool - baseTotalUsed;
    const surplusPerWinner = totalWinners > 0 ? surplus / totalWinners : 0;

    const fmt = (v) => Math.round(v * 100) / 100;

    const batch = db.batch();
    const leaderboardRef =
      db.collection("quizzes").doc(testId).collection("leaderboard");

    // Save shares on quiz doc
    batch.set(
      db.collection("quizzes").doc(testId),
      {
        teacherShare: fmt(teacherShare),
        appShare: fmt(appShare),
        studentPool: fmt(studentPool),
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );



    // ✅ Loop through student submissions
    for (let i = 0; i < submissions.length; i++) {
      const { uid, score, timeTaken } = submissions[i];
      const rank = i + 1;
      let reward = 0;

      if (i < totalWinners) {
        if (i === 0) reward = rank1Base;
        else if (i === 1) reward = rank2Base;
        else if (i === 2) reward = rank3Base;
        else reward = eachLowerRankReward;
        reward += surplusPerWinner;
      }

      const entry = {
        score,
        timeTaken,
        rank,
        reward: fmt(reward),
      };

      // Leaderboard entry
      batch.set(leaderboardRef.doc(uid), entry);

      // Wallet update (global)
      const walletRef = db.collection("wallets").doc(uid);
      const walletSnap = await walletRef.get();
      const currentBalance =
        walletSnap.exists ? walletSnap.data().balance || 0.0 : 0.0;
      const updatedBalance =
        reward > 0 ? currentBalance + reward : currentBalance;
      batch.set(
        walletRef,
        {
          balance: updatedBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Transaction in wallet
      if (reward > 0) {
        const txnRef = walletRef.collection("transactions").doc();
        batch.set(txnRef, {
          type: "Reward",
          amount: fmt(reward),
          note: `Rank ${rank} in quiz: ${quizTitle}`,
          quizId: testId,
          status: "success",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Notification for student
      try {
        await db.collection("students").doc(uid)
          .collection("notifications").add({
            title: `Quiz Completed: ${quizTitle}`,
            body: `Check your rank and rewards in the leaderboard.`,
            senderId: coachingCode,
            senderType: "coachingCodes",
            read: false,
            data: {
              id: testId,
              type: "leaderboard",
              coachingCode
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      } catch (error) {
        console.log(error);
      }
    }

    // ✅ Credit teacher share
    if (createdBy) {
      const teacherWalletRef = db.collection("wallets").doc(createdBy);
      const teacherWalletSnap = await teacherWalletRef.get();
      const currentTeacherBalance = teacherWalletSnap.exists
        ? teacherWalletSnap.data().balance || 0
        : 0;
      const updatedTeacherBalance = currentTeacherBalance + teacherShare;

      batch.set(
        teacherWalletRef,
        {
          balance: updatedTeacherBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Teacher transaction
      const teacherTxnRef = teacherWalletRef.collection("transactions").doc();
      batch.set(teacherTxnRef, {
        type: "reward",
        amount: fmt(teacherShare),
        note: `Earnings from quiz: ${quizTitle}`,
        quizId: testId,
        status: "success",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notification for teacher
      try {
        await db.collection("teachers").doc(createdBy).collection("notifications").add({
          title: `Quiz Earnings Credited`,
          body: `You earned ₹${fmt(teacherShare)} from quiz "${quizTitle}".`,
          senderId: coachingCode,
          senderId: "coachingCodes",
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: { type: "quiz", id: testId, coachingCode },
        });
      } catch (err) {
        console.warn("❌ Failed to write teacher notification:", err);
      }
    }

    // Commit batch
    await batch.commit();

    // ✅ Send push notifications
    try {
      await messaging.sendToTopic(`quiz_${testId}_students`, {
        notification: {
          title: `Quiz Completed: ${quizTitle}`,
          body: `Check your rank and rewards in the leaderboard.`,
        },
        data: { type: "quiz_reward", quizId: testId },
      });
    } catch (err) {
      console.warn("Failed to notify students topic:", err);
    }

    if (createdBy) {
      try {
        await messaging.sendToTopic(`quiz_${testId}_teacher`, {
          notification: {
            title: `Leaderboard Generated`,
            body: `Your quiz "${quizTitle}" is now completed.`,
          },
          data: { type: "leaderboard", quizId: testId },
        });
      } catch (err) {
        console.warn("❌ Failed to notify teacher topic:", err);
      }
    }
  });

export const subscribeToWeb = functions.https.onCall(async (req, context) => {
  try {
    const token = req.data.token;
    const topic = req.data.topic;

    if (!token || !topic) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing token or topic",
      );
    }

    await admin.messaging().subscribeToTopic(token, topic);
    return { success: true };
  } catch (err) {
    console.error("Subscription error:", err.message);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

export const unsubscribeToWeb = functions.https.onCall(async (req, context) => {
  try {
    const token = req.data.token;
    const topic = req.data.topic;

    if (!token || !topic) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing token or topic",
      );
    }

    await admin.messaging().unsubscribeFromTopic(token, topic);
    return { success: true };
  } catch (err) {
    console.error("Subscription error:", err.message);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

export const notifyTeacherOnStudentEnrollAndPayment = onDocumentCreated(
  "quizzes/{quizId}/enrolledStudents/{studentId}",
  async (event) => {
    const data = event.data.data();
    const { quizId, studentId } = event.params;

    try {
      // ✅ Only proceed if paid
      if (!data || !data.hasPaid) return;

      // ✅ Get Quiz Info
      const quizSnap = await db.collection("quizzes").doc(quizId).get();
      const studentDoc = await db.collection("students").doc(studentId).get();
      const studnetName = studentDoc.data().fullName;
      const quiz = quizSnap.data();
      if (!quiz || !quiz.createdBy) return;

      const teacherId = quiz.createdBy;
      const quizTitle = quiz.title || "Untitled Quiz";

      // ✅ Notify Teacher (Firestore + FCM)
      await db
        .collection("teachers")
        .doc(teacherId)
        .collection("notifications")
        .add({
          title: " New Student Enrolled",
          body: `${studnetName} enrolled and paid for "${quizTitle}".`,
          senderId: studentId,
          senderType: "students",
          read: false,
          data: {
            id: studentId, type: "students", coachingCode
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Notify Student (Firestore + FCM)
      await db.collection("students")
        .doc(studentId)
        .collection("notifications")
        .add({
          title: "Enrollment Confirmed",
          body: `You've successfully enrolled in "${quizTitle}".`,
          senderId: coachingCode,
          senderType: "coachingCodes",
          read: false,
          data: { id: quizId, type: "quiz", coachingCode },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });


      const teacherDoc = await db.collection("teachers").doc(teacherId).get();
      const teacherFcmTokens = teacherDoc.data().fcmTokens || [];

      if (teacherFcmTokens.length > 0) {
        const message = {
          tokens: teacherFcmTokens,
          notification: {
            title: "New Student Enrolled",
            body: `${studnetName} has enrolled and paid for your quiz
             "${quizTitle}".`,
          },
          data: {
            id: studentId, type: "students", coachingCode
          },
        };

        const response =
          await admin.messaging().sendEachForMulticast(message);
        if (response.failureCount > 0) {
          const failedTokens = [];

          response.responses.forEach((res, idx) => {
            if (!res.success) {
              failedTokens.push(teacherFcmTokens[idx]);
            }
          });
          const validTokens = teacherFcmTokens.filter(
            (token) => !failedTokens.includes(token),
          );

          if (validTokens.length !== teacherFcmTokens.length) {
            await db.collection("teachers").doc(teacherId).update({
              fcmTokens: validTokens,
            });
          }
        }
      }


      const studentFcmTokens = studentDoc.data().fcmTokens || [];
      if (studentFcmTokens.length > 0) {
        const message = {
          tokens: studentFcmTokens,
          notification: {
            title: "You're Enrolled!",
            body: `You joined "${quizTitle}". Best of luck!`,
          },
          data: { id: quizId, type: "quiz", coachingCode },
        };

        const response =
          await admin.messaging().sendEachForMulticast(message);
        if (response.failureCount > 0) {
          const failedTokens = [];

          response.responses.forEach((res, idx) => {
            if (!res.success) {
              failedTokens.push(studentFcmTokens[idx]);
            }
          });

          if (failedTokens.length > 0) {
            const validTokens = studentFcmTokens.filter(
              (token) => !failedTokens.includes(token),
            );

            if (validTokens.length !== studentFcmTokens.length) {
              await db.collection("students").doc(studentId)
                .update({ fcmTokens: validTokens });
            }
          }
        }
      }
    } catch (err) {
      console.error("❌Error sending notifications:", err);
    }
  },
);


// exports.generateLeaderboard =
//   onDocumentUpdated("quizzes/{testId}", async (event) => {
//     // Revenue distribution percentages
//     const STUDENT_POOL_PERCENT = 65;
//     const TEACHER_SHARE_PERCENT = 15;
//     const APP_SHARE_PERCENT = 20;

//     // Top 3 rank reward percentages from student pool
//     const RANK_PERCENTS = {
//       rank1: 8,
//       rank2: 5,
//       rank3: 3,
//     };

//     const before = event.data.before.data();
//     const after = event.data.after.data();
//     const testId = event.params.testId;

//     if (before.status === after.status ||
//       after.status !== "completed") return;

//     const fee = after.fee || 0;
//     const quizTitle = after.title || "Untitled";
//     const createdBy = after.createdBy || null;

//     const messaging = admin.messaging();

//     const submissionsSnap = await db
//       .collection("quizzes")
//       .doc(testId)
//       .collection("submissions")
//       .get();

//     if (submissionsSnap.empty) {
//       console.log(`No submissions found for quiz: ${testId}`);
//       return;
//     }

//     const submissions = [];
//     submissionsSnap.forEach((doc) => {
//       const data = doc.data();
//       submissions.push({
//         uid: doc.id,
//         name: data.name || "Anonymous",
//         score: data.score || 0,
//         timeTaken:
//           typeof data.timeTaken === "string" ?
//             parseInt(data.timeTaken, 10) :
//             data.timeTaken || Number.MAX_SAFE_INTEGER,
//       });
//     });

//     submissions.sort((a, b) => {
//       if (b.score !== a.score) return b.score - a.score;
//       return a.timeTaken - b.timeTaken;
//     });

//     const totalStudents = submissions.length;
//     const totalRevenue = totalStudents * fee;

//     const studentPool = totalRevenue * (STUDENT_POOL_PERCENT / 100);
//     const teacherShare = totalRevenue * (TEACHER_SHARE_PERCENT / 100);
//     const appShare = totalRevenue * (APP_SHARE_PERCENT / 100);

//     const totalWinners = Math.floor(totalStudents * 0.4);
//     const lowerRankCount = Math.max(0, totalWinners - 3);

//     const rank1Base = studentPool * (RANK_PERCENTS.rank1 / 100);
//     const rank2Base = studentPool * (RANK_PERCENTS.rank2 / 100);
//     const rank3Base = studentPool * (RANK_PERCENTS.rank3 / 100);
//     const rank3Cap = rank3Base;

//     const remainingPool = studentPool - (rank1Base + rank2Base + rank3Base);
//     let eachLowerRankReward =
//       lowerRankCount > 0 ? remainingPool / lowerRankCount : 0;
//     if (eachLowerRankReward > rank3Cap) {
//       eachLowerRankReward = rank3Cap;
//     }

//     const actualLowerRankRewardTotal = eachLowerRankReward * lowerRankCount;
//     const baseTotalUsed = rank1Base + rank2Base +
//       rank3Base + actualLowerRankRewardTotal;
//     const surplus = studentPool - baseTotalUsed;
//     const surplusPerWinner = totalWinners > 0 ? surplus / totalWinners : 0;
//     const fmt = (v) => Math.round(v * 100) / 100;

//     const batch = db.batch();
//     const leaderboardRef = db.collection("quizzes")
//       .doc(testId).collection("leaderboard");

//     batch.set(db.collection("quizzes").doc(testId), {
//       teacherShare: fmt(teacherShare),
//       appShare: fmt(appShare),
//       studentPool: fmt(studentPool),
//       generatedAt: admin.firestore.FieldValue.serverTimestamp(),
//     }, { merge: true });

//     const paymentRef = db.collection("payments").doc();
//     batch.set(paymentRef, {
//       quizId: testId,
//       totalRevenue: fmt(totalRevenue),
//       teacherShare: fmt(teacherShare),
//       appShare: fmt(appShare),
//       studentPool: fmt(studentPool),
//       createdAt: admin.firestore.FieldValue.serverTimestamp(),
//     });

//     for (let i = 0; i < submissions.length; i++) {
//       const { uid, score, timeTaken } = submissions[i];
//       const rank = i + 1;
//       let reward = 0;

//       if (i < totalWinners) {
//         if (i === 0) reward = rank1Base;
//         else if (i === 1) reward = rank2Base;
//         else if (i === 2) reward = rank3Base;
//         else reward = eachLowerRankReward;
//         reward += surplusPerWinner;
//       }

//       const entry = {
//         uid,
//         score,
//         timeTaken,
//         rank,
//         reward: fmt(reward),
//       };

//       batch.set(leaderboardRef.doc(uid), entry);
//       const walletRef = db.collection("wallets").doc(uid);
//       const walletSnap = await walletRef.get();
//       const currentBalance = walletSnap.exists ?
//         walletSnap.data().balance || 0 : 0;
//       // Step 2: Calculate updated balance
//       const updatedBalance = reward > 0 ?
//         currentBalance + reward : currentBalance;
//       batch.set(walletRef, {
//         balance: updatedBalance,
//         updatedAt: admin.firestore.FieldValue.serverTimestamp(),
//       }, { merge: true });

//       if (reward > 0) {
//         const txnRef = walletRef.collection("transactions").doc();
//         batch.set(txnRef, {
//           type: "Reward",
//           amount: fmt(reward),
//           note: `Rank ${rank} in quiz: ${quizTitle}`,
//           quizId: testId,
//           status: "success",
//           createdAt: admin.firestore.FieldValue.serverTimestamp(),
//         });
//       }


//       const individualPaymentRef = db.collection("payments").doc();
//       batch.set(individualPaymentRef, {
//         paymentId: individualPaymentRef.id,
//         studentUid: uid,
//         testId,
//         testTitle: quizTitle,
//         amount: fmt(fee),
//         type: "reward",
//         paidAt: admin.firestore.FieldValue.serverTimestamp(),
//         status: "success",
//         upiId: "wallet",
//       });

//       try {
//         db.collection("students").doc(uid).collection("notifications").add({
//           title: `Quiz Completed: ${quizTitle}`,
//           body: `Check your rank and rewards in the leaderboard.`,
//           data: {
//             type: "quiz_reward",
//             quizId: testId,
//           },
//           createdAt: admin.firestore.FieldValue.serverTimestamp(),
//         });
//       } catch (error) {
//         console.log(error);
//       }
//     }
//     await batch.commit();


//     try {
//       await messaging.sendToTopic(`quiz_${testId}_students`, {
//         notification: {
//           title: `Quiz Completed: ${quizTitle}`,
//           body: `Check your rank and rewards in the leaderboard.`,
//         },
//         data: {
//           type: "quiz_reward",
//           quizId: testId,
//         },
//       });
//     } catch (err) {
//       console.warn("Failed to notify students topic:", err);
//     }

//     if (createdBy) {
//       try {
//         await messaging.sendToTopic(`quiz_${testId}_teacher`, {
//           notification: {
//             title: `Leaderboard Generated`,
//             body: `Your quiz "${quizTitle}" is now completed.`,
//           },
//           data: {
//             type: "quiz_leaderboard",
//             quizId: testId,
//           },
//         });
//       } catch (err) {
//         console.warn("❌ Failed to notify teacher topic:", err);
//       }
//     }
//   });


// if new students is joined in coaching
// then push the notificaions teacher and student

export const notifyTeacherOnNewStudentJoin =
  onDocumentCreated("coachingCodes/{code}/students/{studentId}",
    async (event) => {
      const coachingCode = event.params.code;
      const studentId = event.params.studentId;
      const messaging = admin.messaging();

      try {
        const studentDoc = await db.collection("students").doc(studentId).get();
        const student = studentDoc.data();
        const studentName = student && student.name || "student";
        const studentFcmTokens = student && student.fcmTokens || [];

        const coachingDoc =
          await db.collection("coachingCodes").doc(coachingCode).get();
        const coachingData = coachingDoc.data();
        const coachingName = coachingData.name;
        const teacherId = coachingData && coachingData.createdBy;

        if (!teacherId) {
          console.error("No teacherId found for coaching code:", coachingCode);
          return;
        }

        const teacherRef = db.collection("teachers").doc(teacherId);
        // const teacherDocs = db.collection("coachingCodes").doc(coachingCode)
        //   .collection("teachers");

        const timestamp = admin.firestore.FieldValue.serverTimestamp();

        // ✅ Notify Teacher: Firestore
        await teacherRef.collection("notifications").add({
          title: "New Student Joined",
          body: `${studentName} has joined your coaching.`,
          senderId: studentDoc.id,
          senderType: 'students',
          read: false,
          data: { id: studentId, type: "students", coachingCode },
          createdAt: timestamp,
        });

        // ✅ Notify Teacher: FCM
        await messaging.send({
          topic: `${coachingCode}_teacher`,
          notification: {
            title: "New Student Joined",
            body: `${studentName} has joined ${coachingName ?? "your organization"}.`,
          },
          data: {
            id: studentId,
            type: "students",
            coachingCode
          },
        });

        // ✅ Notify Student: Firestore
        await db.collection("students")
          .doc(studentId)
          .collection("notifications")
          .add({
            title: `Welcome to ${coachingName}`,
            body: `You’ve successfully joined ${coachingName}.`,
            senderId: coachingCode,
            senderType: 'coachingCodes',
            read: false,
            data: {
              id: coachingCode,
              type: "coachingCodes",
              coachingCode
            },
            createdAt: timestamp,
          });

        // ✅ Notify Student: FCM
        if (studentFcmTokens.length > 0) {
          await messaging.sendEachForMulticast({
            tokens: studentFcmTokens,
            notification: {
              title: "Welcome to Coaching",
              body: `You’ve successfully joined ${coachingName}.`,
            },
            data: {
              id: coachingCode,
              type: "coachingCodes",
              coachingCode
            },
          });
        }
      } catch (error) {
        console.error("Error notifying teacher or student of join:", error);
      }
    });

export const notifyTransaction = onDocumentCreated(
  "wallets/{uid}/transactions/{txnId}",
  async (event) => {
    const snap = event.data;

    const uid = event.params.uid;
    const txnId = event.params.txnId;
    const data = snap.data(); // this is your transaction document data

    try {
      let role = null;
      let tokens = [];

      // 🔎 Check teachers first
      const teacherSnap = await admin.firestore().collection("teachers").doc(uid).get();
      if (teacherSnap.exists) {
        role = "teacher";
        tokens = teacherSnap.data().fcmTokens || [];
      } else {
        // 🔎 Otherwise check students
        const studentSnap = await admin.firestore().collection("students").doc(uid).get();
        if (studentSnap.exists) {
          role = "student";
          tokens = studentSnap.data().fcmTokens || [];
        }
      }


      // ✅ Get fields from transaction data
      const txnTitle = data.type
        || "Transaction Update";
      const txnAmount = data.amount || 0;

      // 📦 Build notification payload
      const notifTitle = "Transaction Alert";
      const notifBody = `${txnTitle} of ₹${txnAmount}`;

      const payload = {
        tokens: tokens,
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        data: {
          txnId: txnId,
          amount: txnAmount.toString(),
        },
      };

      // ✉️ Send push notification if tokens exist
      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast(payload);
      }

      //  Save notification in role-specific collection
      const notifData = {
        title: notifTitle,
        body: notifBody,
        senderId: uid,
        senderType: role === "teacher" ? "teachers" : "students",
        read: false,
        data: {
          id: txnId,
          type: "transections",
          amount: txnAmount.toString(),
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      };

      const notifCollection = db
        .collection(role === "teacher" ? "teachers" : "students")
        .doc(uid)
        .collection("notifications");
      await notifCollection.add(notifData);

    } catch (err) {
      console.error("Error in notifyTransaction:", err);
    }
  }
);


// cashfree payment getway intigration in firebase,
// when user pay the amount then update the wallet balance


export const notifyAllRolesOnQuizPublishOrUpdateTestDate =
  onDocumentUpdated("quizzes/{quizId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const messaging = admin.messaging();
    const quizId = event.params.quizId;
    const title = after.title;
    const coachingCode = after.coachingCode;
    const teacherId = after.createdBy;
    const messages = [];

    // ✅ PUBLISH
    if (!before.isPublished && after.isPublished) {
      try {
        // Teacher notification
        await db.collection("teachers")
          .doc(teacherId)
          .collection("notifications")
          .add({
            title: "Quiz Published",
            body: `Your quiz "${title}" has been successfully published.`,
            senderId: coachingCode,
            senderType: 'coachingCodes',
            reed: false,
            data: {
              id: quizId,
              type: 'quiz',
              timeType: null,
              coachingCode
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Student notifications
        const studentsRef = await db
          .collection("coachingCodes")
          .doc(coachingCode)
          .collection("students")
          .get();

        if (!studentsRef.empty) {
          const studentNotifs = studentsRef.docs.map(async (doc) => {
            const studentId = doc.id;
            await db.collection("students")
              .doc(studentId)
              .collection("notifications")
              .add({
                title: "New Quiz Published",
                body: `A new quiz has been published by your coaching.`,
                senderId: teacherId,
                senderType: 'teachers',
                read: false,
                data: {
                  id: quizId,
                  type: "quiz",
                  coachingCode
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
          });

          await Promise.all(studentNotifs);
        }

        // FCM Messages
        messages.push(
          {
            topic: `${coachingCode}_students`,
            notification: {
              title: "New Quiz Published",
              body: `A new quiz "${title}" is available from your coaching.`,
            },
            data: {
              id: quizId,
              type: "quiz",
              coachingCode
            },
          },
          {
            topic: `${coachingCode}_teacher`,
            notification: {
              title: "Quiz Published",
              body: `Your quiz "${title}" has been successfully published.`,
            },
            data: {
              id: quizId,
              type: "quiz",
              coachingCode
            },
          },
        );
      } catch (err) {
        console.error("Error on publish:", err);
      }
    }

    // ✅ UNPUBLISH
    if (before.isPublished && !after.isPublished) {
      try {
        // Teacher notification
        await db.collection("teachers")
          .doc(teacherId)
          .collection("notifications")
          .add({
            title: "Quiz Unpublished",
            body: `Your quiz "${title}" has been unpublished.`,
            senderId: coachingCode,
            senderType: 'coachingCodes',
            read: false,
            data: {
              id: quizId,
              type: 'quiz',
              coachingCode

            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Student notifications
        const studentsRef = await db
          .collection("coachingCodes")
          .doc(coachingCode)
          .collection("students")
          .get();

        if (!studentsRef.empty) {
          const studentNotifs = studentsRef.docs.map(async (doc) => {
            const studentId = doc.id;
            await db.collection("students")
              .doc(studentId)
              .collection("notifications")
              .add({
                title: "Quiz Unpublished",
                body: `Quiz "${title}" is no longer available.`,
                senderId: teacherId,
                senderType: 'teachers',
                read: false,
                data: { id: quizId, type: 'quiz', coachingCode },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
          });

          await Promise.all(studentNotifs);
        }

        // FCM Messages
        messages.push(
          {
            topic: `${coachingCode}_students`,
            notification: {
              title: "Quiz Unpublished",
              body: `Quiz "${title}" is currently unavailable.`,
            },
            data: {
              id: quizId,
              coachingCode,
              type: "unpublished",
            },
          },
          {
            topic: `${coachingCode}_teacher`,
            notification: {
              title: "Quiz Unpublished",
              body: `Your quiz "${title}" has been unpublished.`,
            },
            data: {
              quizId,
              coachingCode,
              type: "unpublished",
            },
          },
        );
      } catch (err) {
        console.error("Error on unpublish:", err);
      }
    }

    // ✅ TIME CHANGE
    const beforeStart = before.testDateTime &&
      before.testDateTime.toMillis() || 0;
    const afterStart = after.testDateTime && after.testDateTime.toMillis() || 0;

    if (beforeStart !== afterStart) {
      const formattedNewTime = new Date(afterStart).toLocaleString("en-IN", {
        timeZone: "Asia/Kolkata",
        hour: "2-digit",
        minute: "2-digit",
        day: "numeric",
        month: "short",
        year: "numeric",
      });

      try {
        // Teacher notification
        await db.collection("teachers")
          .doc(teacherId)
          .collection("notifications")
          .add({
            title: "Quiz Time Changed",
            body: `Your quiz "${title}" start time has been updated
               to ${formattedNewTime}.`,
            senderId: coachingCode,
            senderType: 'coachingCodes',
            redd: false,
            data: {
              id: quizId,
              type: "quiz",
              coachingCode
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Student notifications
        const studentsRef = await db
          .collection("coachingCodes")
          .doc(coachingCode)
          .collection("students")
          .get();

        if (!studentsRef.empty) {
          const studentNotifs = studentsRef.docs.map(async (doc) => {
            const studentId = doc.id;
            await db.collection("students")
              .doc(studentId)
              .collection("notifications")
              .add({
                title: "Quiz Time Updated",
                body: `Quiz "${title}" has a new start time:
                   ${formattedNewTime}.`,

                senderId: teacherId,
                senderType: "teachers",
                read: false,
                data: {
                  id: quizId,
                  type: quizId,
                  coachingCode
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
          });

          await Promise.all(studentNotifs);
        }

        // FCM Messages
        messages.push(
          {
            topic: `${coachingCode}_students`,
            notification: {
              title: "Quiz Time Updated",
              body: `Quiz "${title}" has a new start time:
                 ${formattedNewTime}`,
            },
            data: {
              quizId,
              coachingCode,
              type: "time_update",
            },
          },
          {
            topic: `${coachingCode}_teacher`,
            notification: {
              title: "Quiz Time Changed",
              body: `Your quiz "${title}" start time has been updated to
               ${formattedNewTime}.`,
            },
            data: {
              quizId,
              coachingCode,
              type: "time_update",
            },
          },
        );
      } catch (err) {
        console.error("Error on time change:", err);
      }
    }

    // ✅ SEND FCM NOTIFICATIONS
    if (messages.length > 0) {
      try {
        const sendAll = messages.map((msg) => messaging.send(msg));
        await Promise.all(sendAll);
      } catch (error) {
        console.error("Failed to send FCM notifications:", error);
      }
    }
  });




