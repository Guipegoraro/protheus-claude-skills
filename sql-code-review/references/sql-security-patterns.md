# SQL Security Patterns

## SQL Injection Prevention

```sql
-- ❌ CRITICAL: SQL Injection vulnerability
query = "SELECT * FROM users WHERE id = " + userInput;
query = f"DELETE FROM orders WHERE user_id = {user_id}";

-- ✅ SECURE: Parameterized queries
-- PostgreSQL (ANSI SQL)
PREPARE stmt FROM 'SELECT * FROM users WHERE id = ?';
EXECUTE stmt USING @user_id;

-- SQL Server
EXEC sp_executesql N'SELECT * FROM users WHERE id = @id', N'@id INT', @id = @user_id;
```

## Access Control & Permissions

- **Principle of Least Privilege**: Grant minimum required permissions
- **Role-Based Access**: Use database roles instead of direct user permissions
- **Schema Security**: Proper schema ownership and access controls
- **Function/Procedure Security**: Review DEFINER vs INVOKER rights

### Examples

```sql
-- ❌ BAD: Over-permissioned
GRANT ALL PRIVILEGES ON database.* TO 'app_user'@'%';

-- ✅ GOOD: Principle of least privilege
GRANT SELECT, INSERT, UPDATE ON database.orders TO 'order_service'@'app-server';
GRANT SELECT ON database.products TO 'order_service'@'app-server';
```

## Data Protection

- **Sensitive Data Exposure**: Avoid SELECT * on tables with sensitive columns
- **Audit Logging**: Ensure sensitive operations are logged
- **Data Masking**: Use views or functions to mask sensitive data
- **Encryption**: Verify encrypted storage for sensitive data

### Examples

```sql
-- ❌ BAD: Exposing sensitive data
SELECT * FROM users;  -- includes password_hash, ssn, etc.

-- ✅ GOOD: Select only needed columns, mask sensitive data
SELECT id, name, email,
       CONCAT('***-**-', RIGHT(ssn, 4)) AS masked_ssn
FROM users;

-- ✅ GOOD: Use a view to enforce data masking
CREATE VIEW public_users AS
SELECT id, name, email
FROM users;
```

## Security Review Patterns

### Dynamic SQL Review

When reviewing dynamic SQL, flag these patterns:

| Pattern | Risk Level | Issue |
| --- | --- | --- |
| String concatenation with user input | **CRITICAL** | Direct SQL injection |
| `EXEC(@sql)` without parameterization | **HIGH** | SQL injection via dynamic SQL |
| `SELECT *` on tables with sensitive columns | **MEDIUM** | Data exposure |
| Missing `WHERE` clause on `UPDATE`/`DELETE` | **HIGH** | Accidental data loss |
| Hardcoded credentials in SQL scripts | **CRITICAL** | Credential exposure |
| `GRANT ALL` or over-broad permissions | **MEDIUM** | Excessive privilege |

### Parameterization Checklist

- [ ] All user-supplied values use bind parameters
- [ ] Dynamic table/column names are validated against a whitelist
- [ ] Stored procedures use `sp_executesql` (SQL Server) or `EXECUTE ... USING` (PostgreSQL) for dynamic SQL
- [ ] No string interpolation (`f"..."`, `"..." + var`, `CONCAT(...)`) builds WHERE/ORDER clauses from user input
