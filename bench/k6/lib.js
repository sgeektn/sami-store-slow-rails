export const BASE = __ENV.BASE_URL || "http://localhost:3000";
export const CUSTOMERS = 20000; // matches the seed

export function options(thresholdMs) {
  return {
    vus: Number(__ENV.VUS || 5),
    duration: __ENV.DURATION || "30s",
    thresholds: { http_req_duration: [`p(95)<${thresholdMs}`] },
    summaryTrendStats: ["avg", "med", "p(95)", "max"],
  };
}
