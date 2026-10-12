const templates = {
  ar: {
    child_absence_alert: () => ({
      title: "تنبيه متابعة",
      body: "افتح تطبيق افتقاد لمتابعة أحد مخدوميك.",
    }),
    task_assigned: (args) => ({
      title: `مهمة جديدة: ${args.title || ""} 📋`,
      body: `قام ${args.createdByName || "المسؤول"} بتكليفك بمهمة جديدة`,
    }),
    attendance_khedma: () => ({
      title: "حضور الخدمة 📋",
      body: "تم تكليفك برصد حضور وغياب الخدمة",
    }),
    attendance_qoddas: () => ({
      title: "حضور القداس ⛪",
      body: "تم تكليفك برصد حضور وغياب القداس الإلهي",
    }),
    absence_alert: (args) => ({
      title: `إنذار غياب: ${args.makhdomName || ""} 🚨`,
      body: `غائب منذ ${args.weeks || 2} أسابيع متتالية ومطلوب افتقاده`,
    }),
  },
  en: {
    child_absence_alert: () => ({
      title: "Follow-up alert",
      body: "Open Efteqad to follow up with an assigned student.",
    }),
    task_assigned: (args) => ({
      title: `New Task: ${args.title || ""} 📋`,
      body: `${args.createdByName || "Admin"} assigned you a new task`,
    }),
    attendance_khedma: () => ({
      title: "Service Attendance 📋",
      body: "You are assigned to take Service attendance",
    }),
    attendance_qoddas: () => ({
      title: "Mass Attendance ⛪",
      body: "You are assigned to take Mass attendance",
    }),
    absence_alert: (args) => ({
      title: `Absence Alert: ${args.makhdomName || ""} 🚨`,
      body: `Absent for ${args.weeks || 2} consecutive weeks, visit needed`,
    }),
  },
};

/**
 * Render notification title and body based on template key, arguments, and recipient locale.
 */
function renderNotificationTemplate(templateKey, args = {}, locale = "ar") {
  const lang = locale.startsWith("en") ? "en" : "ar";
  const langTemplates = templates[lang] || templates.ar;
  const renderer = langTemplates[templateKey];

  if (!renderer) {
    return {
      title:
        args.fallbackTitle ||
        (lang === "ar" ? "تنبيه جديد 🔔" : "New Notification 🔔"),
      body: args.fallbackBody || "",
    };
  }

  return renderer(args);
}

module.exports = {
  templates,
  renderNotificationTemplate,
};
