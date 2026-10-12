const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * دالة سحابية (Cloud Function) تعمل تلقائياً بمجرد إنشاء مستند في مجموعة `notifications`
 * وتقوم بإرسال FCM Push Notification حقيقي إلى هاتف الخادم المستهدف عبر التوكن المسجل لديه
 */
exports.sendPushNotificationOnNewNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    // FCM has no Firebase emulator. Automatic emulator events must not contact live messaging.
    if (process.env.FUNCTIONS_EMULATOR === "true") return null;
    const notificationData = snap.data();
    if (!notificationData || notificationData.outboxId) return null;

    const recipientId = notificationData.recipientId;
    if (!recipientId) return null;

    try {
      // 1. جلب بيانات الخادم والتوكن الخاص به
      const khademDoc = await admin
        .firestore()
        .collection("khodam")
        .doc(recipientId)
        .get();
      if (!khademDoc.exists) {
        console.log(
          `Khadem document not found for recipientId: ${recipientId}`,
        );
        return null;
      }

      const profile = khademDoc.data();
      const fcmToken = profile?.fcmToken;
      const isTask = !!(
        notificationData.taskId || notificationData.data?.taskId
      );
      const pushText = isTask
        ? profile?.locale?.startsWith("en")
          ? { title: "New task", body: "Open Efteqad to view your assignment." }
          : { title: "مهمة جديدة", body: "افتح تطبيق افتقاد لعرض التكليف." }
        : {
            title: notificationData.title || "تنبيه جديد",
            body: notificationData.body || "",
          };
      if (!fcmToken) {
        console.log(`No FCM token registered for recipientId: ${recipientId}`);
        return null;
      }

      // 2. تجهيز حمولة الإشعار الفوري
      const message = {
        token: fcmToken,
        notification: {
          title: pushText.title,
          body: pushText.body,
        },
        data: {
          notificationId: context.params.notificationId,
          type: notificationData.type || "general",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          payload: JSON.stringify(notificationData.data || {}),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "efteqad_high_importance_channel",
            sound: "default",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
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

      // 3. إرسال الإشعار
      const response = await admin.messaging().send(message);
      console.log(
        `Successfully sent FCM notification to ${recipientId}:`,
        response,
      );
      return response;
    } catch (error) {
      console.error(
        `Error sending push notification to ${recipientId}:`,
        error,
      );
      return null;
    }
  });

const adminOps = require("./src/admin_operations");
exports.setKhademGrade = adminOps.setKhademGrade;
exports.setGradeAdmin = adminOps.setGradeAdmin;

const assignments = require("./src/assignments");
exports.assignMakhdoms = assignments.assignMakhdoms;

const visits = require("./src/visits");
exports.recordVisit = visits.recordVisit;
exports.updateVisitNotes = visits.updateVisitNotes;

const attendance = require("./src/attendance");
exports.initializeAttendance = attendance.initializeAttendance;
exports.finalizeAttendance = attendance.finalizeAttendance;
exports.reopenAttendance = attendance.reopenAttendance;

const imports = require("./src/imports");
exports.importRows = imports.importRows;

const accountDeletion = require("./src/account_deletion");
exports.requestAccountDeletion = accountDeletion.requestAccountDeletion;

const notifications = require("./src/notifications");
exports.sendPushOnOutboxCreated = notifications.sendPushOnOutboxCreated;

const tasks = require("./src/tasks");
exports.createTask = tasks.createTask;

exports.archiveMakhdom = assignments.archiveMakhdom;
exports.saveMakhdomProfile = assignments.saveMakhdomProfile;
exports.setAttendancePresence = attendance.setAttendancePresence;
exports.getAttendanceRoster = attendance.getAttendanceRoster;

exports.retryNotificationOutbox = notifications.retryNotificationOutbox;
exports.retryAccountDeletions = accountDeletion.retryAccountDeletions;

exports.deleteTask = tasks.deleteTask;
exports.sendChildAlert = tasks.sendChildAlert;
