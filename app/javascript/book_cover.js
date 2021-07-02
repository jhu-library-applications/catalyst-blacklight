export function bookCover() {
  document.addEventListener('DOMContentLoaded', () => {
    if (document.querySelectorAll('.cover-image-container').length) {
      var isbn = document.querySelector('.cover-image-container').getAttribute('data-isbn')
      var imageContainer = document.querySelector('.cover-image-container')

      if (isbn) {
        fetch(`/bookcovershowcase.json?per_page=1&q=${isbn}&search_field=number`)
          .then(response => response.json())
          .then(data => data.bookcovers.forEach(data => {
            imageContainer.innerHTML = `<a href="${data.catalystURL}" title="${data.title}"><img src="${data.imageURL}" alt="${data.title}"></img></a>`
          }))
      }
    }
  })
}
