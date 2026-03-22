-- ComplianceKit: Initial Schema
-- 9 tables + RLS + indexes + triggers

-- =============================================================================
-- Helper function: get current user's org_id
-- =============================================================================
CREATE OR REPLACE FUNCTION public.get_user_org_id()
RETURNS uuid AS $$
  SELECT org_id FROM public.users WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =============================================================================
-- Helper function: auto-update updated_at column
-- =============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Table: organizations
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  plan text CHECK (plan IN ('starter', 'growth')),
  stripe_customer_id text,
  stripe_subscription_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own org"
  ON public.organizations FOR SELECT
  USING (id = public.get_user_org_id());

CREATE POLICY "Owners and admins can update their org"
  ON public.organizations FOR UPDATE
  USING (id = public.get_user_org_id())
  WITH CHECK (id = public.get_user_org_id());

CREATE TRIGGER set_organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Table: users
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view members of their org"
  ON public.users FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Owners and admins can insert users into their org"
  ON public.users FOR INSERT
  WITH CHECK (
    org_id = public.get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE INDEX idx_users_org_id ON public.users(org_id);

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Table: integrations
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('okta', 'aws', 'github', 'google')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'error', 'disconnected')),
  vault_secret_id uuid,
  config jsonb,
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, provider)
);

ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org integrations"
  ON public.integrations FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert integrations for their org"
  ON public.integrations FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their org integrations"
  ON public.integrations FOR UPDATE
  USING (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can delete their org integrations"
  ON public.integrations FOR DELETE
  USING (org_id = public.get_user_org_id());

CREATE INDEX idx_integrations_org_id ON public.integrations(org_id);

CREATE TRIGGER set_integrations_updated_at
  BEFORE UPDATE ON public.integrations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Table: controls (shared reference table — no org_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.controls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  control_id text UNIQUE NOT NULL,
  title text NOT NULL,
  description text,
  category text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view controls"
  ON public.controls FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- No INSERT/UPDATE/DELETE policies — managed by service role only

-- =============================================================================
-- Table: org_controls
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.org_controls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  control_id uuid NOT NULL REFERENCES public.controls(id),
  status text NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'compliant', 'non_compliant')),
  assigned_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, control_id)
);

ALTER TABLE public.org_controls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org controls"
  ON public.org_controls FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert controls for their org"
  ON public.org_controls FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their org controls"
  ON public.org_controls FOR UPDATE
  USING (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can delete their org controls"
  ON public.org_controls FOR DELETE
  USING (org_id = public.get_user_org_id());

CREATE INDEX idx_org_controls_org_id ON public.org_controls(org_id);

CREATE TRIGGER set_org_controls_updated_at
  BEFORE UPDATE ON public.org_controls
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Table: evidence
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  org_control_id uuid NOT NULL REFERENCES public.org_controls(id) ON DELETE CASCADE,
  integration_id uuid REFERENCES public.integrations(id) ON DELETE SET NULL,
  evidence_type text NOT NULL CHECK (evidence_type IN ('automated', 'manual', 'screenshot')),
  title text NOT NULL,
  data jsonb,
  file_path text,
  collected_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.evidence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org evidence"
  ON public.evidence FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert evidence for their org"
  ON public.evidence FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their org evidence"
  ON public.evidence FOR UPDATE
  USING (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can delete their org evidence"
  ON public.evidence FOR DELETE
  USING (org_id = public.get_user_org_id());

CREATE INDEX idx_evidence_org_id ON public.evidence(org_id);
CREATE INDEX idx_evidence_org_control_id ON public.evidence(org_control_id);

-- =============================================================================
-- Table: policies
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  policy_type text NOT NULL,
  title text NOT NULL,
  content text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'approved')),
  version integer NOT NULL DEFAULT 1,
  control_ids text[],
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org policies"
  ON public.policies FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert policies for their org"
  ON public.policies FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their org policies"
  ON public.policies FOR UPDATE
  USING (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can delete their org policies"
  ON public.policies FOR DELETE
  USING (org_id = public.get_user_org_id());

CREATE INDEX idx_policies_org_id ON public.policies(org_id);

CREATE TRIGGER set_policies_updated_at
  BEFORE UPDATE ON public.policies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Table: gap_assessments
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.gap_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  score numeric(5,2) NOT NULL,
  total_controls integer NOT NULL,
  compliant_controls integer NOT NULL,
  top_gaps jsonb,
  ai_narrative text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.gap_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org gap assessments"
  ON public.gap_assessments FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert gap assessments for their org"
  ON public.gap_assessments FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can update their org gap assessments"
  ON public.gap_assessments FOR UPDATE
  USING (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE POLICY "Users can delete their org gap assessments"
  ON public.gap_assessments FOR DELETE
  USING (org_id = public.get_user_org_id());

CREATE INDEX idx_gap_assessments_org_id ON public.gap_assessments(org_id);

-- =============================================================================
-- Table: sync_logs
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.sync_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  integration_id uuid NOT NULL REFERENCES public.integrations(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('started', 'completed', 'failed')),
  records_synced integer DEFAULT 0,
  error_message text,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE public.sync_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their org sync logs"
  ON public.sync_logs FOR SELECT
  USING (org_id = public.get_user_org_id());

CREATE POLICY "Users can insert sync logs for their org"
  ON public.sync_logs FOR INSERT
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX idx_sync_logs_org_id ON public.sync_logs(org_id);
CREATE INDEX idx_sync_logs_integration_id ON public.sync_logs(integration_id);
