---
title: "Supabase RLS Best Practices: Production Patterns for Secure Multi-Tenant Apps"
source: "https://makerkit.dev/blog/tutorials/supabase-rls-best-practices"
author:
  - "[[MakerKit]]"
published: 2026-07-10
created: 2026-07-21
description: "Production-grade Supabase Row Level Security patterns for building secure multi-tenant SaaS applications that won't leak data between organizations."
tags:
  - "clippings"
draft: false
---

Row Level Security (RLS) is Supabase's mechanism for enforcing data access rules at the database level. Done right, it means even a bug in your application code can't leak data across tenant boundaries. Done wrong, it's a source of subtle vulnerabilities and performance issues.

## The Core Mental Model

RLS policies are SQL expressions evaluated for each row. If the expression returns true, the user can access the row. The key function:

```sql
auth.uid()
```

This returns the UUID of the currently authenticated user. Every RLS policy in a multi-tenant app ultimately connects a row to a user via this function.

## The Tenant Isolation Pattern

For multi-tenant SaaS, you need to scope data to organizations, not just users. The standard pattern:

```sql
-- Every data table has an organization_id column
create table documents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id),
  content text,
  created_at timestamptz default now()
);

-- RLS policy: only members of the org can see its documents
create policy "Members can view org documents"
  on documents
  for select
  using (
    organization_id in (
      select organization_id
      from organization_members
      where user_id = auth.uid()
    )
  );
```

The subquery checks organization membership. Every user's data access is automatically scoped to their organizations.

## Performance: The Security Definer Function Pattern

The naive subquery approach above runs the membership lookup for every row. On large tables, this kills query performance. The solution: wrap the membership check in a `security definer` function with proper indexing.

```sql
create or replace function get_user_organization_ids()
returns setof uuid
language sql
security definer
stable
as $$
  select organization_id
  from organization_members
  where user_id = auth.uid();
$$;
```

Then use it in policies:

```sql
create policy "Members can view org documents"
  on documents
  for select
  using (organization_id = any(get_user_organization_ids()));
```

Add an index on `organization_members(user_id)` and the function is cached for the duration of the query.

## Role-Based Access Within an Organization

Most SaaS products have roles (admin, member, viewer). Encode this in your RLS policies:

```sql
-- Only admins can delete documents
create policy "Admins can delete org documents"
  on documents
  for delete
  using (
    exists (
      select 1
      from organization_members
      where user_id = auth.uid()
        and organization_id = documents.organization_id
        and role = 'admin'
    )
  );
```

## Critical Mistakes

**Mistake 1: Enabling RLS but forgetting to add policies**

```sql
alter table documents enable row level security;
-- If you stop here with no policies, ALL access is blocked by default
```

This is actually safe (deny by default) but will cause confusing errors. Always add explicit policies.

**Mistake 2: Policies that accidentally allow all authenticated users**

```sql
-- WRONG: this allows ANY authenticated user to read ALL documents
create policy "Allow authenticated"
  on documents for select
  using (auth.uid() is not null);
```

Always scope to the specific organization or ownership chain.

**Mistake 3: Not testing with a non-privileged user**

Test your RLS policies by querying as a non-admin user. The Supabase dashboard runs queries as the service role (bypasses RLS). Use the SQL editor with `set role authenticated; set request.jwt.claim.sub = '<user-uuid>';` to test real policies.

## Service Role vs Anon Key

- **Anon key**: used in client-side code, subject to RLS
- **Service role key**: bypasses RLS entirely, for server-side trusted operations

Never expose your service role key in client code. Server-side operations (webhooks, cron jobs, admin scripts) use the service role. Client-side operations always use the anon key.

## Storage RLS

Supabase Storage has its own RLS on the `storage.objects` table:

```sql
-- Users can only access files in their org's folder
create policy "Org members can access org files"
  on storage.objects
  for select
  using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] in (
      select organization_id::text
      from organization_members
      where user_id = auth.uid()
    )
  );
```

Store files at paths like `/{organization_id}/{filename}` to make storage RLS straightforward.

## Testing RLS in CI

Add RLS tests to your test suite using `pg_tap` or test via your application's API layer with seeded users. The key scenarios to cover:

1. User A cannot read User B's organization data
2. An admin can perform privileged actions; a member cannot
3. An unauthenticated request receives no data (or explicitly public data)
4. Service role can bypass RLS for admin operations
