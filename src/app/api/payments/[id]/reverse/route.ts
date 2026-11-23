import { NextRequest,NextResponse } from "next/server";
import { reversePayment } from "@/lib/payments";
export async function POST(request:NextRequest,{params}:{params:Promise<{id:string}>}){try{const {reason}=await request.json();await reversePayment((await params).id,String(reason||"Reversed"));return NextResponse.json({ok:true})}catch(error){return NextResponse.json({error:error instanceof Error?error.message:"Unable to reverse payment"},{status:400})}}
