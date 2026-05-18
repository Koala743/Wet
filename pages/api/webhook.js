import crypto from "crypto";

export const config = {
  api: { bodyParser: false },
};

function getRawBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

function verifySignature(rawBody, signature) {
  const secret = process.env.LEMONSQUEEZY_WEBHOOK_SECRET;
  const hmac = crypto.createHmac("sha256", secret);
  const digest = hmac.update(rawBody).digest("hex");
  return digest === signature;
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const rawBody = await getRawBody(req);
  const signature = req.headers["x-signature"];

  if (!verifySignature(rawBody, signature)) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  const event = JSON.parse(rawBody);
  const eventName = event.meta?.event_name;

  if (eventName === "order_created") {
    const order = event.data.attributes;
    console.log("✅ Orden pagada:", order.user_email, order.first_order_item?.product_name);
    // Aquí entregas el producto
  }

  return res.status(200).json({ received: true });
}
