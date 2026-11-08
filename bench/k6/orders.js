import http from "k6/http";
import { check } from "k6";
import { BASE, CUSTOMERS, options as opts } from "./lib.js";

export const options = opts(20);

export default function () {
  const n = Math.floor(Math.random() * CUSTOMERS) + 1;
  check(http.get(`${BASE}/orders?email=customer${n}@example.com`), { "200": (r) => r.status === 200 });
}
