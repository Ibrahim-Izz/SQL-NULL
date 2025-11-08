# NULL Killers: Query Execution Order Explained

Understanding **when** filters are applied is the key to understanding NULL killers.

---

## 📋 SQL Query Execution Order

SQL queries don't execute in the order you write them. Here's the **actual execution order**:

```
1. FROM          → Get tables
2. JOIN          → Combine tables (ON clause filters here)
3. WHERE         → Filter the result set
4. GROUP BY      → Group rows
5. HAVING        → Filter groups
6. SELECT        → Pick columns
7. DISTINCT      → Remove duplicates
8. ORDER BY      → Sort results
9. LIMIT/OFFSET  → Limit rows
```

**The critical insight:** JOIN happens **before** WHERE!

---

## 🔪 NULL KILLER #1: LEFT JOIN + WHERE Filter

### **The Problem**

```sql
FROM players p
LEFT JOIN goals g ON p.player_id = g.player_id
WHERE g.goal_type = 'penalty'
```

### **Execution Order**

```
Step 1 (FROM): Load players table
  → 12 rows (including Hazard, Bale)

Step 2 (LEFT JOIN): Join with goals
  → Match ON player_id
  → For players WITH goals: include goal data
  → For players WITHOUT goals: include NULL for goal columns
  
  Result: 16 rows
  - Haaland: 3 rows with goals
  - Messi: 1 row with goal
  - Hazard: 1 row with NULL goal
  - Bale: 1 row with NULL goal
  - etc.

Step 3 (WHERE): Filter g.goal_type = 'penalty'
  → For Hazard: NULL = 'penalty' → UNKNOWN → REJECTED ❌
  → For Bale: NULL = 'penalty' → UNKNOWN → REJECTED ❌
  
  Final: 3 rows (only players with penalty goals)
  Lost: Hazard, Bale, De Bruyne, Busquets, Youth Prospect
```

### **Why It Kills NULLs**

**LEFT JOIN creates NULL rows** → **WHERE removes them** → NULL rows die

### **The Fix: Move Filter to ON**

```sql
LEFT JOIN goals g ON p.player_id = g.player_id 
    AND g.goal_type = 'penalty'
```

**New Execution:**
```
Step 2 (LEFT JOIN with filter):
  → Only match goals WHERE goal_type = 'penalty'
  → For players without penalty goals: include NULL
  → All players preserved!
  
Step 3 (WHERE): No filter → All rows kept
```

---

## 🔪 NULL KILLER #2: WHERE col <> value

### **The Problem**

```sql
SELECT * FROM players
WHERE position <> 'Forward'
```

### **Execution Order**

```
Step 1 (FROM): Load players table
  → 12 rows

Step 2 (WHERE): Filter position <> 'Forward'
  
  De Bruyne: 'Midfielder' <> 'Forward' → TRUE → KEPT ✅
  Busquets: 'Midfielder' <> 'Forward' → TRUE → KEPT ✅
  Hazard: NULL <> 'Forward' → UNKNOWN → REJECTED ❌
  Bale: NULL <> 'Forward' → UNKNOWN → REJECTED ❌
  
  Final: 2 rows (only non-forwards with known positions)
  Lost: Hazard, Bale (retired, NULL position)
```

### **Why It Kills NULLs**

**Three-valued logic:**
- `NULL <> 'Forward'` → Can we say NULL is definitely NOT 'Forward'?
- We don't know what NULL is → UNKNOWN
- WHERE keeps only TRUE → UNKNOWN gets filtered out

### **The Fix: Include NULL Explicitly**

```sql
WHERE position <> 'Forward' OR position IS NULL
```

**New Evaluation:**
```
Hazard: (NULL <> 'Forward') OR (NULL IS NULL)
        → UNKNOWN OR TRUE
        → TRUE → KEPT ✅
```

---

## 🔪 NULL KILLER #3: Aggregations Ignore NULL

### **The Problem**

```sql
SELECT AVG(market_value) FROM players
```

### **Execution Order**

```
Step 1 (FROM): Load players table
  → 12 rows

Step 2 (SELECT): Calculate AVG(market_value)
  
  Aggregate state: sum = 0, count = 0
  
  Row 1 (Haaland): value = 180 → sum = 180, count = 1
  Row 2 (Mbappe): value = 180 → sum = 360, count = 2
  ...
  Row 10 (Hazard): value = NULL → SKIP → sum unchanged, count unchanged
  Row 11 (Bale): value = NULL → SKIP → sum unchanged, count unchanged
  Row 12 (Youth): value = 2 → sum = 722, count = 10
  
  Final: AVG = 722 / 10 = 72.2
  
  Problem: Calculated average of 10 players, not 12!
```

### **Why It Kills NULLs**

**SQL Standard:** Aggregate functions (except COUNT(*)) **skip NULL values by design**

**Internal Logic:**
```
For each row:
  if (value IS NULL) 
    continue;  // Don't add to sum, don't increment count
  else
    sum += value;
    count++;
```

### **The Fix: Use COUNT(*) to Detect Missing Data**

```sql
SELECT 
    AVG(market_value) AS avg_active_players,
    SUM(market_value) / COUNT(*) AS avg_including_retired,
    COUNT(*) AS total_players,
    COUNT(market_value) AS players_with_value
FROM players
```

**Result:**
```
avg_active_players: 72.2 (10 players)
avg_including_retired: 60.2 (12 players)
total_players: 12
players_with_value: 10
```

---

## 🔪 NULL KILLER #4: NOT IN with NULL

### **The Problem**

```sql
SELECT * FROM players
WHERE nationality NOT IN ('BR', 'AR', NULL)
```

### **Execution Order**

```
Step 1 (FROM): Load players table
  → 12 rows

Step 2 (WHERE): Evaluate NOT IN
  
  Database expands NOT IN:
  WHERE NOT (nationality = 'BR' OR nationality = 'AR' OR nationality = NULL)
  
  Apply De Morgan's Law:
  WHERE nationality <> 'BR' AND nationality <> 'AR' AND nationality <> NULL
  
  For Haaland (nationality = 'NO'):
    'NO' <> 'BR' → TRUE
    'NO' <> 'AR' → TRUE
    'NO' <> NULL → UNKNOWN
    
    TRUE AND TRUE AND UNKNOWN → UNKNOWN → REJECTED ❌
  
  For Mbappe (nationality = 'FR'):
    'FR' <> 'BR' → TRUE
    'FR' <> 'AR' → TRUE
    'FR' <> NULL → UNKNOWN
    
    TRUE AND TRUE AND UNKNOWN → UNKNOWN → REJECTED ❌
  
  For Youth Prospect (nationality = NULL):
    NULL <> 'BR' → UNKNOWN
    NULL <> 'AR' → UNKNOWN
    NULL <> NULL → UNKNOWN
    
    UNKNOWN AND UNKNOWN AND UNKNOWN → UNKNOWN → REJECTED ❌
  
  Final: 0 rows
  Lost: EVERYONE!
```

### **Why It Kills Everything**

**AND logic with UNKNOWN:**
- `TRUE AND UNKNOWN` → UNKNOWN (not TRUE)
- One NULL in the list creates: `col <> NULL` for every row
- `col <> NULL` always returns UNKNOWN
- Every row gets UNKNOWN → all rows rejected

**Truth Table:**
```
TRUE AND UNKNOWN = UNKNOWN
FALSE AND UNKNOWN = FALSE
UNKNOWN AND UNKNOWN = UNKNOWN
```

### **The Fix: Handle NULL Explicitly**

```sql
WHERE nationality NOT IN ('BR', 'AR') 
   OR nationality IS NULL
```

**Or use NOT EXISTS:**
```sql
WHERE NOT EXISTS (
    SELECT 1 FROM (VALUES ('BR'), ('AR')) AS v(c)
    WHERE players.nationality = v.c
)
```

---

## 🎯 Summary: Execution Order Impact

| Killer | Critical Execution Step | Why NULLs Die |
|--------|------------------------|---------------|
| **#1** | WHERE **after** JOIN | JOIN creates NULLs → WHERE removes them |
| **#2** | WHERE predicate evaluation | `NULL <> value` → UNKNOWN → rejected |
| **#3** | Aggregate computation | Aggregates **skip NULL** by design |
| **#4** | NOT IN transformation | Creates `AND col <> NULL` → always UNKNOWN |

---

## 💡 Key Principles

1. **JOIN happens before WHERE** → NULLs created in JOIN can be killed by WHERE
2. **Only TRUE passes filters** → UNKNOWN is treated like FALSE
3. **NULL comparisons return UNKNOWN** → `NULL = x`, `NULL <> x`, `NULL > x` all → UNKNOWN
4. **AND with UNKNOWN fails** → `TRUE AND UNKNOWN` → UNKNOWN → rejected
5. **Aggregates skip NULL** → By SQL standard, not by accident

**Remember:** Understanding **when** each operation happens is the key to preventing NULL killers!
