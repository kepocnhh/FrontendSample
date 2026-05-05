const imageList = document.getElementById('image-list');
const prevButton = document.getElementById('prev-page');
const nextButton = document.getElementById('next-page');

const pageSize = 3;

let items = [];
let currentPage = getPageFromQuery();

function getPageFromQuery() {
  const params = new URLSearchParams(window.location.search);
  const page = Number(params.get('page') ?? 0);

  if (!Number.isInteger(page) || page < 0) {
    return 0;
  }

  return page;
}

function setPageInQuery(page) {
  const url = new URL(window.location.href);
  url.searchParams.set('page', page);
  window.location.href = url.toString();
}

async function loadImages() {
  const response = await fetch('./src/main/json/db.json');

  if (!response.ok) {
    throw new Error(`Cannot load db.json: ${response.status}`);
  }

  items = await response.json();
  items.sort((a, b) => b.time - a.time);

  normalizeCurrentPage();
  renderPage();
}

function normalizeCurrentPage() {
  const lastPage = Math.max(0, Math.ceil(items.length / pageSize) - 1);

  if (currentPage > lastPage) {
    currentPage = lastPage;
  }
}

function renderPage() {
  imageList.replaceChildren();

  const start = currentPage * pageSize;
  const end = start + pageSize;
  const pageItems = items.slice(start, end);

  for (const item of pageItems) {
    const image = document.createElement('img');
    image.src = `./src/main/res/${item.id}.img`;
    image.alt = item.id;
    image.loading = 'lazy';

    imageList.append(image);
  }

  prevButton.disabled = currentPage === 0;
  nextButton.disabled = end >= items.length;
}

prevButton.addEventListener('click', () => {
  if (currentPage > 0) {
    setPageInQuery(currentPage - 1);
  }
});

nextButton.addEventListener('click', () => {
  if ((currentPage + 1) * pageSize < items.length) {
    setPageInQuery(currentPage + 1);
  }
});

loadImages().catch((error) => {
  console.error(error);
  imageList.classList.add('error');
  imageList.textContent = 'TODO';
});
