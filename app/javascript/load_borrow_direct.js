//import isbot from 'isbot'

export const loadBorrowDirect = () => {
    document.querySelectorAll('.borrow-direct-container').forEach((el) => {
        if (el ){//&& !isbot(navigator.userAgent)) {
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

            entry.target.setAttribute('data-processed', true)
        })
    }
}

const shouldFetch = (entry) => {
    return entry.target.textContent.length > 0 &&
        (isFormat(entry, 'Online') && isFormat(entry, 'Book')) ||
        (isFormat(entry, 'Print') && isFormat(entry, 'Book'))
}

const isFormat = (entry, format) => {
    var entryFormat = entry.target.getAttribute('data-format')

    return JSON.parse(entryFormat).includes(format)
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
                } else {
                    hideLoadingIndicator(entry)
                    entry.target.innerHTML = originalText
                }
            }
        ).catch(
            error => {
                entry.target.parentNode.classList.add('hidden')
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