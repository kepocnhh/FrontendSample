const imageList = document.getElementById('image-list');
const prevButton = document.getElementById('prev-page');
const nextButton = document.getElementById('next-page');

const pageSize = 3;
const recordSize = 24;

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
  count = await loadCount();

  if (!isCurrentPageValid()) {
    showErrorPage();
    return;
  }

  pageItems = await loadPageItems();
  renderPage();
}

function isCurrentPageValid() {
  const pages = Math.ceil(count / pageSize);

  return currentPage !== null && currentPage >= 0 && currentPage < pages;
}

function showErrorPage() {
  window.location.href = './src/main/html/error.html';
}

async function loadCount() {
  const response = await fetch('./src/main/bin/count.bin');

  if (!response.ok) {
    throw new Error(`Cannot load count.bin: ${response.status}`);
  }

  const buffer = await response.arrayBuffer();

  if (buffer.byteLength !== 4) {
    throw new Error(`Invalid count.bin size: ${buffer.byteLength}`);
  }

  return new DataView(buffer).getUint32(0, false);
}

async function loadPageItems() {
  const { byteStart, byteEnd } = getPageBounds();
  const response = await fetch('./src/main/bin/db.bin', {
    headers: {
      Range: `bytes=${byteStart}-${byteEnd}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Cannot load db.bin: ${response.status}`);
  }

  let buffer = await response.arrayBuffer();
  const expectedSize = byteEnd - byteStart + 1;

  if (response.status === 200 && buffer.byteLength > expectedSize) {
    buffer = buffer.slice(byteStart, byteEnd + 1);
  }

  if (buffer.byteLength !== expectedSize) {
    throw new Error(`Invalid db.bin page size: ${buffer.byteLength}`);
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
      id: parseUuid(view, offset),
      time: Number(view.getBigUint64(offset + 16, false)),
    });
  }

  return records;
}

function parseUuid(view, offset) {
  const bytes = [];

  for (let i = 0; i < 16; i += 1) {
    bytes.push(view.getUint8(offset + i).toString(16).padStart(2, '0'));
  }

  return [
    bytes.slice(0, 4).join(''),
    bytes.slice(4, 6).join(''),
    bytes.slice(6, 8).join(''),
    bytes.slice(8, 10).join(''),
    bytes.slice(10, 16).join(''),
  ].join('-');
}

function renderPage() {
  imageList.replaceChildren();

  for (const item of pageItems) {
    const image = document.createElement('img');
    image.src = `./src/main/res/${item.id}.img`;
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
