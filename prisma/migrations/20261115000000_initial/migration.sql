CREATE TYPE "LoanStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'DEFAULTED', 'WRITTEN_OFF');
CREATE TYPE "InstallmentStatus" AS ENUM ('PENDING', 'PARTIAL', 'PAID', 'OVERDUE');
CREATE TYPE "PaymentStatus" AS ENUM ('POSTED', 'REVERSED');

CREATE TABLE "District" (
  "id" TEXT NOT NULL, "name" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "District_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "LoanAgent" (
  "id" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL, "phone" TEXT, "districtId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "LoanAgent_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Client" (
  "id" TEXT NOT NULL, "clientNumber" TEXT NOT NULL, "firstName" TEXT NOT NULL, "lastName" TEXT NOT NULL,
  "phone" TEXT, "nationalId" TEXT, "address" TEXT, "districtId" TEXT NOT NULL, "agentId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Client_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Loan" (
  "id" TEXT NOT NULL, "loanNumber" TEXT NOT NULL, "clientId" TEXT NOT NULL, "agentId" TEXT,
  "principal" DECIMAL(14,2) NOT NULL, "interestRate" DECIMAL(7,4) NOT NULL, "totalDue" DECIMAL(14,2) NOT NULL,
  "outstandingBalance" DECIMAL(14,2) NOT NULL, "issuedAt" TIMESTAMP(3) NOT NULL, "dueAt" TIMESTAMP(3) NOT NULL,
  "status" "LoanStatus" NOT NULL DEFAULT 'ACTIVE', "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Loan_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "RepaymentInstallment" (
  "id" TEXT NOT NULL, "loanId" TEXT NOT NULL, "sequence" INTEGER NOT NULL, "dueDate" TIMESTAMP(3) NOT NULL,
  "amountDue" DECIMAL(14,2) NOT NULL, "amountPaid" DECIMAL(14,2) NOT NULL DEFAULT 0,
  "balance" DECIMAL(14,2) NOT NULL, "status" "InstallmentStatus" NOT NULL DEFAULT 'PENDING',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "RepaymentInstallment_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Payment" (
  "id" TEXT NOT NULL, "reference" TEXT NOT NULL, "loanId" TEXT NOT NULL, "amount" DECIMAL(14,2) NOT NULL,
  "paidAt" TIMESTAMP(3) NOT NULL, "method" TEXT NOT NULL, "status" "PaymentStatus" NOT NULL DEFAULT 'POSTED',
  "reversedAt" TIMESTAMP(3), "reversalReason" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL, CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "PaymentAllocation" (
  "id" TEXT NOT NULL, "paymentId" TEXT NOT NULL, "installmentId" TEXT NOT NULL, "amount" DECIMAL(14,2) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "PaymentAllocation_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Notification" (
  "id" TEXT NOT NULL, "clientId" TEXT, "type" TEXT NOT NULL, "message" TEXT NOT NULL,
  "scheduledFor" TIMESTAMP(3) NOT NULL, "sentAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AuditLog" (
  "id" TEXT NOT NULL, "entityType" TEXT NOT NULL, "entityId" TEXT NOT NULL, "action" TEXT NOT NULL,
  "before" JSONB, "after" JSONB, "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "CompanySettings" (
  "id" TEXT NOT NULL DEFAULT 'default', "companyName" TEXT NOT NULL, "currency" TEXT NOT NULL DEFAULT 'ZMW',
  "notificationHour" INTEGER NOT NULL DEFAULT 8, "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "CompanySettings_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "District_name_key" ON "District"("name");
CREATE UNIQUE INDEX "LoanAgent_code_key" ON "LoanAgent"("code");
CREATE UNIQUE INDEX "LoanAgent_phone_key" ON "LoanAgent"("phone");
CREATE UNIQUE INDEX "Client_clientNumber_key" ON "Client"("clientNumber");
CREATE UNIQUE INDEX "Client_phone_key" ON "Client"("phone");
CREATE UNIQUE INDEX "Client_nationalId_key" ON "Client"("nationalId");
CREATE UNIQUE INDEX "Loan_loanNumber_key" ON "Loan"("loanNumber");
CREATE UNIQUE INDEX "RepaymentInstallment_loanId_sequence_key" ON "RepaymentInstallment"("loanId", "sequence");
CREATE UNIQUE INDEX "Payment_reference_key" ON "Payment"("reference");
CREATE UNIQUE INDEX "PaymentAllocation_paymentId_installmentId_key" ON "PaymentAllocation"("paymentId", "installmentId");
CREATE INDEX "LoanAgent_districtId_idx" ON "LoanAgent"("districtId");
CREATE INDEX "Client_districtId_agentId_idx" ON "Client"("districtId", "agentId");
CREATE INDEX "Loan_clientId_status_idx" ON "Loan"("clientId", "status");
CREATE INDEX "Loan_agentId_status_idx" ON "Loan"("agentId", "status");
CREATE INDEX "Loan_dueAt_status_idx" ON "Loan"("dueAt", "status");
CREATE INDEX "RepaymentInstallment_loanId_dueDate_idx" ON "RepaymentInstallment"("loanId", "dueDate");
CREATE INDEX "RepaymentInstallment_dueDate_status_idx" ON "RepaymentInstallment"("dueDate", "status");
CREATE INDEX "Payment_loanId_status_paidAt_idx" ON "Payment"("loanId", "status", "paidAt");
CREATE INDEX "PaymentAllocation_installmentId_idx" ON "PaymentAllocation"("installmentId");
CREATE INDEX "Notification_clientId_scheduledFor_idx" ON "Notification"("clientId", "scheduledFor");
CREATE INDEX "Notification_scheduledFor_sentAt_idx" ON "Notification"("scheduledFor", "sentAt");
CREATE INDEX "AuditLog_entityType_entityId_occurredAt_idx" ON "AuditLog"("entityType", "entityId", "occurredAt");

ALTER TABLE "LoanAgent" ADD CONSTRAINT "LoanAgent_districtId_fkey" FOREIGN KEY ("districtId") REFERENCES "District"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Client" ADD CONSTRAINT "Client_districtId_fkey" FOREIGN KEY ("districtId") REFERENCES "District"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Client" ADD CONSTRAINT "Client_agentId_fkey" FOREIGN KEY ("agentId") REFERENCES "LoanAgent"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Loan" ADD CONSTRAINT "Loan_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Loan" ADD CONSTRAINT "Loan_agentId_fkey" FOREIGN KEY ("agentId") REFERENCES "LoanAgent"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "RepaymentInstallment" ADD CONSTRAINT "RepaymentInstallment_loanId_fkey" FOREIGN KEY ("loanId") REFERENCES "Loan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_loanId_fkey" FOREIGN KEY ("loanId") REFERENCES "Loan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PaymentAllocation" ADD CONSTRAINT "PaymentAllocation_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PaymentAllocation" ADD CONSTRAINT "PaymentAllocation_installmentId_fkey" FOREIGN KEY ("installmentId") REFERENCES "RepaymentInstallment"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE SET NULL ON UPDATE CASCADE;
