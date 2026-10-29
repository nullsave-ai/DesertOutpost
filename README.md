# Desert Outpost — Godot 4.7.2 (Android)

لعبة تصويب من منظور الشخص الثالث: خريطة الصحراء، 3 شخصيات، سلاحان (AR-9 مع 5 بصريات، قناص LR-7 بسكوب PIP)، موجات أعداء بذكاء ملاحة.

## البناء على الأندرويد (GitHub Actions)
1. فك ضغط كل ملفات zip في نفس المجلد (تندمج المجلدات).
2. ارفع المجلد كاملاً إلى مستودع GitHub (فرع main). يوجد `.github/workflows/build-android.yml`.
3. تبويب Actions ← Build Android APK ← بعد النجاح حمّل `DesertOutpost-apk` من Artifacts وثبّته.

## التحكم باللمس
عصا يسار = حركة (دفعها للأقصى = ركض) | السحب في أي مكان بالنصف الأيمن = نظر | FIRE (ويمكن السحب عليه للنظر أثناء النار) | AIM = تصويب/سكوب | RLD تعبئة | SWAP تبديل السلاح | SIGHT تبديل البصرية/التكبير | JUMP.
كيبورد (للتجربة): WASD، ماوس، كليك يمين تصويب، R، Q، E، Space، Shift، P.

## إعادة خبز الملاحة / السلاح
`godot --headless --path . -s tools/bake_nav.gd` ، `godot --headless --path . -s weapons/build_weapons.gd -- out=res://art/Weapons`
