# AutoRescue System Security Overview

**Document Version:** 1.0  
**Project:** AutoRescue (South-West Cameroon Roadside Assistance Platform)  
**Target Scope:** Backend (Spring Boot), Mobile & Web Clients (Flutter), Database (MySQL/Flyway), & Third-Party Integrations  

---

## Executive Summary
AutoRescue is designed with a multi-layered security architecture ensuring end-to-end data privacy, role segregation, real-time communication protection, and secure payment processing. This document outlines the core security measures implemented across the application.

---

## 1. Authentication & Session Management
* **BCrypt Password Hashing**: User passwords are never stored in plain text. They are salted and hashed using `BCryptPasswordEncoder`.
* **Stateless JWT Authorization**: API calls are authenticated using JSON Web Tokens (JWT) signed with HMAC-SHA256 (`JwtService.java`).
* **Two-Factor Authentication (2FA / OTP) for Admins**:
  * Admin sign-in follows a mandatory two-step verification flow (`AdminAuthService.java`).
  * On valid password entry, a single-use 6-digit OTP is generated and emailed to the admin.
  * Access tokens are issued only upon successful OTP verification.
* **Client-Side Session Cleanup**: If an API request returns `401 Unauthorized`, the Flutter client automatically purges tokens and session state to prevent unauthorized reuse.

---

## 2. Role-Based Access Control (RBAC) & Authorization
* **Role Segregation (`DRIVER`, `MECHANIC`, `ADMIN`)**:
  * Enforced at the gateway (`SecurityConfig.java`) and method levels (`@PreAuthorize`).
* **Resource Ownership Guard**:
  * Users can only access or modify their own data (e.g., drivers can only view their own assistance requests; mechanics can only edit their own workshop details).
* **Admin Verification Gate**:
  * Newly registered workshops default to a `PENDING` verification status.
  * Unverified workshops are excluded from driver search results and cannot receive service requests until reviewed and approved by an Admin.

---

## 3. Network Defense & API Security
* **Transport Layer Security (TLS/HTTPS)**:
  * All REST APIs, WebSockets, and Cloudinary media uploads communicate strictly over HTTPS.
* **CORS Policy Controls**:
  * Restricted origin configuration in `WebConfig.java` prevents unauthorized cross-site requests.
* **Rate Limiting & Brute-Force Defense**:
  * `InMemoryRateLimiter` throttles sensitive authentication endpoints (`/login`, `/forgot-password`, `/verify-otp`) to mitigate automated brute-force attacks.
* **Request Timeout Guards**:
  * Client-side `ApiClient` enforces a 45-second timeout to prevent connection hanging and resource exhaustion.

---

## 4. Real-Time Communication Security
* **Authenticated WebSockets**:
  * WebSocket handshakes and STOMP channels are verified via `JwtHandshakeInterceptor` and `StompAuthChannelInterceptor`.
* **Scoped Tracking & Chat Channels**:
  * Live location tracking and chat threads (`/topic/requests/{id}`) are restricted to paired drivers and mechanics assigned to that specific request.
* **Short-Lived Ephemeral Voice Tokens (Agora RTC)**:
  * The **Agora App Certificate** is strictly kept server-side.
  * The backend generates short-lived, per-call tokens (`AgoraTokenService.java`) scoped strictly to active requests (`ACCEPTED` or `EN_ROUTE`), preventing phone number exposure.

---

## 5. Payment Security & Financial Protection (MeSomb)
* **HMAC-SHA256 Webhook Verification**:
  * MeSomb webhooks (`/api/payments/webhooks/mesomb`) verify signatures (`X-MeSomb-Webhook-Signature`) and enforce a 5-minute timestamp tolerance to prevent replay attacks.
* **Server-to-Server Payment Reconciliation**:
  * `PaymentService.refreshStatus` queries the payment gateway directly, preventing client-side status tampering or fake transaction claims.
* **Zero Sensitive Financial Storage**:
  * Credit card numbers, PINs, and mobile money secrets are never stored on AutoRescue databases.

---

## 6. Data Integrity & Input Validation
* **SQL Injection & XSS Mitigation**:
  * Spring Data JPA / Hibernate parameterized queries prevent SQL injection.
  * Text input fields and email templates use strict HTML escaping.
* **File Upload Restrictions**:
  * Uploaded documents and workshop photos are capped at 10MB and stored in Cloudinary using randomized UUID filenames.
