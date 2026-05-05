const imageList = document.getElementById('image-list');

async function loadImages() {
  const response = await fetch('./src/main/json/db.json');

  if (!response.ok) {
    throw new Error(`Cannot load db.json: ${response.status}`);
  }

  const items = await response.json();
  items.sort((a, b) => b.time - a.time);

  for (const item of items) {
    const image = document.createElement('img');
    image.src = `./src/main/res/${item.id}.img`;
    image.alt = item.id;
    image.loading = 'lazy';

    imageList.append(image);
  }
}

loadImages().catch((error) => {
  console.error(error);
  imageList.classList.add('error');
  imageList.textContent = 'Не удалось загрузить картинки.';
});
