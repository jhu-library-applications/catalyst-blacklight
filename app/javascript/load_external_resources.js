import { externalResourcesOverflow } from './external_resources_overflow'

export const loadExternalResources = () => {
  document.querySelectorAll('.external-resources-container').forEach((el) => {
    if (el) {
      const observer = new IntersectionObserver((entries) => {
        observerCallback(entries, observer, el)
      },
                                                { threshold: 1 })
      observer.observe(el)
    }
  })

  const observerCallback = (entries, observer, header) => {
    entries.forEach((entry, i) => {
      if (entry.target.getAttribute('data-processed') || !entry.isIntersecting)
        return true

      if (entry.isIntersecting) {
        if (entry.target.textContent.length > 0) {
          fetchExternalLinks(entry)
        }
      }

      entry.target.setAttribute('src', entry.target.getAttribute('data-src'))
      entry.target.setAttribute('data-processed', true)
    })
  }
}

const fetchExternalLinks = (entry) => {
  var originalText = entry.target.innerHTML

  showLoadingIndicator(entry)
  fetch(entry.target.getAttribute('data-remote-url'))
    .then(response => response.text())
    .then(
      data => {
        if (data) {
          hideLoadingIndicator(entry)
          entry.target.innerHTML = data
          externalResourcesOverflow()
        } else {
            hideLoadingIndicator(entry)
            entry.target.innerHTML = originalText
        }
      }
    )
}

const hideLoadingIndicator = (entry) => {
  entry.target.querySelector('.spinner-border').classList.add('d-none')
}

const showLoadingIndicator = (entry) => {
  entry.target.innerHTML = `<div class="spinner-border text-secondary" role="status">
    <span class="sr-only">Loading Online Access links</span>
  </div>
  `
}
