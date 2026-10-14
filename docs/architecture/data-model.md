# نموذج البيانات الأولي وERD

> هذا ERD تصور كامل مرحلي للمنتج. المخطط المنفذ الآن يغطي ملفات الأطفال وجلسات التعلم فقط؛ راجع EF migration في `backend/src/QuranHero.Infrastructure/Persistence/Migrations/` للتفاصيل الحالية. تستخدم ملفات الأطفال فئة عمرية عامة ولا تخزن تاريخ ميلاد دقيقًا.

```mermaid
erDiagram
  PARENT ||--o{ CHILD_PROFILE : owns
  CHILD_PROFILE ||--o{ STUDY_SESSION : has
  STUDY_SESSION ||--o{ SESSION_AYAH : covers
  QURAN_SURAH ||--|{ QURAN_AYAH : contains
  QURAN_AYAH ||--o{ SESSION_AYAH : references
  CHILD_PROFILE ||--o{ LEARNING_GOAL : follows
  CHILD_PROFILE ||--o{ REWARD : earns
  LEARNING_GOAL ||--o{ REWARD : unlocks
  CHILD_PROFILE ||--o{ ACHIEVEMENT : earns
  CHILD_PROFILE ||--o{ SYNC_EVENT : submits
  PARENT ||--o{ NOTIFICATION_PREFERENCE : configures

  PARENT {
    uuid id PK
    string firebase_uid UK
    string email
    string preferred_language
    datetime created_at
    datetime deleted_at
  }
  CHILD_PROFILE {
    uuid id PK
    uuid parent_id FK
    string display_name
    string age_band
    string level_code
    string interests_json
    datetime created_at
    datetime archived_at
  }
  QURAN_SURAH {
    int surah_number PK
    string name_ar
    string name_en
    int ayah_count
    string content_version
  }
  QURAN_AYAH {
    int surah_number PK,FK
    int ayah_number PK
    string text_uthmani
    string content_checksum
  }
  STUDY_SESSION {
    uuid id PK
    uuid child_id FK
    string kind
    datetime started_at
    datetime ended_at
    int duration_seconds
    string client_event_id UK
  }
  SESSION_AYAH {
    uuid session_id PK,FK
    int surah_number PK,FK
    int ayah_number PK,FK
    int repetitions
    string outcome
  }
  LEARNING_GOAL {
    uuid id PK
    uuid child_id FK
    string goal_type
    string target_json
    date start_date
    date end_date
    string status
  }
  REWARD {
    uuid id PK
    uuid child_id FK
    uuid goal_id FK
    string title
    string status
    datetime unlocked_at
  }
  ACHIEVEMENT {
    uuid id PK
    uuid child_id FK
    string achievement_code
    datetime earned_at
  }
  SYNC_EVENT {
    uuid id PK
    uuid child_id FK
    string client_event_id UK
    datetime occurred_at
    datetime received_at
    string event_type
  }
  NOTIFICATION_PREFERENCE {
    uuid id PK
    uuid parent_id FK
    string channel
    string category
    boolean enabled
  }
```

## قواعد وقيود أساسية

- `PARENT.firebase_uid` فريد، ويُربط بحساب المصادقة بعد تحقق الخادم من الرمز.
- جميع كيانات الطفل تحمل `child_id` أو `parent_id` لازمًا لمسار التفويض؛ الاستعلامات تقيد دائمًا بهوية الأب/الأم المستخرجة من token.
- `QURAN_AYAH` مفتاح مركب `(surah_number, ayah_number)`، مع تحقق من مدى الأرقام ومطابقة إصدار المصدر.
- `client_event_id` فريد لمنع مضاعفة جلسة/نقاط عند إعادة المزامنة.
- التواريخ تخزن UTC، وتُحسب أهداف اليوم والسلسلة وفق المنطقة الزمنية المسجلة لولي الأمر.
- حالات المكافأة المقترحة: `locked`, `unlocked`, `claimed`, `cancelled`؛ انتقالاتها يقررها الخادم.
- الحذف يراعي فصل حذف الحساب عن البيانات اللازمة للسجل القانوني أو المحاسبي إن وجدت؛ تفاصيل الاحتفاظ تتطلب قرارًا قانونيًا حسب السوق.

## فهارس مرشحة

- فريد على `Parent(firebase_uid)`.
- `(ChildProfile.parent_id, ChildProfile.archived_at)` لتعداد الأبناء النشطين.
- `(StudySession.child_id, StudySession.started_at DESC)` لتقارير النشاط.
- فريد على `(SyncEvent.child_id, SyncEvent.client_event_id)`.
- `(LearningGoal.child_id, LearningGoal.status, LearningGoal.end_date)`.
- `(Achievement.child_id, Achievement.earned_at DESC)`.

لا تُنشأ جداول للأصدقاء أو التسجيلات الصوتية أو محتوى مولد آليًا في MVP.
