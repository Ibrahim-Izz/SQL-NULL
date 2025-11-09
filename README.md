# SQL NULL Killers: Quick Reference Guide 💀

Common SQL mistakes that silently eliminate rows due to NULL handling, with execution plan explanations.

---

## NULL KILLER #1: LEFT JOIN + WHERE Filter

### 📋 Scenario: Get all patients and their completed lab results
*Critical: Many patients have pending/refused tests - NO results yet!*

### The Problem
WHERE clause filters are applied AFTER the join completes, eliminating NULL rows and converting LEFT JOIN to INNER JOIN.

### ❌ WRONG - Lost 5 patients (6 shown, 12 exist)
```sql
SELECT p.patient_id, p.full_name, lr.result_date
FROM patients p
LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
WHERE lr.result_date IS NOT NULL;  -- 🚨 Applied AFTER join
```

**Execution Order:**
1. Perform LEFT JOIN → creates rows with NULL for unmatched patients
2. Apply WHERE filter → eliminates those NULL rows

### ✅ CORRECT - All 12 patients preserved
```sql
SELECT p.patient_id, p.full_name, lr.result_date
FROM patients p
LEFT JOIN lab_results lr 
    ON p.patient_id = lr.patient_id
    AND lr.result_date IS NOT NULL;  -- ✅ Applied DURING join
```

**Execution Order:**
1. Perform LEFT JOIN with filter in join condition → unmatched patients get NULL
2. No post-join filtering → all patients included

**Key Takeaway:** Filters in ON clause affect matching; filters in WHERE clause eliminate rows.

---

## NULL KILLER #2: WHERE col <> value

### 📋 Scenario: Find physicians who are NOT cardiologists
*Critical: General practitioners have NULL specialty!*

### The Problem
SQL uses three-valued logic: TRUE, FALSE, UNKNOWN. NULL comparisons return UNKNOWN, which WHERE treats as FALSE.

### ❌ WRONG - Lost 1 physician (6 shown, 8 exist)
```sql
SELECT physician_id, full_name, specialty
FROM physicians
WHERE specialty <> 'Cardiology';  -- 🚨 NULL <> 'Cardiology' → UNKNOWN → excluded
```

**Why NULL is excluded:**
- `'Neurology' <> 'Cardiology'` → TRUE ✅
- `'Cardiology' <> 'Cardiology'` → FALSE ❌
- `NULL <> 'Cardiology'` → UNKNOWN ❌ (treated as FALSE in WHERE)

### ✅ CORRECT - Includes NULL specialties (7 shown)
```sql
SELECT physician_id, full_name, specialty
FROM physicians
WHERE specialty <> 'Cardiology' 
    OR specialty IS NULL;  -- ✅ Explicit NULL handling
```

**Key Takeaway:** Inequality operators (`<>`, `!=`, `>`, `<`) never match NULL. Use `OR column IS NULL`.

---

## NULL KILLER #3: Aggregations Ignore NULL

### 📋 Scenario: Calculate average admission cost
*Critical: Many admissions have NULL cost (charity care, ongoing, insurance processing)!*

### The Problem
Aggregate functions (AVG, SUM, COUNT(column)) skip NULL values at the storage level, potentially skewing results.

### ❌ MISLEADING - Hidden NULL values
```sql
SELECT 
    AVG(total_cost) AS avg_cost,
    COUNT(total_cost) AS admissions_with_cost,
    COUNT(*) AS total_admissions
FROM admissions;
```

**Result:** Average of 4 admissions = $5,000, but 12 total admissions exist!

**How it works:**
- Database reads NULL bitmap
- Skips NULL values entirely (doesn't add to sum or increment count)
- `COUNT(total_cost)` = 4, `COUNT(*)` = 12

### ✅ CORRECT - Shows the full picture
```sql
SELECT 
    SUM(total_cost) / COUNT(*) AS avg_including_nulls,
    AVG(total_cost) AS avg_excluding_nulls,
    COUNT(*) AS total_admissions,
    COUNT(total_cost) AS admissions_with_cost
FROM admissions;
```

**Key Takeaway:** 
- `COUNT(*)` counts all rows
- `COUNT(column)` counts only non-NULL values
- AVG, SUM, MIN, MAX ignore NULLs

---

## NULL KILLER #4: NOT IN with NULL

### 📋 Scenario: Find patients NOT covered by Blue Cross or United Healthcare
*Critical: Many patients have NULL insurance (uninsured, unknown)!*

### The Problem
When NULL is in the NOT IN list, three-valued logic causes the entire query to return zero rows.

### ❌ WRONG - Returns 0 rows! (12 patients exist)
```sql
SELECT patient_id, insurance_provider
FROM patients
WHERE insurance_provider NOT IN (
    'Blue Cross Blue Shield', 
    'United Healthcare', 
    NULL  -- 🚨 This NULL kills everything!
);
```

**Why this returns nothing:**

NOT IN is equivalent to:
```sql
WHERE NOT (
    insurance_provider = 'Blue Cross' OR
    insurance_provider = 'United' OR
    insurance_provider = NULL  -- Always UNKNOWN
)
```

For ANY value:
- At least one comparison is UNKNOWN (the `= NULL` part)
- `TRUE OR UNKNOWN` → UNKNOWN
- `NOT(UNKNOWN)` → UNKNOWN → excluded by WHERE

### ✅ CORRECT - 8 patients returned
```sql
SELECT patient_id, insurance_provider
FROM patients
WHERE insurance_provider NOT IN ('Blue Cross Blue Shield', 'United Healthcare')
    OR insurance_provider IS NULL;  -- ✅ Explicit NULL handling
```

**Alternative - NOT EXISTS (handles NULL naturally):**
```sql
SELECT patient_id, insurance_provider
FROM patients p
WHERE NOT EXISTS (
    SELECT 1 FROM (VALUES ('Blue Cross'), ('United')) AS excluded(provider)
    WHERE p.insurance_provider = excluded.provider
);
```

NOT EXISTS returns TRUE/FALSE (never UNKNOWN), so NULLs are naturally included.

**Key Takeaway:** Avoid NOT IN with nullable columns. Use NOT EXISTS or explicit NULL checks.

---

## Quick Reference: Execution Order

### Query Processing Order
```
1. FROM / JOIN        → Build dataset
2. WHERE              → Filter rows (AFTER joins)
3. GROUP BY           → Group rows
4. HAVING             → Filter groups
5. SELECT             → Project columns
6. ORDER BY           → Sort results
```
