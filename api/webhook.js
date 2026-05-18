const crypto = require("crypto");

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const rawBody = await new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });

  const signature = req.headers["x-signature"];
  const secret = process.env.LEMONSQUEEZY_WEBHOOK_SECRET;
  const hmac = crypto.createHmac("sha256", secret);
  const digest = hmac.update(rawBody).digest("hex");

  if (digest !== signature) {
    return res.status(401).json({ error: "Firma invalida" });
  }

  const event = JSON.parse(rawBody);
  const eventName = event.meta?.event_name;

  if (eventName === "order_created") {
    const order = event.data.attributes;
    console.log("✅ Orden pagada:", order.user_email, order.first_order_item?.product_name);
    // Aqui entregas el producto
  }

  return res.status(200).json({ received: true });
};