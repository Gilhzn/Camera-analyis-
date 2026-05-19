export type CarPart = {
  id: string
  name: string
  hebrewName: string
  category: string
  description: string
  price: string
  warranty: string
  /** Section index where this part is highlighted */
  section: number
  /** Final exploded position offset relative to the car body */
  explode: [number, number, number]
}

export const CAR_PARTS: CarPart[] = [
  {
    id: "engine",
    name: "Engine Block",
    hebrewName: "מנוע",
    category: "הינע",
    description:
      "מנוע 4 צילינדרים בעל הספק של 180 כ\"ס, עם מערכת הזרקה ישירה וקירור משופר. כולל אחריות יצרן מלאה.",
    price: "₪18,400",
    warranty: "3 שנים / 100,000 ק\"מ",
    section: 1,
    explode: [0, 4.5, 0.5],
  },
  {
    id: "wheel-fl",
    name: "Front Left Wheel",
    hebrewName: "גלגל קדמי שמאל",
    category: "הינע",
    description:
      "חישוק סגסוגת קלה 18\" עם צמיג רך-ספורטיבי. שיפור באחיזה ובצריכת דלק עד 6%.",
    price: "₪2,150",
    warranty: "2 שנים",
    section: 2,
    explode: [3.5, -1.8, 2.0],
  },
  {
    id: "wheel-fr",
    name: "Front Right Wheel",
    hebrewName: "גלגל קדמי ימין",
    category: "הינע",
    description:
      "חישוק זהה לזה שמשמאל. נמכר זוגית כדי לשמור על איזון מערך ההיגוי.",
    price: "₪2,150",
    warranty: "2 שנים",
    section: 2,
    explode: [-3.5, -1.8, 2.0],
  },
  {
    id: "wheel-rl",
    name: "Rear Left Wheel",
    hebrewName: "גלגל אחורי שמאל",
    category: "הינע",
    description: "חישוק אחורי תואם, מאוזן מפעלית למהירויות עד 240 קמ\"ש.",
    price: "₪2,150",
    warranty: "2 שנים",
    section: 2,
    explode: [3.5, -1.8, -2.0],
  },
  {
    id: "wheel-rr",
    name: "Rear Right Wheel",
    hebrewName: "גלגל אחורי ימין",
    category: "הינע",
    description: "חישוק אחורי תואם, מאוזן מפעלית למהירויות עד 240 קמ\"ש.",
    price: "₪2,150",
    warranty: "2 שנים",
    section: 2,
    explode: [-3.5, -1.8, -2.0],
  },
  {
    id: "hood",
    name: "Hood",
    hebrewName: "מכסה מנוע",
    category: "מרכב",
    description:
      "מכסה מנוע מאלומיניום מחוזק, קל ב-32% מהמקור. כולל מנגנון בלימת רוח.",
    price: "₪3,600",
    warranty: "5 שנים נגד חלודה",
    section: 3,
    explode: [0, 3.0, 2.5],
  },
  {
    id: "door-l",
    name: "Left Door",
    hebrewName: "דלת שמאל",
    category: "מרכב",
    description:
      "דלת מקורית עם מערכת חיזוק צד נגד התנגשות. כוללת חיווט חשמלי לחלון ולמראה.",
    price: "₪4,250",
    warranty: "3 שנים",
    section: 3,
    explode: [3.5, 0.4, 0],
  },
  {
    id: "door-r",
    name: "Right Door",
    hebrewName: "דלת ימין",
    category: "מרכב",
    description:
      "דלת מקורית עם מערכת חיזוק צד נגד התנגשות. כוללת חיווט חשמלי לחלון ולמראה.",
    price: "₪4,250",
    warranty: "3 שנים",
    section: 3,
    explode: [-3.5, 0.4, 0],
  },
  {
    id: "roof",
    name: "Roof Panel",
    hebrewName: "גג",
    category: "מרכב",
    description: "פאנל גג מקורי. ניתן גם כגג פנורמי בתוספת תשלום.",
    price: "₪5,800",
    warranty: "5 שנים נגד חלודה",
    section: 3,
    explode: [0, 3.6, -1.0],
  },
  {
    id: "headlight-l",
    name: "Headlight Left",
    hebrewName: "פנס קדמי שמאל",
    category: "תאורה",
    description:
      "פנס LED מתכוונן עם פונקציית סיבוב אקטיבי בהתאם להגה. צריכת חשמל מופחתת.",
    price: "₪1,980",
    warranty: "4 שנים",
    section: 4,
    explode: [2.0, 1.0, 4.5],
  },
  {
    id: "headlight-r",
    name: "Headlight Right",
    hebrewName: "פנס קדמי ימין",
    category: "תאורה",
    description:
      "פנס LED מתכוונן עם פונקציית סיבוב אקטיבי בהתאם להגה. צריכת חשמל מופחתת.",
    price: "₪1,980",
    warranty: "4 שנים",
    section: 4,
    explode: [-2.0, 1.0, 4.5],
  },
  {
    id: "mirror-l",
    name: "Mirror Left",
    hebrewName: "מראה צד שמאל",
    category: "תאורה",
    description: "מראה צד עם חימום אוטומטי, איתות משולב וקיפול חשמלי.",
    price: "₪690",
    warranty: "2 שנים",
    section: 4,
    explode: [3.6, 2.0, 1.4],
  },
  {
    id: "mirror-r",
    name: "Mirror Right",
    hebrewName: "מראה צד ימין",
    category: "תאורה",
    description: "מראה צד עם חימום אוטומטי, איתות משולב וקיפול חשמלי.",
    price: "₪690",
    warranty: "2 שנים",
    section: 4,
    explode: [-3.6, 2.0, 1.4],
  },
  {
    id: "exhaust",
    name: "Exhaust",
    hebrewName: "מערכת פליטה",
    category: "הינע",
    description:
      "מערכת פליטה מנירוסטה כפולה, מפחיתה לחץ-חוזר ומעלה את ההספק ב-4%.",
    price: "₪2,750",
    warranty: "3 שנים",
    section: 1,
    explode: [-0.8, -1.0, -5.0],
  },
  {
    id: "battery",
    name: "Battery",
    hebrewName: "מצבר",
    category: "חשמל",
    description:
      "מצבר AGM 80Ah, מתאים למערכות start-stop ולעומסי חשמל גבוהים.",
    price: "₪890",
    warranty: "שנתיים מלאות",
    section: 1,
    explode: [2.4, 2.6, 2.4],
  },
]

export const SECTIONS = [
  {
    id: "intro",
    title: "כל חלק. במקום הנכון.",
    subtitle:
      "חוויית גלילה תלת-מימדית לחלקי חילוף מקוריים. גלול למטה והרכב יתפרק לפניך — חלק אחר חלק.",
    tag: "AutoParts3D",
  },
  {
    id: "drivetrain",
    title: "הינע ומסירת כוח",
    subtitle:
      "מנוע, פליטה ומצבר — הליבה של הרכב. כל החלקים מקוריים, נבדקו במפעל ומגיעים עם אחריות יצרן.",
    tag: "01 · הינע",
  },
  {
    id: "wheels",
    title: "גלגלים ובלמים",
    subtitle:
      "ערכת גלגלים מאוזנת ארבעת-הפינות. חישוקים בסגסוגת קלה, צמיגים ספורטיביים ובלמים בקליפר אדום.",
    tag: "02 · גלגלים",
  },
  {
    id: "body",
    title: "מרכב — דלתות, גג, מכסה מנוע",
    subtitle:
      "פאנלים מקוריים, צבועים בגוון המפעל. חיזוקי בטיחות מובנים נגד התנגשויות צד וקדמיות.",
    tag: "03 · מרכב",
  },
  {
    id: "lights",
    title: "תאורה ומראות",
    subtitle:
      "פנסי LED עם סיבוב אקטיבי ומראות צד עם חימום ואיתות. שיפור משמעותי לראות הלילה.",
    tag: "04 · תאורה",
  },
  {
    id: "cta",
    title: "בנה את הרכב שלך",
    subtitle:
      "סמן את החלקים שאתה צריך, ואנחנו נשלח עד הבית — תוך 48 שעות, עם התקנה במוסך מורשה.",
    tag: "סיכום",
  },
]
