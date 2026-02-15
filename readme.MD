```md
---

## ♻️ Shared Utility Script (`common.sh`)

To keep the Expense application automation simple and maintainable, all repeated logic is written once inside a shared file:

```

common.sh

````

Each component script (mysql, backend, frontend) imports it using:

```bash
source common.sh
````

This avoids duplicating the same code across multiple scripts and follows real DevOps engineering standards 🧠

---

## 🧰 What `common.sh` Handles

---

### 🔐 Root Privilege Validation

Ensures scripts run only with administrator permissions.

**Why needed?**
Installing packages, configuring services, and writing system files require root access.

**Behavior:**

* Root user → continue ✔️
* Non-root user → exit immediately ❌

Prevents partial configuration and broken environments ⚠️

---

### 👤 Application User Creation

Creates the application user only if it does not already exist.

**Benefits:**

* No duplicate users
* Safe re-execution
* Maintains idempotency ♻️

---

### 📜 Centralized Logging

All scripts write execution output to a standard log location:

```
/var/log/shell-expense/
```

**Advantages:**

* Easy debugging 🔍
* Consistent log format 📏
* Track execution history 🧾

Every step prints meaningful messages instead of silent execution.

---

### ✔️ Command Status Validation

After each important command, the result is checked.

**Flow:**

* Success → continue
* Failure → stop script with clear error message

Avoids confusion like:

> Service installed but not working

---

### 📦 Smart Package Installation

Reusable installer function:

* Checks if package already installed
* Installs only if missing
* Speeds up repeated runs
* Saves bandwidth ♻️

---

### 🧠 Standard Output Messages

Scripts display uniform status messages:

* INFO ℹ️
* SUCCESS ✅
* FAILURE ❌

This makes logs readable even for new users.

---

## 🏗️ How Scripts Use It

Each script begins with:

```bash
source /home/ec2-user/shell-expense/common.sh
```

Then functions are directly used:

```bash
check_root
create_app_user
install_package nginx
validate $? "Installing Nginx"
```

---

## 🎯 Why This Design Matters

Centralizing shared logic provides:

* Cleaner scripts ✨
* Easier maintenance 🧹
* Consistent behavior 📏
* Safe re-execution ♻️
* Production-style structure 🏢

This is the same design approach used in real infrastructure automation projects.
