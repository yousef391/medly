# Medly 🚀

**Medly** is an automated, background-running SMS campaign and notification manager built specifically for e-commerce sellers in Algeria using **Yalidine** for shipping. 

Medly bridges the gap between your logistics and your customers by utilizing your phone's native SMS capabilities, eliminating the need for expensive third-party SMS gateways.

## 📱 How It Works (The Workflow)

1. **User Registration:** You can easily register and create a new user account directly within the app.
2. **API Connection:** Configure your Yalidine API credentials in the settings.
3. **Background Webhooks:** Medly runs a continuous, optimized background service (using `flutter_foreground_task`) that listens for webhook events from the Yalidine API.
4. **Trigger & Send:** Whenever a package status changes (e.g., "Out for delivery", "Ready for pickup", "Returned"), Yalidine pings your app. The app automatically pulls the correct custom SMS template, inserts the customer's name and tracking number, and sends an SMS directly from your device.

## ✨ Key Features

- **Dashboard:** A high-level overview of your automated campaigns, success rates, and SMS metrics.
- **Logs:** A complete history of every SMS sent and its delivery status.
- **Modèles (Templates):** Customizable dynamic SMS templates (e.g., *"Bonjour {{name}}, votre colis Yalidine {{tracking}} est arrivé !"*).
- **Background Execution:** Fully operates in the background, minimizing battery usage while never missing an update.

---

### ⚠️ Important Note
**Medly must be connected to your store and the Yalidine API.** 
For the automated SMS triggers to function properly, you must configure your API tokens in the settings and ensure your e-commerce platform/Yalidine account is actively pushing webhook updates to the app.

---

## 🛠 Tech Stack
- **Framework:** Flutter / Dart
- **Backend/Auth:** Supabase
- **Background Services:** `flutter_foreground_task`
- **UI/UX:** Custom dark-mode minimalist design
