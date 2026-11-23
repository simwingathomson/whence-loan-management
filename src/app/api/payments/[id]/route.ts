import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { editPayment } from "@/lib/payments";

const schema = z.object({
  reference: z.string().min(1),
  loanId: z.string().min(1),
  amount: z.string().regex(/^\d+(\.\d{1,2})?$/),
  method: z.string().min(1),
  paidAt: z.coerce.date(),
  installmentId: z.string().optional(),
});

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    return NextResponse.json(await editPayment(id, schema.parse(await request.json())));
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Unable to update payment" }, { status: 400 });
  }
}
