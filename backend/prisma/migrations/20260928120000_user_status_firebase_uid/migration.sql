-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('active', 'under_review', 'deactivated');

-- AlterTable: las cuentas existentes quedan como 'active' por el DEFAULT.
ALTER TABLE "app_user" ADD COLUMN     "firebase_uid" TEXT,
ADD COLUMN     "status" "UserStatus" NOT NULL DEFAULT 'active';
