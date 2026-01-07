import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const onNewVideo = functions.firestore
  .document("videos/{videoId}")
  .onCreate(async (snapshot, context) => {
    const videoData = snapshot.data();
    if (!videoData) return;

    const restaurantId = videoData.restaurantId;
    const restaurantName = videoData.restaurantName;
    const videoId = context.params.videoId;

    if (!restaurantId || !restaurantName) {
      console.log("Missing restaurant details in video");
      return;
    }

    try {
      // Query the users collection where following array contains that restaurantId
      const usersSnapshot = await db
        .collection("users")
        .where("following", "array-contains", restaurantId)
        .get();

      if (usersSnapshot.empty) {
        console.log("No followers found for restaurant", restaurantId);
        return;
      }

      const tokens: string[] = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No valid FCM tokens found");
        return;
      }

      // Send Push Notification
      const payload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: `Fresh from ${restaurantName}!`,
          body: "A new dish has been posted. Tap to watch.",
        },
        data: {
          videoId: videoId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      console.log("Notifications sent:", response.successCount);
      if (response.failureCount > 0) {
        console.log("Failed notifications:", response.failureCount);
      }
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
