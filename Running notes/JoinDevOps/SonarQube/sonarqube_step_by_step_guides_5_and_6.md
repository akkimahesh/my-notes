# Step-by-Step Documentation: User Creation & Project Isolation (RBAC)

---

# Part 1 (Document 5): Creating Developer Accounts in SonarQube

This guide explains how to create new developer accounts without triggering syntax errors.

---

### Step 1.1: Navigate to User Management
1. Log into SonarQube as an **Administrator**.
2. In the top navigation bar, click on **Administration**.
3. In the sub-menu, select **Security** → click **Users**.
4. Click the blue **Create User** button located in the top-right corner.

---

### Step 1.2: Fill Out User Information (Avoiding Syntax Errors)

> [!WARNING]
> **The `Login` field does NOT permit spaces.**  
> SonarQube validates `Login` with the regex: `^[a-zA-Z0-9_.-@]+$`. Using spaces will cause the error:  
> `Login should contain only letters, numbers, and .-_@`

| Field | Allowed Format | Example Value | Notes |
| :--- | :--- | :--- | :--- |
| **Login\*** | Letters, numbers, `.` `-` `_` `@` **(No spaces)** | `charan.b` or `bolgam.charan` | This is the username used to log in. |
| **Name\*** | Any characters, spaces allowed | `Bolgam Sai Charan` | This is the display name shown on reports and issues. |
| **Email** | Valid email address | `charan.b@chrp-india.com` | Used for notifications and avatar mapping. |
| **Password\*** | Any secure string | `••••••••••••` | Developer will use this to sign in. |
| **SCM Accounts** | Optional | *(Leave empty)* | Optional Git/SCM author mapping. |

---

### Step 1.3: Save and Verify
1. Click **Create**.
2. Verify that the user appears in the **Users** list with the `sonar-users` group automatically assigned.
3. Share the **Login** and **Password** with the developer.

---
---

# Part 2 (Document 6): Restricting Project Visibility & Disabling "Create Project" (RBAC)

By default in SonarQube, every new user belongs to `sonar-users`. If global permissions or project-level permissions are left open, new users will be able to create projects and inspect unrelated proprietary projects.

Follow these 4 steps to achieve complete isolation:

---

### Step 2.1: Revoke "Create Projects" Globally (Stop Developers from Creating Projects)

1. Go to **Administration** (top bar) → **Security** → **Global Permissions**.
2. Find the row for **`sonar-users`**.
3. **Uncheck** the box under **Create Projects**.
4. *(Optional)* If the **`Anyone`** row has **Create Projects** checked, uncheck that as well.

> [!NOTE]
> Only `sonar-administrators` should have the **Create Projects** permission checked.

---

### Step 2.2: Ensure All Sensitive Projects Are Marked `PRIVATE`

If a project is marked `PUBLIC`, every user can see it regardless of permissions.

1. Go to **Administration** → **Projects** → **Management**.
2. Review the list of projects in the table.
3. Identify any project missing the **`PRIVATE`** badge (e.g., `Indus Towers Flutter`, `XRD-Frontend`):
   - Check the checkbox on the left of each public project.
   - Click the top dropdown: **`Public, Pri... ▾`**.
   - Select **Private**.
4. Verify all projects in the list display the **`PRIVATE`** badge.

---

### Step 2.3: Strip `sonar-users` Permissions from Other Projects

Marking a project `PRIVATE` restricts access to assigned users and groups. However, if the project still grants permissions to the group `sonar-users`, every authenticated user can still see it.

For **each project that the developer should NOT see** (e.g., `XRD-Backend`, `Schneider Backend`, etc.):

1. Open the project:
   - Example: `https://sonarqube.chrp-india.com/project_roles?id=XRD-Backend`
   *(or click **Projects** → select project → **Project Settings** → **Permissions**)*
2. Click on the **Groups** tab.
3. Locate the **`sonar-users`** row.
4. **Uncheck ALL boxes** on this row:
   - ⬜ **Browse**
   - ⬜ **See Source Code**
   - ⬜ **Administer Issues**
   - ⬜ **Administer Security Hotspots**
   - ⬜ **Administer**
   - ⬜ **Execute Analysis**

> [!IMPORTANT]
> The **`sonar-users`** row must be **completely blank (all checkboxes cleared)** on any project you wish to hide.

---

### Step 2.4: Grant Read-Only Access ONLY to the Assigned Project

Now, configure the only project the developer is allowed to access (`offline-app-clientportal`):

1. Go to the project dashboard:  
   `https://sonarqube.chrp-india.com/project_roles?id=offline-app-clientportal`  
   *(or **Projects** → `offline-app-clientportal` → **Project Settings** → **Permissions**)*
2. Under the **Users** tab (or **Groups** if using a specific project team group):
   - Search for `charan.b`.
3. Check **ONLY** these two boxes:
   - ☑️ **Browse** (Allows viewing the dashboard, issues list, and metrics).
   - ☑️ **See Source Code** (Allows viewing code lines associated with issues).
4. Leave all other permissions unchecked:
   - ⬜ *Administer Issues*
   - ⬜ *Administer Security Hotspots*
   - ⬜ *Administer*
   - ⬜ *Execute Analysis*

---

## 3. Verification Checklist

Log in as the developer (`charan.b`) in an Incognito / Private window and confirm:

- [ ] **Home / Projects page**: Only **`offline-app-clientportal`** is visible.
- [ ] **Other projects**: `XRD-Backend`, `Schneider Backend`, and `Indus Towers Flutter` are **not visible**.
- [ ] **Top navigation**: There is **no "+ / Create Project"** button.
- [ ] **Project view**: Developer can inspect **Issues**, **Code Smells**, and source lines.
- [ ] **Admin settings**: Developer **cannot** modify project settings, quality profiles, or quality gates.
