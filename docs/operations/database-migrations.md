# تشغيل ترحيلات قاعدة البيانات

## السياسة

- تستخدم Development وTesting قاعدة SQLite؛ ينشئ التطبيق مخططًا محليًا للاختبار عبر `EnsureCreated`.
- تستخدم البيئات الأخرى SQL Server/Azure SQL فقط. لا ينفّذ التطبيق `Migrate()` أو يغيّر المخطط تلقائيًا عند بدء Production أو Staging.
- قبل تشغيل إصدار يحتاج مخططًا جديدًا، ولّد سكربت SQL قابلًا لإعادة التشغيل، راجعه، وطبّقه كخطوة نشر مستقلة ومصرّح بها. لا تشغّل تطبيق API قبل توفر المخطط المطلوب.
- يتطلب بدء كل بيئة غير Development/Testing الإعدادين `Firebase:ProjectId` و`ConnectionStrings:QuranHero`. يفشل التطبيق برسالة تسمي المفاتيح الناقصة فقط، دون طباعة قيمها.

## توليد سكربت للمراجعة

نفّذ الأوامر من جذر المستودع بعد تثبيت .NET 8 و`dotnet-ef` 8.0:

```bash
dotnet ef migrations list \
  --project backend/src/QuranHero.Infrastructure/QuranHero.Infrastructure.csproj \
  --startup-project backend/src/QuranHero.Api/QuranHero.Api.csproj \
  --context QuranHeroDbContext

mkdir -p artifacts
dotnet ef migrations script --idempotent \
  --project backend/src/QuranHero.Infrastructure/QuranHero.Infrastructure.csproj \
  --startup-project backend/src/QuranHero.Api/QuranHero.Api.csproj \
  --context QuranHeroDbContext \
  --output artifacts/quran-hero-migrations.sql
```

الأداة تستخدم `QuranHeroDesignTimeFactory` لتكوين مزود SQL Server. **توليد السكربت لا يتصل بقاعدة بيانات ولا يطبقه**؛ لا تستخدم `dotnet ef database update` على بيئة مشتركة أو إنتاجية كبديل عن إجراء النشر.

## مراجعة وتطبيق

1. راجع السكربت والمهاجرات المقابلة للتغييرات التعاقدية، قيود الفهارس، وأثرها على البيانات الحالية وزمن الأقفال. السكربت idempotent لكنه ليس ضمانًا لخلو التغيير من المخاطر التشغيلية.
2. طبّقه أولًا على بيئة SQL Server/Azure SQL اختبارية متوافقة، باستخدام حساب نشر محدود الصلاحيات ومن خلال مسار نشر معتمد يحفظ بيانات الاتصال في مخزن الأسرار. لا تضع سلسلة اتصال حقيقية أو ملفًا مولدًا يحوي بيانات بيئة في Git.
3. تحقق من سجل `__EFMigrationsHistory`، واختبر مسارات API وقراءة/كتابة البيانات في البيئة الاختبارية. جهّز نسخة احتياطية وخطة استعادة قبل تغيير الإنتاج.
4. انشر السكربت كمهمة قاعدة بيانات منفصلة ومراجعة قبل نشر نسخ API التي تعتمد على المخطط الجديد. لا تجعل كل نسخة API تنفذ migrations بالتوازي عند الإقلاع.
5. بعد موافقة مسؤول البيئة وتطبيق السكربت، انشر التطبيق وتحقق من `/health` ثم اختبارات smoke آمنة. خطة التراجع يجب أن تعالج البيانات المتأثرة؛ لا تنفذ `Down` تلقائيًا أو دون تقييم.

لا تتضمن هذه الوثيقة اتصالًا بقاعدة Azure فعلية أو موافقة على إنشاء موارد مدفوعة أو نشر تطبيق. يلزم اعتماد مسؤول البيئة وأسراره قبل تطبيق أي سكربت على نظام مشترك أو إنتاجي.
