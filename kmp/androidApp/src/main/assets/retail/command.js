const state = { done: false, results: [], origin: location.origin };
window[KEY] = state;
const base = '/api/customer/1.4.1.0';
let selectedSap = null;

function productImageUrl(value) {
  for (const image of [value.image, value.primaryImage]) {
    const template = image?.cropUrlTemplate;
    if (typeof template !== 'string' || template.length > 2000 || template.split('%s').length !== 2) continue;
    try {
      const imageUrl = new URL(template.replace('%s', '200x200-fit'));
      if (imageUrl.protocol === 'https:' && imageUrl.hostname === 'tsx.x5static.net' &&
          !imageUrl.port && !imageUrl.username && !imageUrl.password && !imageUrl.search && !imageUrl.hash &&
          imageUrl.pathname.startsWith('/i/200x200-fit/xdelivery/files/')) return imageUrl.href;
    } catch (_) { /* An optional malformed source image must not reject a product. */ }
  }
  return null;
}

function product(value) {
  const master = value.masterData || {};
  const tag = value.priceTag || {};
  const category = value.primaryCategory || value.catalogPrimaryCategory || {};
  return {
    id: value.id,
    title: value.title,
    image_url: productImageUrl(value),
    slug: typeof master.slug === 'string' ? master.slug.slice(0, 500) : null,
    plu: typeof master.plu === 'string' || Number.isInteger(master.plu) ? String(master.plu).slice(0, 100) : null,
    primary_category_id: Number.isInteger(value.primaryCategory?.id) ? value.primaryCategory.id : null,
    catalog_primary_category_id: Number.isInteger(value.catalogPrimaryCategory?.id) ? value.catalogPrimaryCategory.id : null,
    price_kopeks: Number.isInteger(tag.price) ? tag.price : null,
    balance_state: value.balanceState ?? null,
    unit: Number.isInteger(master.unit) ? master.unit : null,
    unit_name: typeof master.unitName === 'string' ? master.unitName.slice(0, 40) : null,
    quantum: Number.isFinite(master.quantum) ? master.quantum : null,
    quantum_step: Number.isFinite(master.quantumStep) ? master.quantumStep : null,
    weight: Number.isFinite(master.weight) ? master.weight : null,
    volume: Number.isFinite(master.volume) ? master.volume : null,
    price_per_quantum_kopeks: Number.isInteger(tag.pricePerQuantum) ? tag.pricePerQuantum : null,
    url: category.id && master.slug && master.plu
      ? 'https://www.perekrestok.ru/cat/' + category.id + '/p/' + master.slug + '-' + master.plu
      : null,
  };
}

async function request(operation, path, method = 'GET', body = null) {
  const controller = new AbortController();
  state.controller = controller;
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(base + path, {
      method,
      credentials: 'include',
      headers: { ...HEADERS, accept: 'application/json', 'content-type': 'application/json' },
      ...(body ? { body: JSON.stringify(body) } : {}),
      signal: controller.signal,
    });
    const row = { operation, http_status: response.status,
      response_url: response.url, request_method: method };
    state.results.push(row);
    if (!response.ok) throw Error(response.status === 403 ? 'challenge_or_block' : 'http_' + response.status);
    let payload;
    try { payload = await response.json(); } catch (_) { throw Error('non_json_response'); }
    const content = payload.content;
    if (!content) throw Error('missing_content');
    if (operation === 'select_store') {
      row.mode = content.mode;
      row.shop_id = content.shop?.id;
      row.sap_id = String(content.shop?.sapId || '');
      if (row.mode !== 'catalog' || row.shop_id !== COMMAND.store_id || !/^[0-9]{1,12}$/.test(row.sap_id)) throw Error('store_selection_mismatch');
      selectedSap = row.sap_id;
    } else if (operation === 'search_products') {
      row.sap_id = String(content.sapId || '');
      if (row.sap_id !== selectedSap) throw Error('store_mismatch');
      row.items = (content.items || []).slice(0, 48).map(product);
    } else {
      row.sap_id = selectedSap;
      row.store_binding = 'session_context';
      row.items = [product(content)];
    }
  } finally {
    clearTimeout(timeout);
    state.controller = null;
  }
}

(async () => {
  try {
    const store = COMMAND.store_id;
    const expectedSap = COMMAND.sap_id;
    const hasExpectedSap = typeof expectedSap === 'string' && /^[0-9]{1,12}$/.test(expectedSap);
    if (!Number.isInteger(store) || store <= 0 ||
        (expectedSap != null && !hasExpectedSap) || (COMMAND.operation !== 'select_store' && !hasExpectedSap)) throw Error('unsupported_store');
    await request('select_store', '/delivery/mode/pickup/' + store, 'PUT');
    if (hasExpectedSap && selectedSap !== expectedSap) throw Error('store_mapping_mismatch');
    if (COMMAND.operation === 'search_products') {
      await request('search_products', '/catalog/product/feed', 'POST', {
        page: COMMAND.page,
        perPage: 48,
        filter: { textQuery: COMMAND.query },
        withBestProductReviews: false,
      });
    } else if (COMMAND.operation === 'get_product') {
      await request('get_product', '/catalog/product/' + COMMAND.product_id);
    } else if (COMMAND.operation !== 'select_store') {
      throw Error('unsupported_operation');
    }
  } catch (error) {
    state.error = error?.name === 'AbortError'
      ? 'timeout'
      : String(error?.message || 'request_failed').slice(0, 120);
  } finally {
    state.done = true;
  }
})();
