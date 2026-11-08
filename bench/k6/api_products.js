import http from "k6/http";
import { check } from "k6";
import { BASE, options as opts } from "./lib.js";

export const options = opts(100);

export default function () {
  check(http.get(`${BASE}/api/products`), { "200": (r) => r.status === 200 });
}
