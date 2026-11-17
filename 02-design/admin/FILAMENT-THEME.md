# Filament admin: design notes for implementation

Mockups: `02-design/admin/index.html` (five screens, light and dark). Build with the `filament-pro` skill; confirm exact
Filament APIs with `context7-cli` before coding (the colors array format changed between versions).

## Fonts (license)
The admin is a website, so the **thmanyah font must not be used here** (its license forbids web hosting).
Use **IBM Plex Sans Arabic** (OFL, free to serve): `->font('IBM Plex Sans Arabic')` on the panel, loaded from the
default font provider. Set the app locale to `ar` so Filament switches to RTL.

## Panel provider (sketch, not final code)
```php
return $panel
    ->id('admin')->path('admin')->login()
    ->brandName('رعايتي')->brandLogo(asset('images/riayati-symbol.svg'))
    ->font('IBM Plex Sans Arabic')
    ->colors([
        // primary = logo olive. Prefer Color::hex('#406a05') and let Filament build the shades;
        // if you need exact shades, the generated ramp (OKLCH, from the logo) is below.
        'primary' => Color::hex('#406a05'),
        'danger'  => Color::hex('#dc2626'),
        'success' => Color::hex('#16a34a'),
        'warning' => Color::hex('#d97706'),
        'info'    => Color::hex('#2563eb'),
    ])
    ->sidebarCollapsibleOnDesktop(false);
```

Brand ramp (`primitive.brand` in `01-brand/tokens/colors.json`):
```
            50 => '#effce5',
            100 => '#def6cc',
            200 => '#c5eaa9',
            300 => '#aad883',
            400 => '#8ec061',
            500 => '#73a345',
            600 => '#578625',
            700 => '#406a05',
            800 => '#2f5200',
            900 => '#203a01',
            950 => '#102100',
```
Lime accent ramp (use sparingly, dark mode primary): 300 = `#b9d476`, 200 = `#d1e7a0`.

## Resources
| Resource | Table columns | Filters | Actions |
|---|---|---|---|
| `IncidentReportResource` | reference (mono), reporter name + role, incident date, attachment count, status badge | status, role, date range | View; mark as reviewed (bulk too) |
| `LegalDocumentResource` | title, type badge, reference, updated at, index status badge | type (tabs), index status | Edit, Delete (confirmation modal), Retry indexing |

- **Status badges:** report status `under_review` (info) / `reviewed` (success). Index status `indexed` (success), `indexing` (info), `failed` (danger).
- **Stats widget** on the inbox: under review, reviewed, received this week.
- **Report view page:** description, attachments as tiles opened through **short-lived signed URLs** (private storage), reporter card, status timeline, "Download PDF" action.
- **Legal text form:** title, type (family law / Supreme Court), reference, full text, `is_active` toggle. Saving dispatches the re-index job (cron-driven queue on Hostinger: `queue:work --stop-when-empty` every minute). Show chunk count and last indexed time in a sidebar section.
- **Delete:** destructive confirmation modal, then remove the embeddings for that document.
- **Navigation:** two items only (reports with a count badge, legal texts).

## Authorization
- Only the `admin` role may open `/admin` (`canAccessPanel`). Parents never see this panel.
- Admin can read every report and attachment; nobody can delete a submitted report from the panel UI (evidence rule from the product decisions).

## Not in scope here
Parent account management, report deletion, internal admin notes, analytics. Add only if the client asks, with a written change request (quote section 10).
