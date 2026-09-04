-- Las tablas auxiliares/internas pasan a usar id entero autoincremental en
-- vez de uuid (mejor rendimiento en joins/índices, sin riesgo de exposición
-- porque nunca se usan para autorización). Las entidades principales
-- (AppUser, Post, etc.) mantienen uuid porque sus ids se exponen al cliente
-- y un entero secuencial haría trivial enumerarlos.
--
-- Estas tablas solo tenían datos de seed/dev (que prisma/seed.js recrea en
-- cada corrida), así que se vaciaron antes de esta migración en vez de
-- intentar un cast uuid->int.

-- Elimina los FKs que referencian las columnas que cambian de tipo.
ALTER TABLE "category_hierarchy" DROP CONSTRAINT IF EXISTS "category_hierarchy_general_category_id_fkey";
ALTER TABLE "category_hierarchy" DROP CONSTRAINT IF EXISTS "category_hierarchy_specific_category_id_fkey";
ALTER TABLE "worker_category" DROP CONSTRAINT IF EXISTS "worker_category_general_category_id_fkey";
ALTER TABLE "post_category" DROP CONSTRAINT IF EXISTS "post_category_specific_category_id_fkey";

-- general_category: uuid -> serial (autoincremental)
ALTER TABLE "general_category" DROP CONSTRAINT IF EXISTS "general_category_pkey";
ALTER TABLE "general_category" DROP COLUMN "id";
ALTER TABLE "general_category" ADD COLUMN "id" SERIAL NOT NULL;
ALTER TABLE "general_category" ADD CONSTRAINT "general_category_pkey" PRIMARY KEY ("id");

-- specific_category: uuid -> serial (autoincremental)
ALTER TABLE "specific_category" DROP CONSTRAINT IF EXISTS "specific_category_pkey";
ALTER TABLE "specific_category" DROP COLUMN "id";
ALTER TABLE "specific_category" ADD COLUMN "id" SERIAL NOT NULL;
ALTER TABLE "specific_category" ADD CONSTRAINT "specific_category_pkey" PRIMARY KEY ("id");

-- category_hierarchy: columnas FK -> integer, vuelven a apuntar a los nuevos ids
ALTER TABLE "category_hierarchy" DROP CONSTRAINT IF EXISTS "category_hierarchy_pkey";
TRUNCATE TABLE "category_hierarchy";
ALTER TABLE "category_hierarchy" ALTER COLUMN "general_category_id" TYPE INTEGER USING NULL;
ALTER TABLE "category_hierarchy" ALTER COLUMN "specific_category_id" TYPE INTEGER USING NULL;
ALTER TABLE "category_hierarchy" ADD CONSTRAINT "category_hierarchy_pkey" PRIMARY KEY ("general_category_id", "specific_category_id");
ALTER TABLE "category_hierarchy" ADD CONSTRAINT "category_hierarchy_general_category_id_fkey" FOREIGN KEY ("general_category_id") REFERENCES "general_category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "category_hierarchy" ADD CONSTRAINT "category_hierarchy_specific_category_id_fkey" FOREIGN KEY ("specific_category_id") REFERENCES "specific_category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- worker_category: columna FK -> integer
TRUNCATE TABLE "worker_category";
ALTER TABLE "worker_category" ALTER COLUMN "general_category_id" TYPE INTEGER USING NULL;
ALTER TABLE "worker_category" ADD CONSTRAINT "worker_category_general_category_id_fkey" FOREIGN KEY ("general_category_id") REFERENCES "general_category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- post_category: columna FK -> integer
TRUNCATE TABLE "post_category";
ALTER TABLE "post_category" ALTER COLUMN "specific_category_id" TYPE INTEGER USING NULL;
ALTER TABLE "post_category" ADD CONSTRAINT "post_category_specific_category_id_fkey" FOREIGN KEY ("specific_category_id") REFERENCES "specific_category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- post_photo: uuid -> serial (ninguna otra tabla lo referencia)
ALTER TABLE "post_photo" DROP CONSTRAINT IF EXISTS "post_photo_pkey";
ALTER TABLE "post_photo" DROP COLUMN "id";
ALTER TABLE "post_photo" ADD COLUMN "id" SERIAL NOT NULL;
ALTER TABLE "post_photo" ADD CONSTRAINT "post_photo_pkey" PRIMARY KEY ("id");

-- dispute_evidence: uuid -> serial (ninguna otra tabla lo referencia)
ALTER TABLE "dispute_evidence" DROP CONSTRAINT IF EXISTS "dispute_evidence_pkey";
ALTER TABLE "dispute_evidence" DROP COLUMN "id";
ALTER TABLE "dispute_evidence" ADD COLUMN "id" SERIAL NOT NULL;
ALTER TABLE "dispute_evidence" ADD CONSTRAINT "dispute_evidence_pkey" PRIMARY KEY ("id");

-- balance_movement: uuid -> serial (ninguna otra tabla lo referencia)
ALTER TABLE "balance_movement" DROP CONSTRAINT IF EXISTS "balance_movement_pkey";
ALTER TABLE "balance_movement" DROP COLUMN "id";
ALTER TABLE "balance_movement" ADD COLUMN "id" SERIAL NOT NULL;
ALTER TABLE "balance_movement" ADD CONSTRAINT "balance_movement_pkey" PRIMARY KEY ("id");

-- Tabla auxiliar nueva: ubicaciones del Urabá antioqueño.
CREATE TABLE "location" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "location_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "location_name_key" ON "location"("name");
