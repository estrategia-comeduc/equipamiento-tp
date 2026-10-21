-- ============================================================
-- Equipamiento TP — Esquema Supabase
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Tabla principal: una fila por establecimiento (RBD)
CREATE TABLE IF NOT EXISTS public.schools (
  rbd         TEXT PRIMARY KEY,          -- Código RBD del establecimiento
  data        JSONB NOT NULL DEFAULT '{}', -- Todos los campos del formulario
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para búsquedas rápidas por fecha
CREATE INDEX IF NOT EXISTS schools_updated_idx ON public.schools (updated_at DESC);

-- Actualiza updated_at automáticamente al hacer UPSERT
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS schools_updated_at ON public.schools;
CREATE TRIGGER schools_updated_at
  BEFORE INSERT OR UPDATE ON public.schools
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

-- Política de lectura: cualquier visitante (anon) puede leer
CREATE POLICY "lectura_publica" ON public.schools
  FOR SELECT USING (true);

-- Política de escritura: sólo usuarios autenticados
-- (en tu app sólo el administrador inicia sesión con Supabase Auth)
CREATE POLICY "escritura_autenticados" ON public.schools
  FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================
-- Realtime
-- Activa la publicación de cambios en la tabla para que el
-- front-end reciba actualizaciones en vivo sin recargar.
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.schools;
