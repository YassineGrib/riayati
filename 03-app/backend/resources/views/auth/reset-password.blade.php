<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>تعيين كلمة مرور جديدة · رعايتي</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;700&display=swap">
<style>
  :root { --ink:#2f332d; --muted:#5a5e57; --bg:#f4f9f0; --card:#fff; --primary:#406a05; --border:#737770; --err:#991b1b; --errbg:#fef2f2; }
  * { box-sizing: border-box; }
  body { margin:0; min-height:100vh; display:grid; place-items:center; padding:24px; background:var(--bg); color:var(--ink); font-family:"IBM Plex Sans Arabic",system-ui,sans-serif; line-height:1.65; }
  main { width:100%; max-width:420px; background:var(--card); border-radius:16px; padding:32px 24px; border:1px solid #d9ded6; }
  h1 { margin:0 0 8px; font-size:24px; line-height:1.4; }
  p { margin:0 0 24px; color:var(--muted); }
  label { display:block; margin-bottom:6px; font-weight:500; font-size:14px; }
  input { width:100%; height:52px; padding:0 16px; border:1px solid var(--border); border-radius:12px; font:inherit; direction:ltr; text-align:right; }
  input:focus { outline:2px solid var(--primary); outline-offset:2px; }
  .field { margin-bottom:16px; }
  button { width:100%; height:52px; border:0; border-radius:12px; background:var(--primary); color:#fff; font:inherit; font-weight:700; cursor:pointer; }
  button:hover { background:#355a04; }
  .err { margin-bottom:16px; padding:12px 16px; border-radius:12px; background:var(--errbg); color:var(--err); font-size:14px; border:1px solid #fca5a5; }
</style>
</head>
<body>
<main>
  <h1>تعيين كلمة مرور جديدة</h1>
  <p>اختر كلمة مرور من 8 أحرف على الأقل.</p>
  @if ($errors->any())
    <div class="err" role="alert">{{ $errors->first() }}</div>
  @endif
  <form method="POST" action="{{ route('password.reset.submit') }}">
    @csrf
    <input type="hidden" name="token" value="{{ $token }}">
    <input type="hidden" name="email" value="{{ $email }}">
    <div class="field"><label for="password">كلمة المرور الجديدة</label><input id="password" name="password" type="password" autocomplete="new-password" required minlength="8"></div>
    <div class="field"><label for="password_confirmation">تأكيد كلمة المرور</label><input id="password_confirmation" name="password_confirmation" type="password" autocomplete="new-password" required minlength="8"></div>
    <button type="submit">حفظ كلمة المرور</button>
  </form>
</main>
</body>
</html>
