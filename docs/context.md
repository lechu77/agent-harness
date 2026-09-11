# Domain Context & Ubiquitous Language

> Canonical domain definitions, entity lifecycles, and anti-synonym rules.
> All agents (Leader, Implementer, Reviewer) must adhere strictly to these terms.
> Deviations cause cascading hallucination and naming drift across agent sessions.

---

## 1. Canonical Entities

Define the primary business models and objects. Every entity must have one canonical name used everywhere in code, schemas, and tests.

| Entity Name | Definition | Key Identifiers / Core Fields |
|-------------|------------|-------------------------------|
| `User`      | Registered account with login credentials     | `id`, `email`, `role`, `created_at` |
| `Item`      | Core domain resource managed in the system     | `id`, `owner_id`, `status`, `name` |

---

## 2. Entity Lifecycles & Valid States

Define the exact lifecycle states and permissible state transitions for each stateful entity. State transitions not explicitly permitted here are considered invalid.

### `Item` Lifecycle

```text
[ draft ] ──> [ pending ] ──> [ active ] ──> [ archived ]
                   │
                   └───> [ rejected ]
```

| Entity | Valid States | Allowed Transitions | Terminal States |
|--------|--------------|---------------------|-----------------|
| `Item` | `draft`, `pending`, `active`, `archived`, `rejected` | `draft -> pending`<br>`pending -> active`<br>`pending -> rejected`<br>`active -> archived` | `archived`, `rejected` |

---

## 3. Anti-Synonym & Disambiguation Rules

> **Strict Rule**: LLMs frequently invent synonyms (e.g., swapping `client` for `customer`).
> The terms in the "FORBIDDEN Synonyms" column MUST NEVER appear in code, variable names, database columns, API routes, or test cases for the given context.

| Canonical Term (USE THIS) | FORBIDDEN Synonyms (DO NOT USE) | Context / Scope |
|---------------------------|---------------------------------|-----------------|
| `customer`                | `client`, `buyer`, `shopper`    | Commerce & billing context |
| `user`                    | `member`, `account`, `person`   | Authentication & identity context |
| `workspace`               | `tenant`, `org`, `team`         | Multi-tenant scoping |
| `item`                    | `product`, `article`, `entry`   | Domain inventory context |

---

## 4. Boundary & Relationship Rules

- [Entity A] belongs to exactly one [Entity B].
- Deleting an [Entity B] cascades to [Entity A] (or marks as archived).
- No circular dependencies between domain modules.
