import { InstallmentStatus, PaymentStatus, Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";

type PaymentInput = {
  reference: string;
  loanId: string;
  amount: string;
  method: string;
  paidAt: Date;
  installmentId?: string;
};

const zero = new Prisma.Decimal(0);
const money = (value: Prisma.Decimal) => value.toDecimalPlaces(2);

const serializePayment = (payment: { reference: string; amount: Prisma.Decimal; method: string; paidAt: Date; status: PaymentStatus }) => ({
  reference: payment.reference,
  amount: payment.amount.toFixed(2),
  method: payment.method,
  paidAt: payment.paidAt.toISOString(),
  status: payment.status,
});

async function createAllocations(tx: Prisma.TransactionClient, loanId: string, paymentId: string, amount: Prisma.Decimal, installmentId?: string) {
  const installments = await tx.repaymentInstallment.findMany({
    where: { loanId, balance: { gt: zero } },
    orderBy: { sequence: "asc" },
  });
  if (installmentId) {
    const index = installments.findIndex((installment) => installment.id === installmentId);
    if (index === -1) throw new Error("The selected installment does not belong to this loan or is already paid");
    installments.splice(0, installments.length, ...installments.slice(index));
  }

  let remaining = amount;
  const allocations: { paymentId: string; installmentId: string; amount: Prisma.Decimal }[] = [];
  for (const installment of installments) {
    if (remaining.lte(zero)) break;
    const allocation = Prisma.Decimal.min(remaining, installment.balance);
    allocations.push({ paymentId, installmentId: installment.id, amount: money(allocation) });
    remaining = remaining.minus(allocation);
  }
  if (remaining.gt(zero)) throw new Error("Payment exceeds the loan's remaining installment balance");
  await tx.paymentAllocation.createMany({ data: allocations });
}

async function syncInstallments(tx: Prisma.TransactionClient, loanId: string) {
  const installments = await tx.repaymentInstallment.findMany({ where: { loanId }, orderBy: { sequence: "asc" } });
  const totals = await tx.paymentAllocation.groupBy({
    by: ["installmentId"],
    where: { payment: { status: PaymentStatus.POSTED }, installment: { loanId } },
    _sum: { amount: true },
  });
  const paidByInstallment = new Map(totals.map((total) => [total.installmentId, money(total._sum.amount ?? zero)]));
  await Promise.all(installments.map((installment) => {
    const amountPaid = paidByInstallment.get(installment.id) ?? zero;
    const balance = money(Prisma.Decimal.max(zero, installment.amountDue.minus(amountPaid)));
    return tx.repaymentInstallment.update({
      where: { id: installment.id },
      data: {
        amountPaid: money(amountPaid),
        balance,
        status: amountPaid.greaterThanOrEqualTo(installment.amountDue)
          ? InstallmentStatus.PAID
          : amountPaid.gt(zero) ? InstallmentStatus.PARTIAL : InstallmentStatus.PENDING,
      },
    });
  }));
}

async function reconcileLoan(tx: Prisma.TransactionClient, loanId: string) {
  const [loan, payments] = await Promise.all([
    tx.loan.findUniqueOrThrow({ where: { id: loanId } }),
    tx.payment.aggregate({ where: { loanId, status: PaymentStatus.POSTED }, _sum: { amount: true } }),
  ]);
  const paid = money(payments._sum.amount ?? zero);
  const outstandingBalance = money(Prisma.Decimal.max(zero, loan.totalDue.minus(paid)));
  await tx.loan.update({
    where: { id: loanId },
    data: { outstandingBalance, status: outstandingBalance.isZero() ? "COMPLETED" : "ACTIVE" },
  });
}

function paymentAmount(value: string) {
  const amount = new Prisma.Decimal(value);
  if (amount.lte(zero)) throw new Error("Payment amount must be positive");
  return money(amount);
}

export async function recordPayment(input: PaymentInput) {
  return prisma.$transaction(async (tx) => {
    const amount = paymentAmount(input.amount);
    await tx.loan.findUniqueOrThrow({ where: { id: input.loanId } });
    const payment = await tx.payment.create({
      data: { reference: input.reference, loanId: input.loanId, amount, method: input.method, paidAt: input.paidAt },
    });
    await createAllocations(tx, input.loanId, payment.id, amount, input.installmentId);
    await syncInstallments(tx, input.loanId);
    await reconcileLoan(tx, input.loanId);
    await tx.auditLog.create({ data: { entityType: "Payment", entityId: payment.id, action: "CREATED", after: serializePayment(payment) } });
    return payment;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

export async function editPayment(id: string, input: PaymentInput) {
  return prisma.$transaction(async (tx) => {
    const previous = await tx.payment.findUniqueOrThrow({ where: { id } });
    if (previous.status === PaymentStatus.REVERSED) throw new Error("A reversed payment cannot be edited");
    if (previous.loanId !== input.loanId) throw new Error("A payment cannot be moved to another loan");
    const amount = paymentAmount(input.amount);
    await tx.paymentAllocation.deleteMany({ where: { paymentId: id } });
    await syncInstallments(tx, input.loanId);
    const payment = await tx.payment.update({
      where: { id },
      data: { reference: input.reference, amount, method: input.method, paidAt: input.paidAt },
    });
    await createAllocations(tx, input.loanId, id, amount, input.installmentId);
    await syncInstallments(tx, input.loanId);
    await reconcileLoan(tx, input.loanId);
    await tx.auditLog.create({ data: { entityType: "Payment", entityId: id, action: "UPDATED", before: serializePayment(previous), after: serializePayment(payment) } });
    return payment;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

export async function reversePayment(id: string, reason: string) {
  return prisma.$transaction(async (tx) => {
    const previous = await tx.payment.findUniqueOrThrow({ where: { id } });
    if (previous.status === PaymentStatus.REVERSED) throw new Error("Payment already reversed");
    const payment = await tx.payment.update({
      where: { id },
      data: { status: PaymentStatus.REVERSED, reversedAt: new Date(), reversalReason: reason },
    });
    await syncInstallments(tx, payment.loanId);
    await reconcileLoan(tx, payment.loanId);
    await tx.auditLog.create({ data: { entityType: "Payment", entityId: id, action: "REVERSED", before: serializePayment(previous), after: serializePayment(payment) } });
    return payment;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}
