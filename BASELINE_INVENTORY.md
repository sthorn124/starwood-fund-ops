# Baseline inventory — Starwood Demo (subscription intake), before draw approval

This is the application as found before any draw approval work began. It lists top-level object **names only**: no object contents were read, and nothing was modified.

- **Captured:** 2026-09-21.
- **Source:** Dev MCP `listApplicationObjects` on application `dd3bb740-b105-421b-a866-29d542a144da` (`Starwood Demo`, prefix `SD`).
- **Identity:** run as `scott.thorn@appian.com`, the designer account. That account is a member of `SD Administrators` and, through it, of `SD Users`.
- **Scope of the listing:** design-object listings are not row-secured. Only the application's own objects are listed; objects outside the application are not visible here.

Draw approval objects added later are recorded in `BUILD_LOG.md`, not here. This file is the "before" picture and is not updated.

## Record types (16)

- SD Subscription
- SD Subscription Submission
- SD Ref Subscription Status
- SD Review Task
- SD Investor
- SD Status History
- SD Fund
- SD Document Classification
- SD Field Extraction
- SD Ref Document Type
- SD Ref Entity Type
- SD Ref Task Outcome
- SD Ref Task Type
- SA Fund
- Subscription Agreement
- SA Subscription Event

## Process models (15)

- SD Create Or Update Subscription
- SD Create Or Update Subscription Submission
- SD Upload and Process Subscription Packet
- SD Extract and Validate Subscription Data
- SD Review and Correct Flagged Fields
- SD Submit for Compliance Review
- SD Compliance Review and Approval
- SD Escalate Overdue Tasks
- SD Manager Pipeline Oversight
- SA Upload and Create Subscription
- SA Approve DocCenter Split
- SD Process Packet (async)
- SD Start Intake (MCP)
- SD Approve Subscription (MCP)
- SD Process Batch Roster (MCP)

## Interfaces (14)

- SD_CreateOrUpdateSubscription
- SD_CreateOrUpdateSubscriptionSubmission
- SD_SubscriptionSubmissionSummary
- SD_ReviewTaskSummary
- SD_FieldExtractionSummary
- SD_CMPT_LandingPageAlertCard
- SD_CMPT_LandingPageTaskCard
- SD_SubscriptionIntakeDashboard
- SD_FundOperationsManagementDashboard
- SA_NewSubscriptionUploadForm
- SA_DocCenterSplitReview
- SA_SubscriptionAgreementSummary
- SD_SubscriptionManagementDashboard
- SD_form_reviewClassificationResults

## Sites (0)

- None. The application contains no site.

## Groups (7)

- SD Administrators
- SD Users
- SD Fund Operations Manager
- SD Compliance Reviewer
- SD Fund Operations Analyst
- Subscription Agreement Analysts
- SD Compliance Reviewers

## Observations (names only, no contents read)

- **Nothing draw-related exists yet.** No object name mentions a draw, a capital call, a budget, or approval of a draw.
- **Three naming families coexist:** `SD` / `SD_`, `SA` / `SA_`, and two unprefixed objects (`Subscription Agreement` and `Subscription Agreement Analysts`).
- **Two compliance groups have near-identical names:** `SD Compliance Reviewer` (singular, currently empty) and `SD Compliance Reviewers` (plural, one member).
- **Other object types were not inventoried this session:** expression rules, constants, integrations, connected systems, documents, folders, agents, AI skills, web APIs, and portals.
