// 📌 Archivo: setAdminRole.js
// Ejecutar con: node setAdminRole.js

const admin = require("firebase-admin");
const path = require("path");

// 📍 Ruta del archivo JSON de la clave privada
const serviceAccount = require(path.join(__dirname, "joyeria-95fe7-firebase-adminsdk-fbsvc-aff6dbef55.json"));

// Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

// 📍 UID y correo del admin (pon aquí tu usuario)
const ADMIN_UID = "8XMjfEPOzwgK2E64gVaoL7VUeRp2";   // 👈 UID de Firebase
const ADMIN_EMAIL = "slopezs27@miumg.edu.gt";        // 👈 correo del admin

async function setAdminRole() {
  try {
    // 1️⃣ Establecer custom claim en Authentication
    await auth.setCustomUserClaims(ADMIN_UID, { admin: true });
    console.log(`✅ Rol de ADMIN asignado al usuario ${ADMIN_EMAIL}`);

    // 2️⃣ (Opcional) Guardar también en la colección usuarios
    await db.collection("usuarios").doc(ADMIN_UID).set(
      {
        email: ADMIN_EMAIL,
        rol: "admin",
        actualizado: new Date().toISOString()
      },
      { merge: true }
    );

    console.log("✅ Documento de usuario actualizado en Firestore");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error al asignar rol:", error);
    process.exit(1);
  }
}

setAdminRole();
