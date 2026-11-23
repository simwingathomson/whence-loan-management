import { NextRequest,NextResponse } from "next/server";
import { z } from "zod";
import { recordPayment } from "@/lib/payments";
const schema=z.object({reference:z.string().min(1),loanId:z.string().min(1),amount:z.string().regex(/^\d+(\.\d{1,2})?$/),method:z.string().min(1),paidAt:z.coerce.date(),installmentId:z.string().optional()});
export async function POST(request:NextRequest){try{return NextResponse.json(await recordPayment(schema.parse(await request.json())),{status:201})}catch(error){return NextResponse.json({error:error instanceof Error?error.message:"Unable to record payment"},{status:400})}}
