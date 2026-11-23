import { NextRequest,NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
export async function GET(request:NextRequest){if(request.headers.get("authorization")!==`Bearer ${process.env.CRON_SECRET}`)return new NextResponse("Unauthorized",{status:401});const now=new Date();const count=await prisma.notification.updateMany({where:{scheduledFor:{lte:now},sentAt:null},data:{sentAt:now}});return NextResponse.json({processed:count.count})}
