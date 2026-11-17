<?php

// Arabic validation messages for the fields the app sends. The mobile app can also map errors by field name.
return [
    'required' => 'هذا الحقل مطلوب.',
    'string' => 'قيمة غير صالحة.',
    'email' => 'أدخل بريدًا إلكترونيًا صحيحًا.',
    'unique' => 'هذا البريد مسجّل بالفعل.',
    'min' => ['string' => 'يجب ألا يقل عن :min أحرف.', 'numeric' => 'يجب ألا تقل القيمة عن :min.'],
    'max' => ['string' => 'يجب ألا يزيد عن :max حرفًا.', 'numeric' => 'يجب ألا تزيد القيمة عن :max.'],
    'integer' => 'أدخل عددًا صحيحًا.',
    'regex' => 'صيغة غير صالحة.',
    'custom' => [
        'phone' => ['regex' => 'أدخل رقم هاتف جزائري صحيحًا يبدأ بـ 0 أو +213 ويتبعه 9 أرقام.'],
    ],
    'confirmed' => 'تأكيد كلمة المرور غير مطابق.',
    'current_password' => 'كلمة المرور الحالية غير صحيحة.',
    'accepted' => 'يجب الموافقة على الشروط وسياسة الخصوصية.',
    'in' => 'قيمة غير صالحة.',
    'attributes' => [
        'name' => 'الاسم',
        'email' => 'البريد الإلكتروني',
        'password' => 'كلمة المرور',
        'current_password' => 'كلمة المرور الحالية',
        'password_confirmation' => 'تأكيد كلمة المرور',
        'role' => 'الدور',
        'terms' => 'الشروط',
        'code' => 'الرمز',
        'phone' => 'رقم الهاتف',
        'wilaya' => 'الولاية',
        'children_count' => 'عدد الأطفال',
    ],
];
