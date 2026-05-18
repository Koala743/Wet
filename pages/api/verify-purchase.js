export default async function handler(req, res) {
  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email } = req.query;

  if (!email) {
    return res.status(400).json({ error: "Se requiere email" });
  }

  const response = await fetch(
    `https://api.lemonsqueezy.com/v1/orders?filter[store_id]=${process.env.LEMONSQUEEZY_STORE_ID}&filter[user_email]=${email}`,
    {
      headers: {
        Authorization: `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`,
        Accept: "application/vnd.api+json",
      },
    }
  );

  const data = await response.json();
  const pagadas = data.data.filter((o) => o.attributes.status === "paid");

  return res.status(200).json({
    verified: pagadas.length > 0,
    ordenes: pagadas.map((o) => ({
      id: o.id,
      producto: o.attributes.first_order_item?.product_name,
      total: o.attributes.total_formatted,
    })),
  });
}