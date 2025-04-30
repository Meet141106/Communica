import "https://deno.land/std@0.224.0/dotenv/load.ts"; // Load environment variables
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import nodemailer from "npm:nodemailer"; // Use Node.js module directly in Deno 2.0

console.log("✅ Supabase Edge Function: send-otp started!");

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ success: false, error: "Only POST requests allowed" }),
        { status: 405, headers: { "Content-Type": "application/json" } }
      );
    }

    const { email, otp } = await req.json();
    if (!email || !otp) {
      return new Response(
        JSON.stringify({ success: false, error: "Email and OTP are required!" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create a Nodemailer Transporter
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: Deno.env.get("SMTP_USER"),
        pass: Deno.env.get("SMTP_PASS"),
      },
    });

    // Send Email
    await transporter.sendMail({
      from: Deno.env.get("SMTP_FROM"),
      to: email,
      subject: "🔐 Your OTP Code - Charity Fire",
      text: `Hello,\n\nYour OTP code is: ${otp}\n\nDo not share this with anyone.\n\nRegards,\nCharity Fire Team`,
    });

    return new Response(
      JSON.stringify({ success: true, message: "OTP Sent Successfully!" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Error Sending OTP:", error.message);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
