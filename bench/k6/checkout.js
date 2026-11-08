import http from "k6/http";
import { check } from "k6";
import { BASE, CUSTOMERS, options as opts } from "./lib.js";

export const options = opts(200);

export default function () {
  const n = Math.floor(Math.random() * CUSTOMERS) + 1;
  const res = http.post(`${BASE}/checkout`, {
    email: `customer${n}@example.com`,
    product_id: Math.floor(Math.random() * 50000) + 1,
    quantity: 1,
  });
  check(res, { "2xx": (r) => r.status >= 200 && r.status < 300 });
}
