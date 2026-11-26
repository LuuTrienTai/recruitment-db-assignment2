"""M5 — kiểm chứng ngẫu nhiên sp_report_job_applications và fn_employer_recruitment_budget.

Gọi routine qua mysql-connector-python (giống backend) rồi so TỪNG Ô kết quả với một
cài đặt độc lập bằng Python (oracle) trên dữ liệu và tham số ngẫu nhiên.

  Phần 1  gọi như backend: tên/kiểu cột, ví dụ trong docs/contracts.md, mã + thông báo lỗi
  Phần 2  thêm ~200 hồ sơ, ~80 nhu cầu ngẫu nhiên (nhiều mốc 00:00:00/23:59:59, ngân sách
          NULL/0), gọi mỗi routine N lần với tham số ngẫu nhiên (cả tham số sai)
  Phần 3  tính chất cộng theo kỳ: 12 tháng cộng lại = cả năm (lập luận của D-M5-02)
  Phần 4  ROLLBACK, kiểm tra dữ liệu và application_count trở về như cũ

Điều kiện: DB đã có schema, seed và hai routine M5; `.env` ở thư mục gốc repo có
DB_HOST/DB_PORT/DB_USER/DB_PASSWORD (như backend).
  pip install mysql-connector-python
  python database/tests/m5_verify_random.py [seed] [số_lần_gọi]     # mặc định 20261124 3000
Mọi dữ liệu thêm vào nằm trong một transaction và bị ROLLBACK. Thoát mã 0 khi tất cả PASS.
"""
import datetime as dt
import random
import sys
import warnings
from decimal import Decimal
from pathlib import Path

import mysql.connector

warnings.filterwarnings("ignore", category=DeprecationWarning)  # stored_results() ở connector 26.x

REPO = Path(__file__).resolve().parents[2]
SEED = int(sys.argv[1]) if len(sys.argv) > 1 else 20261124
N_CALLS = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
rnd = random.Random(SEED)

env = {}
for line in (REPO / ".env").read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if line and not line.startswith("#") and "=" in line:
        k, v = line.split("=", 1)
        env[k] = v

conn = mysql.connector.connect(host=env.get("DB_HOST", "127.0.0.1"), port=int(env.get("DB_PORT", 3306)),
                               user=env["DB_USER"], password=env["DB_PASSWORD"],
                               database=env.get("DB_NAME", "recruitment_db"), charset="utf8mb4", autocommit=False)
cur = conn.cursor()

FAILS = []
CHECKS = 0


def check(cond, msg):
    global CHECKS
    CHECKS += 1
    if not cond:
        FAILS.append(msg)
        if len(FAILS) <= 15:
            print("  FAIL", msg)


MSG = {
    "min_null": "Số hồ sơ tối thiểu (p_min_applications) là bắt buộc; nhập 0 để hiển thị cả tin chưa có hồ sơ.",
    "min_neg": "Số hồ sơ tối thiểu (p_min_applications) không được âm.",
    "range": "Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).",
    "company": "Công ty (p_company_id) không tồn tại.",
    "emp_null": "Mã employer (p_employer_id) là bắt buộc.",
    "emp": "Employer (p_employer_id) không tồn tại.",
}
COLS = ["job_posting_id", "title", "company_id", "company_name", "job_status", "posted_date",
        "application_deadline", "total_applications", "submitted_count", "viewed_count",
        "interviewing_count", "accepted_count", "rejected_count", "first_submission", "last_submission"]
STATUSES = ["submitted", "viewed", "interviewing", "accepted", "rejected"]


def call_proc(args):
    """Gọi như backend: callproc + stored_results. Trả (cols, rows) hoặc ('ERR', errno, sqlstate, msg)."""
    try:
        cur.callproc("sp_report_job_applications", args)
        res = list(cur.stored_results())
        r = res[0]
        return [d[0] for d in r.description], r.fetchall()
    except mysql.connector.Error as e:
        return ("ERR", e.errno, e.sqlstate, e.msg)


def call_fn(args):
    try:
        cur.execute("SELECT fn_employer_recruitment_budget(%s, %s, %s)", args)
        return cur.fetchone()[0]
    except mysql.connector.Error as e:
        return ("ERR", e.errno, e.sqlstate, e.msg)


# ------------------------------------------------------------------ PHẦN 1
print("== PHẦN 1: gọi như backend (mysql-connector-python)")
cols, rows = call_proc((dt.date(2026, 10, 1), dt.date(2026, 11, 30), None, 1))
check(cols == COLS, f"tên cột procedure khác contract: {cols}")
check([(r[0], r[7]) for r in rows] == [(701, 2), (704, 2), (702, 1), (705, 1)], f"ví dụ contract 1: {rows}")
types = {c: type(v).__name__ for c, v in zip(cols, rows[0])}
print("   kiểu Python của các cột:", ", ".join(f"{c}={t}" for c, t in types.items()))
check(isinstance(rows[0][7], int), "total_applications phải là int")
check(all(isinstance(rows[0][i], int) for i in range(7, 13)), "6 cột đếm phải cùng kiểu int")
check(isinstance(rows[0][13], dt.datetime), "first_submission phải là datetime")
cols, rows = call_proc((None, None, 401, 0))
check([(r[0], r[7]) for r in rows] == [(701, 2), (706, 0), (707, 0)], f"ví dụ contract 2: {rows}")
check(rows[-1][13] is None and rows[-1][14] is None, "tin 0 hồ sơ phải có first/last = None")
v = call_fn((201, dt.date(2026, 1, 1), dt.date(2026, 12, 31)))
check(v == Decimal("900000000.00") and isinstance(v, Decimal), f"fn(201, 2026) = {v!r}")
check(call_fn((209, None, None)) is None, "fn(209) phải là None (NULL)")
check(call_fn((210, None, None)) == Decimal("0.00"), "fn(210) phải là 0.00")
for args, key in [((None, None, None, None), "min_null"), ((None, None, None, -1), "min_neg"),
                  ((dt.date(2026, 12, 1), dt.date(2026, 11, 1), None, 0), "range"),
                  ((None, None, 999, 0), "company"), ((None, None, -7, 0), "company")]:
    r = call_proc(args)
    check(r == ("ERR", 1644, "45000", MSG[key]), f"lỗi procedure {args}: {r}")
for args, key in [((None, None, None), "emp_null"), ((999, None, None), "emp"), ((-5, None, None), "emp"),
                  ((201, dt.date(2026, 12, 31), dt.date(2026, 1, 1)), "range")]:
    r = call_fn(args)
    check(r == ("ERR", 1644, "45000", MSG[key]), f"lỗi function {args}: {r}")
print(f"   {CHECKS} kiểm tra, {len(FAILS)} FAIL")

# ------------------------------------------------------------------ PHẦN 2
print(f"== PHẦN 2: đối chiếu ngẫu nhiên (seed={SEED}, {N_CALLS} lần gọi mỗi routine)")
cur.execute("SELECT COUNT(*) FROM application"); base_app = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM recruitment_need"); base_need = cur.fetchone()[0]

cur.execute("SELECT candidate_id, cv_no FROM cv"); cvs = cur.fetchall()
cur.execute("SELECT job_posting_id FROM job_posting"); jobs = [r[0] for r in cur.fetchall()]
cur.execute("SELECT employer_id, company_id FROM employer"); emps = cur.fetchall()

start = dt.datetime(2026, 8, 1)
apps = []
for i in range(200):
    day = start + dt.timedelta(days=rnd.randint(0, 180))
    t = rnd.choice([dt.time(0, 0, 0), dt.time(23, 59, 59), dt.time(rnd.randint(0, 23), rnd.randint(0, 59), rnd.randint(0, 59))])
    cand, cvno = rnd.choice(cvs)
    apps.append((5000 + i, cand, cvno, rnd.choice(jobs), dt.datetime.combine(day.date(), t), rnd.choice(STATUSES)))
cur.executemany("""INSERT INTO application (application_id, candidate_id, cv_no, job_posting_id, submission_time,
                   contact_name, email, phone_number, work_location, personal_data_usage_agreed, application_status)
                   VALUES (%s,%s,%s,%s,%s,'Test','test@example.test','0900000000','Ho Chi Minh City',TRUE,%s)""", apps)
needs = []
for i in range(80):
    e, c = rnd.choice(emps)
    d = dt.date(2025, 6, 1) + dt.timedelta(days=rnd.randint(0, 730))
    b = rnd.choice([None, None, Decimal("0.00"), Decimal(rnd.randint(1, 10**11)) / 100])
    needs.append((6000 + i, d, b, e, c))
cur.executemany("""INSERT INTO recruitment_need (need_id, declared_date, professional_position, job_level,
                   number_employee_required, budget) VALUES (%s,%s,'Test position','Junior',1,%s)""",
                [(n[0], n[1], n[2]) for n in needs])
cur.executemany("INSERT INTO declares_recruitment_need (need_id, employer_id, company_id) VALUES (%s,%s,%s)",
                [(n[0], n[3], n[4]) for n in needs])

# Ảnh chụp dữ liệu bằng SELECT thường để oracle tự tính
cur.execute("""SELECT jp.job_posting_id, jp.title, c.company_id, c.name, jp.job_status, jp.posted_date,
               jp.application_deadline FROM job_posting jp JOIN company c ON c.company_id = jp.company_id""")
JOBS = cur.fetchall()
cur.execute("SELECT job_posting_id, submission_time, application_status FROM application")
APPS = cur.fetchall()
cur.execute("SELECT company_id FROM company"); COMPANIES = {r[0] for r in cur.fetchall()}
cur.execute("""SELECT d.employer_id, rn.declared_date, rn.budget FROM recruitment_need rn
               JOIN declares_recruitment_need d ON d.need_id = rn.need_id""")
NEEDS = cur.fetchall()
EMPLOYERS = {e for e, _ in emps}


def oracle_proc(f, t, comp, mn):
    if mn is None: return ("ERR", 1644, "45000", MSG["min_null"])
    if mn < 0: return ("ERR", 1644, "45000", MSG["min_neg"])
    if f is not None and t is not None and f > t: return ("ERR", 1644, "45000", MSG["range"])
    if comp is not None and comp not in COMPANIES: return ("ERR", 1644, "45000", MSG["company"])
    out = []
    for j in JOBS:
        if comp is not None and j[2] != comp: continue
        sel = [a for a in APPS if a[0] == j[0] and (f is None or a[1].date() >= f) and (t is None or a[1].date() <= t)]
        if len(sel) < mn: continue
        counts = [sum(1 for a in sel if a[2] == s) for s in STATUSES]
        times = [a[1] for a in sel]
        out.append(tuple(j) + (len(sel), *counts, min(times) if times else None, max(times) if times else None))
    out.sort(key=lambda r: (-r[7], r[0]))
    return out


def oracle_fn(e, f, t):
    if e is None: return ("ERR", 1644, "45000", MSG["emp_null"])
    if e not in EMPLOYERS: return ("ERR", 1644, "45000", MSG["emp"])
    if f is not None and t is not None and f > t: return ("ERR", 1644, "45000", MSG["range"])
    sel = [b for (emp, d, b) in NEEDS if emp == e and (f is None or d >= f) and (t is None or d <= t)]
    if not sel: return Decimal("0.00")
    known = [b for b in sel if b is not None]
    return sum(known, Decimal("0.00")) if known else None


def rnd_date():
    r = rnd.random()
    if r < 0.15: return None
    if r < 0.20: return rnd.choice([dt.date(1000, 1, 1), dt.date(9999, 12, 31)])
    return dt.date(2025, 6, 1) + dt.timedelta(days=rnd.randint(0, 760))


def rnd_pair():
    f, t = rnd_date(), rnd_date()
    if f is not None and t is not None and f > t and rnd.random() < 0.9:
        f, t = t, f
    return f, t


def norm(rows):  # SUM(CASE…) trả Decimal; đưa về int để so với oracle
    return [tuple(int(v) if isinstance(v, Decimal) else v for v in r) for r in rows]


n_err = n_rows = 0
for k in range(N_CALLS):
    f, t = rnd_pair()
    comp = rnd.choice([None, None, None, 401, 402, 403, 404, 405, 401, 404] + ([999, 0, -3] if rnd.random() < 0.1 else []))
    mn = rnd.choice([0, 0, 0, 1, 1, 2, 3, 5, 8] + ([None, -1] if rnd.random() < 0.1 else []))
    exp = oracle_proc(f, t, comp, mn)
    got = call_proc((f, t, comp, mn))
    if isinstance(exp, tuple):
        n_err += 1
        check(got == exp, f"proc{(f, t, comp, mn)}: kỳ vọng {exp}, nhận {got}")
    else:
        n_rows += len(exp)
        check(got[0] == COLS and norm(got[1]) == exp, f"proc{(f, t, comp, mn)}: kết quả lệch oracle")
print(f"   procedure: {N_CALLS} lần gọi ({N_CALLS - n_err} hợp lệ, {n_err} kỳ vọng lỗi; {n_rows} dòng so từng ô)")

fe = 0
for k in range(N_CALLS):
    e = rnd.choice([201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 201, 209, 210] + ([None, 999, 101, 0, -1] if rnd.random() < 0.1 else []))
    f, t = rnd_pair()
    exp = oracle_fn(e, f, t)
    got = call_fn((e, f, t))
    fe += isinstance(exp, tuple)
    check(got == exp and type(got) is type(exp), f"fn{(e, f, t)}: kỳ vọng {exp!r}, nhận {got!r}")
print(f"   function: {N_CALLS} lần gọi ({N_CALLS - fe} hợp lệ, {fe} kỳ vọng lỗi)")
nulls = sum(1 for e in range(201, 211) if call_fn((e, None, None)) is None)
print(f"   dữ liệu ngẫu nhiên: {len(apps)} hồ sơ, {len(needs)} nhu cầu ({sum(1 for n in needs if n[2] is None)} NULL, "
      f"{sum(1 for n in needs if n[2] == 0)} bằng 0)")

# ------------------------------------------------------------------ PHẦN 3
print("== PHẦN 3: tính chất cộng theo kỳ (lập luận của D-M5-02)")
for year in (2025, 2026, 2027):
    months = [(dt.date(year, m, 1), (dt.date(year + (m == 12), m % 12 + 1, 1) - dt.timedelta(days=1))) for m in range(1, 13)]
    for e in range(201, 211):
        yv = call_fn((e, dt.date(year, 1, 1), dt.date(year, 12, 31)))
        mv = [call_fn((e, a, b)) for a, b in months]
        s = sum((x for x in mv if x is not None), Decimal("0.00"))
        check((yv is None and all(x is None or x == 0 for x in mv) and any(x is None for x in mv)) or yv == s,
              f"ngân sách {e}/{year}: năm={yv}, tổng tháng={s}")
    _, yrows = call_proc((dt.date(year, 1, 1), dt.date(year, 12, 31), None, 0))
    ytot = {r[0]: r[7] for r in yrows}
    mtot = {}
    for a, b in months:
        for r in call_proc((a, b, None, 0))[1]:
            mtot[r[0]] = mtot.get(r[0], 0) + r[7]
    check(ytot == mtot, f"hồ sơ {year}: năm={ytot}, tổng tháng={mtot}")
print("   12 tháng cộng lại = cả năm, cho 10 employer × 3 năm và mọi tin × 3 năm")

# ------------------------------------------------------------------ PHẦN 4
conn.rollback()
cur.execute("SELECT COUNT(*) FROM application"); a2 = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM recruitment_need"); n2 = cur.fetchone()[0]
cur.execute("""SELECT COUNT(*) FROM job_posting jp WHERE jp.application_count <>
               (SELECT COUNT(*) FROM application a WHERE a.job_posting_id = jp.job_posting_id)""")
mm = cur.fetchone()[0]
check(a2 == base_app and n2 == base_need and mm == 0, f"sau ROLLBACK: app {a2}/{base_app}, need {n2}/{base_need}, lệch count {mm}")
print(f"== PHẦN 4: ROLLBACK — application {a2}, recruitment_need {n2}, application_count lệch {mm}")
print(f"== TỔNG: {CHECKS} kiểm tra, {len(FAILS)} FAIL -> {'TẤT CẢ PASS' if not FAILS else 'CÓ FAIL'}")
sys.exit(1 if FAILS else 0)
