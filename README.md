# 🚀 Medly

**Medly** is an intelligent, background-running SMS automation app designed specifically for e-commerce sellers in Algeria who use **Yalidine** for logistics. 

Whether you are a store owner looking to understand how this helps your business, or a developer looking to contribute, this guide explains everything you need to know.

📥 **[Download the Latest Medly APK (Android)](https://drive.google.com/file/d/1vftI55Gr8wo01nmvCobprtPxQXNTsuqZ/view?usp=drive_link)**

---

## 📖 What is Medly? (For Store Owners & Non-Developers)

Imagine having a personal assistant who constantly watches your Yalidine shipments, and the second a package goes out for delivery, they grab your phone and text the customer: *"Hello Ahmed, your package is arriving today!"* 

**That is exactly what Medly does.** 

Instead of paying for expensive bulk SMS services, Medly uses your Android phone's regular SIM card (and your standard SMS plan) to automatically send delivery updates to your customers. 

### How to use Medly (Step-by-Step):
1. **Create an Account:** You can register and create your user account directly inside the Medly app.
2. **Connect Your Store/Yalidine:** **⚠️ CRITICAL STEP:** Medly *must* be connected to your Yalidine account or e-commerce store to function. You will do this by entering your Yalidine API tokens in the app's Settings menu.
3. **Write Your Templates:** Go to the "Modèles" (Templates) tab and write what you want your texts to say. (e.g., *"Bonjour {{name}}, votre colis {{tracking}} est en route."*)
4. **Let it Run:** Once set up, the app runs quietly in the background. When your store/Yalidine updates a tracking status, Medly wakes up and automatically sends the SMS to the customer from your phone.

---

## 🏗 Architecture & Technical Details (For Developers)

Medly is built to be resilient, ensuring that webhooks are caught and SMS messages are dispatched even if the app is closed.

### 1. Technology Stack
* **Frontend:** Flutter (Dart). Chosen for rapid cross-platform UI development and deep native Android integrations.
* **Backend as a Service (BaaS):** Supabase. Used for seamless user authentication (Auth), data storage (PostgreSQL), and handling incoming webhooks via Edge Functions.
* **Background Processing:** `flutter_foreground_task`. This is the backbone of the app. It creates a persistent Android foreground service (with a low-priority notification) that keeps the Dart isolate alive to listen to real-time database updates from Supabase.
* **Telephony:** The app requests `SEND_SMS` permissions to natively dispatch SMS messages via the Android Telephony manager without requiring the user to press "Send".

### 2. The Data Workflow
1. **Event Trigger:** A package status changes on Yalidine (e.g., from "Hub" to "Out for Delivery").
2. **Webhook Reception:** Yalidine fires a webhook to a Supabase Edge Function.
3. **Database Update:** Supabase validates the webhook and updates the `sms_queue` table in the PostgreSQL database.
4. **Real-time Sync:** The Medly Android app, kept alive by `flutter_foreground_task`, maintains an active WebSocket connection to Supabase via `Supabase Realtime`.
5. **Execution:** The app detects the new row in `sms_queue`, formats the text message using the user's saved templates, extracts the phone number, and fires the native Android SMS intent.
6. **Logging:** The app updates the `sms_queue` status to `SENT` or `FAILED` so the user can view the outcome in the Logs screen.

### 3. Project Structure
* `lib/screens/`: Contains the modular UI screens (Dashboard, Logs, Templates, Settings, Auth).
* `lib/core/services/`: Contains the heavy lifting logic:
  * `foreground_task_handler.dart`: Manages the Android background service isolate.
  * `webhook_listener_service.dart`: Manages the Supabase Realtime WebSocket connection.
  * `sms_sender_service.dart`: Interfaces with Android native code to dispatch the SMS.
* `lib/core/theme/`: Custom dark-mode UI design tokens, colors, and typography matching the premium branding.

---

## 🚀 Setup & Installation

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Ensure you have an active Supabase project. Add your Supabase URL and Anon Key to `lib/main.dart` (or your `.env` file).
4. Run the app on a physical Android device (Emulators cannot send actual SMS messages): `flutter run`.
5. Grant the required SMS and Notification permissions when prompted by the app.
