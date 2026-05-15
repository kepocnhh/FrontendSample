const imageList = document.getElementById('image-list');
const prevButton = document.getElementById('prev-page');
const nextButton = document.getElementById('next-page');

const pageSize = 3;
const recordSize = 8;
const cacheKey = Date.now();

let count = 0;
let pageItems = [];
let currentPage = getPageFromQuery();

function getPageFromQuery() {
  const params = new URLSearchParams(window.location.search);
  const pageValue = params.get('page') ?? '0';
  const page = Number(pageValue);

  if (!Number.isInteger(page) || String(page) !== pageValue) {
    return null;
  }

  return page;
}

function setPageInQuery(page) {
  const url = new URL(window.location.href);
  url.searchParams.set('page', page);
  window.location.href = url.toString();
}

async function loadImages() {
  const countData = await loadCount();
  count = countData.publishedCount;

  if (!isCurrentPageValid()) {
    showErrorPage();
    return;
  }

  pageItems = count === 0 ? [] : await loadPageItems();
  renderPage();
}

function isCurrentPageValid() {
  const pages = Math.ceil(count / pageSize);

  if (count === 0) {
    return currentPage === 0;
  }

  return currentPage !== null && currentPage >= 0 && currentPage < pages;
}

function showErrorPage() {
  window.location.href = './src/main/html/error.html';
}

async function loadCount() {
  const response = await fetch(`./src/main/res/counts.bin?cache=${cacheKey}`, {
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error(`Cannot load counts.bin: ${response.status}`);
  }

  const buffer = await response.arrayBuffer();

  if (buffer.byteLength !== 12) {
    throw new Error(`Invalid counts.bin size: ${buffer.byteLength}`);
  }

  const view = new DataView(buffer);

  return {
    publishedCount: view.getUint32(0, false),
    pendingCount: view.getUint32(4, false),
    lastCounter: view.getUint32(8, false),
  };
}

async function loadPageItems() {
  const { byteStart, byteEnd } = getPageBounds();
  const response = await fetch(`./src/main/res/published.bin?cache=${cacheKey}`, {
    cache: 'no-store',
    headers: {
      Range: `bytes=${byteStart}-${byteEnd}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Cannot load published.bin: ${response.status}`);
  }

  let buffer = await response.arrayBuffer();
  const expectedSize = byteEnd - byteStart + 1;

  if (response.status === 200 && buffer.byteLength > expectedSize) {
    buffer = buffer.slice(byteStart, byteEnd + 1);
  }

  if (buffer.byteLength !== expectedSize) {
    throw new Error(`Invalid published.bin page size: ${buffer.byteLength}`);
  }

  return parseRecords(buffer).reverse();
}

function getPageBounds() {
  const endRecord = count - currentPage * pageSize;
  const startRecord = Math.max(0, endRecord - pageSize);

  return {
    byteStart: startRecord * recordSize,
    byteEnd: endRecord * recordSize - 1,
  };
}

function parseRecords(buffer) {
  const view = new DataView(buffer);
  const records = [];

  for (let offset = 0; offset < buffer.byteLength; offset += recordSize) {
    records.push({
      id: parseId(view, offset),
      time: view.getUint32(offset, false),
    });
  }

  return records;
}

function parseId(view, offset) {
  const bytes = [];

  for (let i = 0; i < 8; i += 1) {
    bytes.push(view.getUint8(offset + i).toString(16).padStart(2, '0'));
  }

  return bytes.join('');
}

function renderPage() {
  imageList.replaceChildren();

  for (const item of pageItems) {
    const image = document.createElement('img');
    image.src = `./src/main/res/${item.id}.jpg`;
    image.alt = item.id;
    image.loading = 'lazy';

    imageList.append(image);
  }

  prevButton.disabled = currentPage === 0;
  nextButton.disabled = (currentPage + 1) * pageSize >= count;
}

prevButton.addEventListener('click', () => {
  if (currentPage > 0) {
    setPageInQuery(currentPage - 1);
  }
});

nextButton.addEventListener('click', () => {
  if ((currentPage + 1) * pageSize < count) {
    setPageInQuery(currentPage + 1);
  }
});

loadImages().catch((error) => {
  console.error(error);
  imageList.classList.add('error');
  imageList.textContent = 'TODO';
});
