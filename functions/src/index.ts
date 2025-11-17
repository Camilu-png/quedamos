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
import {
  onDocumentUpdated,
  onDocumentDeleted} from "firebase-functions/v2/firestore";

admin.initializeApp();

// Notificar al usuario cuando reciba una nueva solicitud de amistad.

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

// Manejar la aceptación de una solicitud de amistad.

export const onFriendRequestDeleted = onDocumentDeleted(
  "users/{userId}/friendRequests/{otherUid}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as {
      from: string;
      to: string;
      name?: string;
      status: string;
    };
    const {from, to, status} = data;
    // Solo notificar si se borra la solicitud "sent"
    if (status !== "sent") {
      console.log("Se eliminó el pending → no notificar");
      return;
    }

    const db = admin.firestore();

    // Verificar si realmente se aceptó
    const acceptedRef = db
      .collection("users")
      .doc(from)
      .collection("friends")
      .doc(to);

    const acceptedSnap = await acceptedRef.get();

    // Notificar al usuario que envió la solicitud
    const fromSnap = await db.collection("users").doc(from).get();
    const token = fromSnap.get("fcmToken");
    const friendName = data.name ?? "Alguien";


    if (!acceptedSnap.exists) {
      console.log("Solicitud eliminada sin amistad → rechazo");

      // Notificar rechazo al que envió la solicitud
      await admin.messaging().send({
        token,
        notification: {
          title: "Solicitud rechazada 😢",
          body: `${friendName} no aceptó tu solicitud`,
        },
      });

      return;
    }

    console.log("Amistad detectada → notificar aceptación");
    if (!token) return;

    await admin.messaging().send({
      token,
      notification: {
        title: "¡Solicitud aceptada!",
        body: `${friendName} ahora es tu amigo 🎉`,
      },
    });
  }
);

type Ubicacion = {
  direccion: string;
  latitud: number;
  longitud: number;
  nombre: string;
};

type Plan = {
  planID: string;
  anfitrionID: string;
  anfitrionNombre?: string;
  titulo?: string;
  participantesAceptados?: string[];
  fecha?: FirebaseFirestore.Timestamp | null;
  hora?: string | null;
  ubicacion?: Ubicacion | null;
  fechaEsEncuesta?: boolean;
  horaEsEncuesta?: boolean;
  ubicacionEsEncuesta?: boolean;
};

/**
 * Envía una notificación push a un conjunto de usuarios por su UID.
 * @param {string[]} uids
 * @param {{title: string, body: string}} notification
 */
async function notifyUsers(
  uids: string[],
  notification: { title: string, body: string }) {
  const db = admin.firestore();
  for (const uid of uids) {
    const snap = await db.collection("users").doc(uid).get();
    const token = snap.get("fcmToken");
    if (!token) continue;

    await admin.messaging().send({
      token,
      notification,
    });
  }
}

// 1️⃣ Cambio asistencia (acepta/cancela)
export const notifyAttendanceChange = onDocumentUpdated(
  "planes/{planId}",
  async (event) => {
    const before = event.data?.before?.data() as Plan | undefined;
    const after = event.data?.after?.data() as Plan | undefined;
    if (!before || !after) return;

    const antes = before.participantesAceptados ?? [];
    const ahora = after.participantesAceptados ?? [];

    const anfitrion = after.anfitrionID;

    const newUid = ahora.find((u) => !antes.includes(u));
    if (newUid) {
      return notifyUsers([anfitrion], {
        title: after.titulo ?? "Nuevo asistente",
        body: "Alguien aceptó participar ✨",
      });
    }

    const removedUid = antes.find((u) => !ahora.includes(u));
    if (removedUid) {
      return notifyUsers([anfitrion], {
        title: after.titulo ?? "Cambio de asistencia",
        body: "Un asistente canceló su participación ❌",
      });
    }
  }
);

export const notifyPlanChanges = onDocumentUpdated(
  "planes/{planId}",
  async (event) => {
    const before = event.data?.before?.data() as Plan | undefined;
    const after = event.data?.after?.data() as Plan | undefined;
    if (!before || !after) return;

    const aceptados = (after.participantesAceptados ?? [])
      .filter((u) => u !== after.anfitrionID);

    if (aceptados.length === 0) return;

    const camposClave: [keyof Plan, keyof Plan][] = [
      ["fecha", "fechaEsEncuesta"],
      ["hora", "horaEsEncuesta"],
      ["ubicacion", "ubicacionEsEncuesta"],
    ];

    for (const [campo, flag] of camposClave) {
      const antes = JSON.stringify(before[campo]);
      const ahora = JSON.stringify(after[campo]);

      if (antes === ahora) continue;

      const eraEncuesta = Boolean(before[flag]);
      const esEncuesta = Boolean(after[flag]);

      if (eraEncuesta && !esEncuesta) {
        // De encuesta → fijo
        await notifyUsers(aceptados, {
          title: after.titulo ?? "Plan actualizado",
          body: `Se fijó la ${campo} del plan ✔`,
        });
      } else if (!eraEncuesta && esEncuesta) {
        // De fijo → encuesta
        await notifyUsers(aceptados, {
          title: after.titulo ?? "Votación abierta",
          body: `Se abrió votación para la ${campo} 🗳️`,
        });
      } else if (!eraEncuesta && !esEncuesta) {
        // Cambio normal sin encuesta
        await notifyUsers(aceptados, {
          title: after.titulo ?? "Plan actualizado",
          body: `El anfitrión cambió la ${campo} 🔄`,
        });
      }
    }
  }
);

// 3️⃣ Eliminación del plan → Cancelación 🚫
// Excluye anfitrión
export const notifyPlanDeleted = onDocumentDeleted(
  "planes/{planId}",
  async (event) => {
    const plan = event.data?.data() as Plan | undefined;
    if (!plan) return;

    const aceptados = (plan.participantesAceptados ?? [])
      .filter((u) => u !== plan.anfitrionID);
    if (aceptados.length === 0) return;

    await notifyUsers(aceptados, {
      title: plan.titulo ?? "Plan cancelado",
      body: `${plan.anfitrionNombre ??
        "El anfitrión"} canceló el plan” ❌`,
    });
  }
);
