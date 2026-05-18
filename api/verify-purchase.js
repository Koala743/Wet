module.exports = async (req, res) => {
  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email } = req.query;

  if (!email) {
    return res.status(400).json({ error: "Se requiere email" });
  }

  const response = await fetch(
    `https://api.lemonsqueezy.com/v1/orders?filter[store_id]=361536&filter[user_email]=${email}`,
    {
      headers: {
        Authorization: `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`,
        Accept: "application/vnd.api+json",
      },
    }
  );

  const data = await response.json();
  const pagadas = data.data.filter((o) => o.attributes.status === "paid");

  if (pagadas.length === 0) {
    return res.status(200).json({
      verified: false,
      mensaje: "Este email no tiene compras registradas"
    });
  }

  return res.status(200).json({
    verified: true,
    mensaje: "Compra verificada!",
    ordenes: pagadas.map((o) => ({
      id: o.id,
      producto: o.attributes.first_order_item?.product_name,
      total: o.attributes.total_formatted,
    })),
  });
};