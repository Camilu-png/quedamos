/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

import * as functions from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifyFriendRequest = functions.onDocumentCreated(
  {
    document: "users/{toUid}/friendRequests/{fromUid}",
    region: "southamerica-west1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    if (!data) return;

    if (data.status !== "pending") return;

    const toUid = data.to;
    const fromName = data.name;

    const user = await admin.firestore().collection("users").doc(toUid).get();
    const fcmToken = user.get("fcmToken");

    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "Nueva solicitud de amistad",
        body: `${fromName} te ha enviado una solicitud de amistad`,
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`Notificación enviada a ${toUid}`);
    } catch (error) {
      console.error("Error enviando notificación:", error);
    }
  }
);


// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
