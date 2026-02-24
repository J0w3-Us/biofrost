-- Ejecutar en el SQL Editor del Dashboard de Supabase
-- https://supabase.com/dashboard/project/zhnufraaybrruqdtgbwj/sql

CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_avatar_url TEXT,
  text TEXT NOT NULL CHECK (char_length(text) >= 3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS comments_project_id_idx ON public.comments (project_id);
CREATE INDEX IF NOT EXISTS comments_created_at_idx ON public.comments (created_at DESC);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede leer comentarios
CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT USING (true);

-- Cualquiera puede insertar (la app controla autenticación)
CREATE POLICY "comments_insert_all" ON public.comments
  FOR INSERT WITH CHECK (true);
