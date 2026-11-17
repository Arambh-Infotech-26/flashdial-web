# FlashDial Web --- Project Context

> **Purpose:** This document defines the product scope, architecture,
> behavior, and engineering constraints for the FlashDial Web
> application. Keep it in the root of the web repository as
> `PROJECT_CONTEXT.md`.
>
> **Scope:** FlashDial Web only. The Android app is called **FlashDial
> Mobile** and is responsible for executing cellular call actions
> through Android Telecom. Both applications share the same Firebase
> project and data contracts.

------------------------------------------------------------------------

## 1. Product Overview

**Product name:** FlashDial Web\
**Product family:** FlashDial\
**Brand:** Aarambh Technologies\
**Product type:** Remote calling dashboard and call-control interface

**Description:**

FlashDial Web is a smart calling interface that lets an authorized user
initiate calls through their registered Android device, monitor incoming
and ongoing calls, and control supported call actions from a computer.
It uses Firebase Realtime Database to exchange call commands and state
with FlashDial Mobile.

The web application does not make cellular calls itself. It observes and
updates authorized Firebase data; FlashDial Mobile validates commands
and performs the actual SIM-based call operations.

### Product principles

1.  **Mobile executes; web controls.** FlashDial Mobile is the authority
    for actual telephony actions and call state.
2.  **Firebase coordinates.** Realtime Database carries authorized
    commands and call/device state between the applications.
3.  **No public web registration.** Only approved users can sign in.
4.  **Fast keyboard-first workflow.** Common call actions should be
    accessible through clearly documented keyboard shortcuts.
5.  **Contextual number detection.** Where supported, the user should be
    able to select or detect a phone number on screen and initiate a
    call through their registered mobile.
6.  **Never imply success prematurely.** A web command being written to
    Firebase does not mean the phone has executed it.

------------------------------------------------------------------------

## 2. Authentication and Access Policy

### Shared Firebase Authentication

FlashDial Mobile and FlashDial Web use the **same Firebase project and
Firebase Authentication accounts**. A user should not need separate
credentials for each application.

### Registration

-   FlashDial Web has **Sign In** and **Forgot Password** only.
-   Do not expose public Sign Up / Create Account on the web.
-   Accounts are invited, provisioned, or approved by Aarambh
    Technologies.
-   Apply the same approved-user policy to mobile onboarding.
    Restricting web registration alone is not sufficient if the APK can
    be shared.

### Authorization after sign-in

After Firebase Authentication succeeds, verify: - The user profile
exists. - Account status is `active`. - The user's role is permitted. -
The user has an authorized registered Android device.

Suggested account states: `invited`, `active`, `suspended`, `disabled`.

Suggested roles: `user`, `admin`.

Roles, account status, and device ownership must be controlled by
trusted backend/admin operations. A normal user must not be able to
activate their account, grant themselves admin privileges, or register
another user's device.

------------------------------------------------------------------------

## 3. Core Features

### 3.1 Remote dialer

-   Provide a dial pad and phone-number input.
-   Allow the user to enter a number manually or select a detected
    number.
-   Submit a uniquely identified `place_call` command for the user's
    registered Android device.
-   Show command delivery/acknowledgement status.
-   Show actual call progress only when reported by FlashDial Mobile.

### 3.2 Incoming call observation and controls

-   Observe incoming-call state published by FlashDial Mobile to
    Firebase.
-   Display caller number and contact details when available and
    authorized.
-   Provide **Answer** and **Decline** actions when the mobile app and
    Android platform support them.
-   Send the requested action through Firebase.
-   Update the UI from the resulting native call state reported by
    mobile.

### 3.3 Ongoing call controls

Provide controls for supported actions, such as: - End call - Mute /
unmute - Volume up / down - Answer / decline for incoming calls -
Optional hold / unhold, if implemented and supported

The web app sends control commands. FlashDial Mobile is responsible for
validating and executing them. Volume control should affect the relevant
mobile call audio level only if the Android implementation explicitly
supports it. Browser keyboard events cannot directly control Android
device volume.

### 3.4 Device status

Display: - Device online/offline state - Last-seen timestamp - Current
call state - Pending command state - Error or unavailable state

Do not treat an old database value as live state. Use
timestamps/heartbeats and visibly mark stale device data.

------------------------------------------------------------------------

## 4. Contextual Phone Number Detection and Call Overlay

The product goal is to help a user call a phone number they see on their
computer without manually copying and pasting it.

### Intended experience

1.  User sees a phone number on screen.
2.  FlashDial identifies a possible 10-digit phone number in a supported
    context.
3.  A small FlashDial call action appears near the number or in a
    contextual UI.
4.  User clicks the call icon.
5.  Web app normalizes and displays the detected number for confirmation
    where appropriate.
6.  Web sends a call command to the registered Android device.
7.  Mobile executes the call and reports the real call state.

### Important platform distinction

A normal website running in a browser **cannot continuously inspect
arbitrary content across the user's entire desktop or draw a system-wide
overlay above other applications**. Browser security boundaries prevent
this.

Therefore, number detection must be implemented according to the actual
deployment model:

#### Option A --- Browser-only web app

A standard website can detect numbers only in content it is allowed to
access, such as: - Text entered or pasted into FlashDial Web. - Text
rendered inside FlashDial Web. - Content explicitly shared or copied by
the user. - A browser page only if the user explicitly selects/copies
content or grants an appropriate browser integration.

A normal website cannot inject a floating icon into unrelated websites
or desktop applications.

#### Option B --- Browser extension (web-page integration)

A browser extension may inspect permitted webpage content on sites for
which the user has granted host permissions. It can identify candidate
phone numbers and add a contextual call action to supported pages.

Requirements: - Request the minimum host permissions possible. - Explain
what page content is inspected and why. - Avoid collecting or
transmitting page text. - Detect only candidate phone-number strings,
not general page content. - Provide enable/disable controls and site
exclusions. - Do not inject into browser-internal pages or sites where
extension access is prohibited. - Keep the extension's Firebase access
authenticated and restricted to the signed-in user.

A browser extension works within supported browser pages; it does not
provide a system-wide overlay over native desktop applications.

#### Option C --- Desktop companion application

If the requirement is to detect numbers across arbitrary desktop
applications and show a true floating overlay, a separate desktop
companion may be required.

A desktop app can potentially use OS accessibility APIs, clipboard
monitoring (with explicit consent), or screen capture/OCR (with explicit
consent and platform permissions). This is a separate capability and
should not be described as something a normal Flutter Web page can do.

Before implementing this feature, choose and document the supported
deployment model: browser-only, browser extension, or desktop companion.
Do not promise system-wide detection until the desktop approach has been
designed and validated.

### Phone-number matching

-   Treat a detected 10-digit sequence as a **candidate**, not
    automatically as a valid Indian phone number.
-   Avoid matching longer digit sequences as a 10-digit number by
    mistake.
-   Avoid duplicate call icons for the same number.
-   Normalize the number before sending it to mobile, using an agreed
    country/region rule.
-   Do not silently add a country code when the region is unknown.
-   Let the user review the number before calling when detection
    confidence is uncertain.
-   Do not send surrounding page text to Firebase.

------------------------------------------------------------------------

## 5. Keyboard Shortcuts

FlashDial Web should support a keyboard-first call-control experience.

### Proposed shortcut map

  -----------------------------------------------------------------------
  Key                     Proposed action         Context
  ----------------------- ----------------------- -----------------------
  `←` Left Arrow          Answer / pick up        Only when an incoming
                          incoming call           call is active

  `→` Right Arrow         End active call, or     Confirm behavior by
                          decline incoming call   call state

  `↑` Up Arrow            Increase call volume    During an active call,
                                                  if mobile supports it

  `↓` Down Arrow          Decrease call volume    During an active call,
                                                  if mobile supports it

  `Space`                 Toggle mute / unmute    During an active call

  `Esc`                   Close contextual        When a dismissible UI
                          overlay / dismiss       is open
                          dialog                  
  -----------------------------------------------------------------------

These are proposed defaults and must be validated with user testing
before being treated as final.

### Shortcut behavior rules

-   Do not trigger shortcuts while the user is typing in an input,
    textarea, editable region, or dial-pad field, except where the
    focused component explicitly handles that key.
-   Do not hijack arrow keys while navigating menus, lists, or
    accessible controls.
-   Prevent browser scrolling only when a shortcut is intentionally
    active in the call-control context.
-   Show a visible keyboard-shortcut help panel.
-   Provide accessible labels and visible focus states.
-   Provide an option to disable or customize shortcuts.
-   Require a clear active-call/incoming-call context before dispatching
    a command.
-   Avoid accidental call termination. Consider a confirmation or
    configurable behavior for the End/Decline shortcut.
-   Reflect the result from mobile; do not optimistically show mute,
    volume, answer, or end as successful until acknowledged/state is
    updated.

### Browser vs desktop keyboard limitations

A browser page can reliably listen for shortcuts only while it has focus
and is not blocked by the browser or operating system. A normal website
cannot guarantee global shortcuts while another application is active or
while the browser is minimized.

Global shortcuts across desktop applications require a desktop companion
or another OS-level integration. This must be treated as a separate
implementation scope.

------------------------------------------------------------------------

## 6. Call and Command Lifecycle

Keep **command status** separate from **actual call status**.

### Suggested command states

-   `queued`
-   `delivered`
-   `accepted`
-   `executing`
-   `completed`
-   `failed`
-   `expired`

### Suggested call states

-   `ringing`
-   `dialing`
-   `connecting`
-   `active`
-   `holding`
-   `disconnected`
-   `failed`

A command can fail before a call exists. A call can end after its
initiating command completed. Never combine both lifecycles into one
status field.

### UI behavior

-   Show a pending state after a command is submitted.
-   Show delivered/accepted only when mobile/backend acknowledges it.
-   Show call progress only from mobile's call-state updates.
-   Show a timeout or failure when no acknowledgement arrives within the
    agreed window.
-   Do not automatically retry call commands without deduplication and
    explicit retry rules.

------------------------------------------------------------------------

## 7. Firebase Architecture and Data Contract

Both applications use the same Firebase project. Exact database paths
and schemas must be agreed with FlashDial Mobile before implementation.

### Firebase services

-   **Firebase Authentication:** shared identity.
-   **Firebase Realtime Database:** device presence, call state, and
    command exchange.
-   **Cloud Functions / trusted backend:** account provisioning,
    authorization, and sensitive command validation where required.
-   **Firebase App Check:** may be used as an additional
    abuse-resistance layer; it does not replace authentication or
    authorization.

### Example user profile

``` json
{
  "uid": "firebase-auth-uid",
  "email": "user@example.com",
  "role": "user",
  "status": "active"
}
```

### Example device record

``` json
{
  "deviceId": "unique-device-id",
  "userId": "firebase-auth-uid",
  "platform": "android",
  "status": "online",
  "lastSeenAt": 1794900000000
}
```

### Example command

``` json
{
  "commandId": "unique-command-id",
  "deviceId": "registered-device-id",
  "userId": "firebase-auth-uid",
  "type": "place_call",
  "payload": {
    "phoneNumber": "+911234567890"
  },
  "status": "queued",
  "createdAt": 1794900000000,
  "expiresAt": 1794900030000
}
```

This is illustrative only. The final schema must be versioned and shared
by both teams.

### Suggested command types

-   `place_call`
-   `answer_call`
-   `decline_call`
-   `end_call`
-   `set_muted`
-   `set_call_volume`
-   `hold_call`
-   `unhold_call`

Only include commands that FlashDial Mobile has implemented and
validated. For volume, define whether the payload is an absolute level
or a relative step and agree on the supported range with mobile.

### Security requirements

-   Use Firebase UID as the user identity.
-   Deny database access by default.
-   Enforce device ownership in Realtime Database Security Rules and
    trusted backend code.
-   Do not trust browser-supplied `userId`, `deviceId`, role, or account
    status.
-   Do not let the browser write arbitrary call state or mark its own
    command as executed.
-   Validate command type, payload, device ownership, and expiry.
-   Use unique command IDs and deduplication to prevent repeated
    execution.
-   Ensure a user cannot read or control another user's device.
-   Keep admin operations server-authorized.
-   Never put Firebase Admin credentials in the web client.
-   Do not rely on hidden buttons or frontend route guards as the
    security boundary.

Prefer a trusted backend for sensitive command creation and
account/device operations. If a client writes commands directly to
Realtime Database, Security Rules must fully enforce ownership and
allowed payloads.

------------------------------------------------------------------------

## 8. Suggested Web Architecture

The final framework and versions should be recorded by the
implementation team. Keep features separated and make the Firebase
integration reusable.

Suggested logical modules:

-   `authentication` --- sign-in, session, authorization checks
-   `dashboard` --- device status and overview
-   `dialer` --- number input and call initiation
-   `incoming_call` --- incoming call UI and actions
-   `call_controls` --- active-call controls and keyboard shortcuts
-   `number_detection` --- candidate detection in supported content
    contexts
-   `browser_integration` --- only if a browser extension/content script
    is selected
-   `device_management` --- device identity and availability
-   `call_history` --- only if call history is approved and implemented
-   `core/firebase` --- shared Firebase access and data contracts
-   `core/theme` --- colors, typography, spacing, components

Keep keyboard shortcut handling in a dedicated service/controller rather
than scattering key handlers across widgets.

------------------------------------------------------------------------

## 9. Branding and Design System

Use the approved FlashDial logo unchanged and align with the Aarambh
Technologies identity.

The following are agreed practical UI theme tokens based on the logo's
navy, metallic white, and orange direction. They are approximate design
values, not extracted from a vector brand file.

  Token                  Hex         Usage
  ---------------------- ----------- --------------------------------------------
  **Primary**            `#07152E`   Main navy brand color, navigation, headers
  **Primary dark**       `#030B1A`   Deep backgrounds
  **Secondary**          `#FF6A00`   Orange accent and primary actions
  **Secondary bright**   `#FF9D00`   Highlights
  **Accent gold**        `#FFC247`   Occasional highlight
  **Surface**            `#101F38`   Cards and panels
  **Surface light**      `#F4F6FA`   Light surfaces
  **Text on dark**       `#F5F7FB`   Primary text on dark
  **Secondary text**     `#AAB5C5`   Supporting text on dark
  **Dark text**          `#111827`   Text on light
  **Border**             `#263750`   Borders and dividers
  **Success**            `#22A06B`   Connected/success states
  **Error**              `#E5484D`   End/reject/error states
  **Warning**            `#F5A524`   Warnings

**Primary color:** `#07152E`\
**Secondary color:** `#FF6A00`

### UI guidance

-   Build a professional, desktop-first productivity interface.
-   Make the current device and call state immediately visible.
-   Make answer and decline actions visually distinct.
-   Use orange for primary actions, green for connected/success states,
    and red for decline/end.
-   Make keyboard shortcuts discoverable and show the associated key
    hints near controls.
-   Use accessible contrast, semantic labels, and keyboard focus
    indicators.
-   Avoid accidental call actions; use confirmation or configurable
    safeguards for destructive shortcuts.
-   Show pending, acknowledged, failed, stale, and offline states
    explicitly.
-   Keep the working interface restrained even though the logo has a
    glossy 3D appearance.

------------------------------------------------------------------------

## 10. Privacy and User Consent

Number detection can expose sensitive information from webpages or
desktop content. Implement it transparently.

-   Explain what content is inspected and in which contexts.
-   Request the minimum browser/OS permissions needed.
-   Provide a clear on/off setting for number detection.
-   Provide site exclusions if a browser extension is implemented.
-   Do not collect or upload surrounding page text.
-   Do not store detected numbers unless the user explicitly initiates
    an action or an approved feature requires it.
-   Do not capture screenshots or run OCR without explicit user
    permission and a clear product need.
-   Do not capture, stream, or store call audio.
-   Avoid logging full phone numbers, authentication tokens, or
    sensitive call metadata.
-   Restrict call data to the authenticated user's authorized device.

------------------------------------------------------------------------

## 11. Error and Availability States

Handle at least:

-   Invalid credentials
-   Unapproved, suspended, or disabled account
-   No registered Android device
-   Device offline or stale
-   Firebase/backend unavailable
-   Command rejected, expired, or not acknowledged
-   Mobile app unable to perform an action
-   Call state changed on the phone
-   Unsupported call action or audio control
-   Browser extension permission unavailable (if applicable)
-   Number detection unavailable in the current context
-   Keyboard shortcut ignored because focus is in a text field or
    browser-reserved context
-   Session expiry or access revocation

Never show a successful call state solely because a command was
submitted.

------------------------------------------------------------------------

## 12. Development Milestones

### Milestone 1 --- Authentication and live device state

-   [ ] Configure shared Firebase project.
-   [ ] Implement sign-in and forgot-password.
-   [ ] No public registration.
-   [ ] Validate user profile, account status, role, and device
    ownership.
-   [ ] Display device online/offline and last-seen state.
-   [ ] Subscribe to authorized call/device state.
-   [ ] Configure and test Firebase Security Rules.

### Milestone 2 --- Remote dialer and call controls

-   [ ] Implement dial pad and number input.
-   [ ] Submit outgoing-call commands.
-   [ ] Display command acknowledgement separately from call state.
-   [ ] Display incoming-call UI.
-   [ ] Implement supported answer/decline/end commands.
-   [ ] Implement mute and volume commands only after mobile support is
    ready.
-   [ ] Handle command expiry, errors, and duplicate requests.

### Milestone 3 --- Keyboard shortcuts

-   [ ] Implement the agreed shortcut map.
-   [ ] Ignore shortcuts while typing or navigating editable controls.
-   [ ] Add shortcut help and visible key hints.
-   [ ] Add accessibility and focus behavior.
-   [ ] Test browser-reserved shortcuts and scrolling behavior.
-   [ ] Add global shortcuts only if a desktop companion is selected.

### Milestone 4 --- Number detection

-   [ ] Decide browser-only, browser extension, or desktop companion
    scope.
-   [ ] Implement candidate 10-digit number detection in the supported
    context.
-   [ ] Prevent partial/duplicate matches.
-   [ ] Normalize numbers with an agreed region rule.
-   [ ] Add contextual call action.
-   [ ] Add permission, consent, enable/disable, and exclusion controls.
-   [ ] Verify no surrounding page text is transmitted.

### Milestone 5 --- Hardening

-   [ ] Test with multiple Firebase users/devices.
-   [ ] Test cross-user access denial.
-   [ ] Test offline/stale device state and command expiry.
-   [ ] Test keyboard accessibility.
-   [ ] Test browser permissions and extension restrictions if
    applicable.
-   [ ] Review privacy and data retention.
-   [ ] Add safe diagnostics and error monitoring.

------------------------------------------------------------------------

## 13. Testing Requirements

  -----------------------------------------------------------------------
  Scenario                            Expected behavior
  ----------------------------------- -----------------------------------
  Approved user signs in              Dashboard opens after authorization

  Unapproved user signs in            Access denied; no protected data
                                      exposed

  User has no device                  Clear device setup/unavailable
                                      state

  Device offline                      Remote actions unavailable or
                                      clearly pending/blocked

  Outgoing command submitted          Pending state shown; not falsely
                                      marked as a call

  Mobile acknowledges command         Command state updates

  Mobile reports active call          Web displays active call

  Incoming call published             Web displays incoming call

  Answer/decline command              UI changes based on mobile's
                                      reported result

  Duplicate command                   Deduplicated

  Expired command                     Not executed as a fresh action

  Arrow key while typing              Text input behaves normally

  Shortcut in call context            Correct supported command is
                                      submitted

  Browser tab not focused             No promise of global shortcut
                                      behavior

  Number in supported page context    Candidate number and call action
                                      appear

  Number in unrelated desktop app     Not detected by ordinary website

  User lacks extension permission     Explain limitation; no silent
                                      failure
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 14. Engineering Rules for Future Developers

1.  FlashDial Web never performs SIM telephony directly.
2.  FlashDial Mobile owns native call execution and authoritative call
    state.
3.  Use the same Firebase Authentication project as mobile.
4.  Do not add public web registration.
5.  Enforce account and device authorization in Security Rules/backend
    code.
6.  Keep command status separate from call status.
7.  Do not show success until mobile reports the resulting state.
8.  Do not claim a standard website can inspect the whole desktop or
    create a system-wide overlay.
9.  Browser keyboard shortcuts are not global; global shortcuts require
    desktop integration.
10. Do not inspect or upload page content beyond the explicitly
    permitted number-detection scope.
11. Keep number detection and keyboard handling isolated and testable.
12. Coordinate every command type and data schema with the mobile team.
13. Update this document when platform scope or product decisions
    change.

------------------------------------------------------------------------

## 15. Open Decisions Before Implementation

-   Final web framework and state-management choice.
-   Whether the first release is browser-only or includes a browser
    extension.
-   Whether system-wide overlay and global keyboard shortcuts justify a
    desktop companion app.
-   Exact Firebase Realtime Database paths and command schema.
-   Whether Google Sign-In is enabled at launch.
-   Invitation/admin account provisioning workflow.
-   Exact remote call actions supported by the first mobile release.
-   Volume command semantics and supported Android behavior.
-   Number normalization rules and default country/region.
-   Whether call history is included, and its retention policy.
-   Whether users can register/replace a device and what verification is
    required.

Treat these as open decisions until explicitly confirmed. Do not
implement a browser-only approximation while presenting it as
system-wide overlay functionality.

------------------------------------------------------------------------

**Document status:** Initial project context\
**Product:** FlashDial Web\
**Brand owner:** Aarambh Technologies\
**Authentication policy:** Shared Firebase accounts; approved-user
access; no public web registration
