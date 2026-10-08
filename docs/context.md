# Domain Context & Ubiquitous Language

> Canonical domain definitions and anti-synonym enforcement.
> Prevents LLM naming drift (`customer` vs `client`, `item` vs `product`).
> All agents must follow these terms strictly.

---

## Structure

Define your domain using these three tables:

### Table 1: Canonical Entities
| Entity Name | Definition | Key Fields |
|-------------|------------|------------|
| (example) `User` | Registered account with login credentials | `id`, `email`, `role` |

### Table 2: Entity Lifecycles
| Entity | Valid States | Allowed Transitions | Terminal States |
|--------|--------------|---------------------|-----------------|
| (example) `Order` | `draft`, `pending`, `shipped`, `delivered`, `cancelled` | `draft->pending->shipped->delivered` OR `*->cancelled` | `delivered`, `cancelled` |

### Table 3: Anti-Synonyms
| Canonical Term (USE THIS) | FORBIDDEN Synonyms (NEVER USE) | Context |
|---------------------------|--------------------------------|---------|
| (example) `customer` | `client`, `buyer`, `shopper` | Commerce context |

---

## Fill Instructions

On first task or when the domain is established, fill the tables above with your project's actual entities, lifecycle states, and forbidden synonym mappings.
