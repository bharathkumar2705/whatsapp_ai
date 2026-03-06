const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Triggered whenever a new message is created in:
 *   chats/{chatId}/messages/{messageId}
 *
 * It reads the receiver's FCM token from their user document
 * and sends a push notification.
 */
exports.sendMessageNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
        const messageData = event.data.data();
        if (!messageData) return;

        const { senderId, receiverId, text, type } = messageData;
        // Don't notify yourself
        if (!receiverId || receiverId === senderId) return;

        const db = getFirestore();

        try {
            // ── Fetch sender info ────────────────────────────────────────────────
            const senderDoc = await db.collection("users").doc(senderId).get();
            const senderName = senderDoc.exists
                ? senderDoc.data().displayName || "Someone"
                : "Someone";

            // ── Fetch receiver's FCM token ────────────────────────────────────────
            const receiverDoc = await db.collection("users").doc(receiverId).get();
            if (!receiverDoc.exists) {
                console.log(`Receiver ${receiverId} not found in Firestore.`);
                return;
            }

            const receiverData = receiverDoc.data();
            const fcmToken = receiverData.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token for receiver ${receiverId}.`);
                return;
            }

            // ── Build notification body ───────────────────────────────────────────
            let body = text || "";
            if (type === "image") body = "📷 Photo";
            else if (type === "video") body = "🎥 Video";
            else if (type === "audio") body = "🎵 Voice message";
            else if (type === "document") body = "📄 Document";
            else if (type === "location") body = "📍 Location";
            else if (type === "gif") body = "GIF";
            // Truncate long text
            if (body.length > 100) body = body.substring(0, 97) + "...";

            // ── Send the notification ─────────────────────────────────────────────
            const message = {
                token: fcmToken,
                notification: {
                    title: senderName,
                    body: body,
                },
                data: {
                    chatId: event.params.chatId,
                    senderId: senderId,
                    type: type || "text",
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "high_importance_channel",
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            await getMessaging().send(message);
            console.log(`Notification sent to ${receiverId} (${senderName}: ${body})`);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    }
);

/**
 * (Optional) Triggered for group messages — sends to ALL participants except sender.
 */
exports.sendGroupMessageNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
        const messageData = event.data.data();
        if (!messageData) return;

        const { senderId, chatId, text, type } = messageData;
        const db = getFirestore();

        try {
            // Fetch the chat to get participants
            const chatDoc = await db.collection("chats").doc(chatId).get();
            if (!chatDoc.exists) return;

            const chatData = chatDoc.data();
            if (!chatData.isGroup) return; // Only for group chats

            const participants = chatData.participants || [];
            const recipients = participants.filter((uid) => uid !== senderId);

            if (recipients.length === 0) return;

            // Fetch sender name
            const senderDoc = await db.collection("users").doc(senderId).get();
            const senderName = senderDoc.exists
                ? senderDoc.data().displayName || "Someone"
                : "Someone";
            const groupName = chatData.groupName || "Group";

            // Build body
            let body = `${senderName}: ${text || ""}`;
            if (type === "image") body = `${senderName}: 📷 Photo`;
            else if (type === "video") body = `${senderName}: 🎥 Video`;
            else if (type === "audio") body = `${senderName}: 🎵 Voice message`;
            if (body.length > 100) body = body.substring(0, 97) + "...";

            // Collect tokens
            const tokenPromises = recipients.map((uid) =>
                db.collection("users").doc(uid).get()
            );
            const userDocs = await Promise.all(tokenPromises);
            const tokens = userDocs
                .filter((doc) => doc.exists && doc.data().fcmToken)
                .map((doc) => doc.data().fcmToken);

            if (tokens.length === 0) return;

            // Use sendEachForMulticast for multiple tokens
            const multicastMessage = {
                tokens: tokens,
                notification: {
                    title: groupName,
                    body: body,
                },
                data: {
                    chatId: chatId,
                    senderId: senderId,
                    type: type || "text",
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "high_importance_channel",
                        sound: "default",
                    },
                },
            };

            const response = await getMessaging().sendEachForMulticast(multicastMessage);
            console.log(`Group notification: ${response.successCount}/${tokens.length} sent`);
        } catch (error) {
            console.error("Error sending group notification:", error);
        }
    }
);
