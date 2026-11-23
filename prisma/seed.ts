import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const district = await prisma.district.upsert({ where: { name: "Lusaka" }, update: {}, create: { name: "Lusaka" } });
  const agent = await prisma.loanAgent.upsert({ where: { code: "AG-001" }, update: {}, create: { code: "AG-001", name: "Demo Agent", districtId: district.id } });
  const client = await prisma.client.upsert({
    where: { clientNumber: "CL-0001" }, update: {},
    create: { clientNumber: "CL-0001", firstName: "Demo", lastName: "Client", districtId: district.id, agentId: agent.id },
  });
  const issuedAt = new Date();
  const dueAt = new Date(issuedAt);
  dueAt.setMonth(dueAt.getMonth() + 2);
  const loan = await prisma.loan.upsert({
    where: { loanNumber: "LN-DEMO-001" }, update: {},
    create: {
      loanNumber: "LN-DEMO-001", clientId: client.id, agentId: agent.id, principal: "1000.00", interestRate: "10.0000",
      totalDue: "1100.00", outstandingBalance: "1100.00", issuedAt, dueAt,
      installments: { create: [
        { sequence: 1, dueDate: new Date(issuedAt.getFullYear(), issuedAt.getMonth() + 1, issuedAt.getDate()), amountDue: "550.00", balance: "550.00" },
        { sequence: 2, dueDate: dueAt, amountDue: "550.00", balance: "550.00" },
      ] },
    },
  });
  await prisma.companySettings.upsert({ where: { id: "default" }, update: {}, create: { id: "default", companyName: "WHENCE Loans", currency: "ZMW" } });
  console.log(`Seeded ${loan.loanNumber}`);
}

main().finally(() => prisma.$disconnect());
