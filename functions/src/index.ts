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
      // Query the followers sub-collection of that restaurant
      const followersSnapshot = await db
        .collection("restaurants")
        .doc(restaurantId)
        .collection("followers")
        .get();

      if (followersSnapshot.empty) {
        console.log("No followers found for restaurant", restaurantId);
        return;
      }

      // Collect user IDs from the followers sub-collection
      // Assuming the document ID in 'followers' is the user ID
      const userIds = followersSnapshot.docs.map((doc) => doc.id);

      // Fetch user documents to get FCM tokens
      // Note: Firestore 'in' query supports up to 10 items.
      // For scalability, we should process in batches or individually.
      // Here we will fetch individually for simplicity in this context,
      // but in production, batching is recommended.

      const tokens: string[] = [];

      // Create an array of promises to fetch user data
      const userPromises = userIds.map(async (userId) => {
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData && userData.fcmToken) {
                return userData.fcmToken as string;
            }
        }
        return null;
      });

      // Wait for all fetches
      const results = await Promise.all(userPromises);

      // Filter out nulls
      results.forEach((token) => {
          if (token) tokens.push(token);
      });

      if (tokens.length === 0) {
        console.log("No valid FCM tokens found");
        return;
      }

      // Send Push Notification
      const payload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: `${restaurantName} just posted a new dish!`,
          body: "Tap to see what's cooking.",
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
