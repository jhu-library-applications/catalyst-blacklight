import { onlineAccessOverflow } from './online_access_overflow'
import isbot from 'isbot'

export const loadOnlineAccess = () => {
  document.querySelectorAll('.online-access-container').forEach((el) => {
    if (el && !isbot(navigator.userAgent)) {
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
        if (shouldFetch(entry)) {
          fetchExternalLinks(entry)
        }
      }

      entry.target.setAttribute('src', entry.target.getAttribute('data-src'))
      entry.target.setAttribute('data-processed', true)
    })
  }
}

const shouldFetch = (entry) => {
  console.log(entry.target);
  return entry.target.textContent.length > 0 && 
    isFormat(entry, 'Journal/Newspaper') || 
    // Only look for Online Books in SFX if the publisher is Springer
    (isFormat(entry, 'Online') && isFormat(entry, 'Book') && isSpringerBook(entry)) ||
    (isFormat(entry, 'Print') && isFormat(entry, 'Book'))
}

const isSpringerBook = (entry) => { 
  var entryPublisher = entry.target.getAttribute('data-publisher')
  console.log(entryPublisher.includes('Springer'))
  return entryPublisher.includes('Springer')
}

const isFormat = (entry, format) => { 
  var entryFormat = entry.target.getAttribute('data-format')

  return JSON.parse(entryFormat).includes(format)
}

const fetchExternalLinks = (entry) => {
  var originalText = entry.target.innerHTML

  showLoadingIndicator(entry)
  fetch(entry.target.getAttribute('data-remote-url'))
    .then(errorHandler)
    .then(response => response.text())
    .then(
      data => {
        if (data) {
          hideLoadingIndicator(entry)
          entry.target.innerHTML = data
          onlineAccessOverflow()
        } else {
            hideLoadingIndicator(entry)
            entry.target.innerHTML = originalText
        }
      }
    ).catch((error) => {
      hideLoadingIndicator(entry)
      if (originalText) {
        entry.target.innerHTML = originalText
      } else {
        entry.target.innerHTML = response
      }
    })
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

const errorHandler = (response) => {
  if (!response.ok) {
    throw Error(response.statusText);
  }

  return response;
}
