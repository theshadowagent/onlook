-- Enable the unaccent extension for search functionality
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Create base tables
CREATE TABLE account_registry (
    account_name TEXT NOT NULL,
    is_organization BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_name, is_organization)
);

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    account_name TEXT NOT NULL,
    is_organization BOOLEAN NOT NULL DEFAULT false,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    public_metadata JSONB,
    private_metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT REFERENCES users(id),
    updated_by TEXT REFERENCES users(id),
    CONSTRAINT fk_account_registry FOREIGN KEY (account_name, is_organization) 
        REFERENCES account_registry(account_name, is_organization)
);

CREATE TABLE organizations (
    id TEXT PRIMARY KEY,
    account_name TEXT NOT NULL,
    is_organization BOOLEAN NOT NULL DEFAULT true,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    public_metadata JSONB,
    private_metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT REFERENCES users(id),
    updated_by TEXT REFERENCES users(id),
    CONSTRAINT fk_account_registry FOREIGN KEY (account_name, is_organization) 
        REFERENCES account_registry(account_name, is_organization)
);

CREATE TYPE membership_role AS ENUM ('owner', 'write', 'read');

CREATE TABLE users_on_organization (
    user_id TEXT REFERENCES users(id),
    organization_id TEXT REFERENCES organizations(id),
    membership_role membership_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, organization_id)
);

CREATE TABLE feedback (
    id SERIAL PRIMARY KEY,
    mood TEXT,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create functions
CREATE OR REPLACE FUNCTION get_me()
RETURNS users
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM users WHERE id = auth.uid()::TEXT;
$$;

CREATE OR REPLACE FUNCTION get_user_by_id(user_id TEXT)
RETURNS users
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM users WHERE id = user_id;
$$;

CREATE OR REPLACE FUNCTION get_user_by_name(account_name TEXT)
RETURNS users
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM users WHERE account_name = account_name AND NOT is_organization;
$$;

CREATE OR REPLACE FUNCTION get_user_id(account_name TEXT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT id FROM users WHERE account_name = account_name AND NOT is_organization;
$$;

CREATE OR REPLACE FUNCTION get_organization_by_id(organization_id TEXT)
RETURNS organizations
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM organizations WHERE id = organization_id;
$$;

CREATE OR REPLACE FUNCTION get_organization_by_name(account_name TEXT)
RETURNS organizations
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM organizations WHERE account_name = account_name AND is_organization;
$$;

CREATE OR REPLACE FUNCTION get_organization_id(account_name TEXT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT id FROM organizations WHERE account_name = account_name AND is_organization;
$$;

CREATE OR REPLACE FUNCTION create_organization(
    account_name TEXT,
    display_name TEXT DEFAULT NULL,
    bio TEXT DEFAULT NULL
)
RETURNS SETOF organizations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO account_registry (account_name, is_organization)
    VALUES (account_name, true);

    RETURN QUERY
        INSERT INTO organizations (id, account_name, is_organization, display_name, bio, created_by)
        VALUES (gen_random_uuid()::TEXT, account_name, true, display_name, bio, auth.uid()::TEXT)
        RETURNING *;
END;
$$;

CREATE OR REPLACE FUNCTION update_organization(
    organization_id TEXT,
    display_name TEXT DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    public_metadata JSONB DEFAULT NULL,
    replace_metadata BOOLEAN DEFAULT false
)
RETURNS SETOF organizations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
        UPDATE organizations
        SET 
            display_name = COALESCE(update_organization.display_name, organizations.display_name),
            bio = COALESCE(update_organization.bio, organizations.bio),
            public_metadata = CASE 
                WHEN update_organization.public_metadata IS NULL THEN organizations.public_metadata
                WHEN replace_metadata THEN update_organization.public_metadata
                ELSE organizations.public_metadata || update_organization.public_metadata
            END,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = auth.uid()::TEXT
        WHERE id = organization_id
        RETURNING *;
END;
$$;

CREATE OR REPLACE FUNCTION delete_organization(organization_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM organizations WHERE id = organization_id;
    RETURN FOUND;
END;
$$;

-- Add more functions as needed for search_organizations, search_users, 
-- get_organization_users, update_user_on_organization, etc.

-- Create indexes for better performance
CREATE INDEX idx_users_account_name ON users(account_name);
CREATE INDEX idx_organizations_account_name ON organizations(account_name);
CREATE INDEX idx_users_on_organization_org_id ON users_on_organization(organization_id);
CREATE INDEX idx_users_on_organization_user_id ON users_on_organization(user_id);
