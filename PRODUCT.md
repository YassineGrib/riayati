# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack
Flutter mobile app (Android first, iOS only if free), Laravel + Sanctum backend, Filament admin, SQLite, Hostinger shared hosting. Screens are first designed as HTML mockups from the DTCG tokens in `01-brand/tokens/`, then rebuilt in FigCraft, then implemented in Flutter.

## Users
Divorced or separated parents in Algeria (a father and a mother, each with their own account) who share custody of a child and have to deal with family-court rules. They use the app on a phone, often while stressed, in conflict with the other parent, and sometimes in an emergency. Secondary user: an admin (the client's team) who receives incident reports and maintains the legal texts. Admin uses a Filament web panel, not this mobile UI.

## Product Purpose
Riayati (رعايتي) is a digital platform for protecting children within custody arrangements. It lets a parent (1) get AI-assisted answers grounded in Algerian Family Code texts and Supreme Court rulings, (2) report and document child-protection incidents with text, photos and video and export a structured PDF report, and (3) coordinate visits with the other parent on a shared calendar (propose, accept, decline, confirm). Success: a parent can record an incident or agree a visit in a few taps without confusion, and trusts that their data stays private.

## Positioning
A neutral, structured record-keeping and legal-information tool for custody situations, grounded only in provided Algerian legal sources, with role-based privacy between the two parents. Not a messaging app, not legal advice, not a court filing system.

## Operating Context
Arabic only, right-to-left. Phone, Android first. Sessions are short and emotionally loaded. Data is sensitive (children, family disputes, evidence). Accounts: father, mother, admin. Parents see only their own data plus the shared calendar. Two parent accounts are linked by an invite code: each registers alone, one generates a short code or link, the other enters it after signing up; nothing is shared until the link is accepted. Login is email and password only. There is no OTP. Password reset is by an emailed link.

## Capabilities and Constraints
- Auth: email + password (Laravel Sanctum). No OTP, no social login. Register collects name, email, password and role (father or mother). Forgot password sends a reset link by email. Consent to terms and privacy is shown at registration.
- Evidence uploads: private storage, signed URLs, about 30 MB per file, 5 files per report, video compressed on the phone, parents cannot delete a submitted report.
- Chatbot: Gemini via Google AI Studio, answers only from retrieved legal sources and cites articles, says so when sources are insufficient. Users are told not to type names or case details into the chat.
- Legal corpus not yet delivered by the client; placeholder public articles until then.
- Arabic RTL only for the MVP. Font: thmanyah family (Sans, Serif Display, Serif Text) for the app; its license forbids redistributing or web-hosting the files, so web surfaces use IBM Plex Sans Arabic instead.
- Undecided: email verification (not in this batch), exact legal copy for terms and privacy.

## Brand Commitments
Name: رعايتي (Riayati). Logo symbol in `01-brand/logo/` (olive `#658E3F`, lime `#C5E76C`). Palette derived from the logo in `01-brand/tokens/colors.json` (olive primary, lime accent, SOS red `#DC2626` family fixed for emergencies). Tokens in `01-brand/tokens/` are the single source of truth; no hardcoded colors, sizes or timings in screens.

## Evidence on Hand
Logo SVG/PNG, token files, the signed quote RIA-MVP-001 in `00-admin/`. No testimonials, user counts, legal approval, or certification exist and none may be invented. Legal text content is not delivered yet.

## Product Principles
1. Calm over clever: the user is stressed, so every screen has one clear next action.
2. Privacy is visible: say plainly what is private and who can see what.
3. Neutral toward both parents: never take a side, never use accusatory wording.
4. Emergency path stays one tap away and visually distinct (SOS red is reserved for it).
5. Grounded, not guessing: the product only states what its legal sources support.

## Accessibility & Inclusion
WCAG 2.2 AA on tokens (checked). Arabic RTL with generous line height. Large touch targets for use under stress. Never use color as the only signal. Low-literacy-friendly short sentences.
