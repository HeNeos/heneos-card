export function start_footer_timer(milliseconds, callback) {
  globalThis.setInterval(callback, milliseconds);
}

export function random_seed() {
  return Math.floor(Math.random() * 2_147_483_646) + 1;
}
