export const externalResourcesOverflow = () => {
  document.addEventListener('click', el => {
    let viewButtonEl = el.target.closest('.view-overflow-urls')

    if (viewButtonEl) {
      viewButtonEl.classList.add('d-none')
      viewButtonEl.nextElementSibling.classList.remove('overflow-urls')
    }
  })
}
