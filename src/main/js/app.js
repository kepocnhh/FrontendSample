const imageList = document.getElementById('image-list');
const nextButton = document.getElementById('next-page');

const pageSize = 3;

let items = [];
let currentPage = 0;

async function loadImages() {
  const response = await fetch('./src/main/json/db.json');

  if (!response.ok) {
    throw new Error(`Cannot load db.json: ${response.status}`);
  }

  items = await response.json();
  items.sort((a, b) => b.time - a.time);

  renderPage();
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

  nextButton.disabled = end >= items.length;
}

nextButton.addEventListener('click', () => {
  if ((currentPage + 1) * pageSize < items.length) {
    currentPage += 1;
    renderPage();
  }
});

loadImages().catch((error) => {
  console.error(error);
  imageList.classList.add('error');
  imageList.textContent = 'TODO';
});
