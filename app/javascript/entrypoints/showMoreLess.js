// eslint-disable-next-line import/prefer-default-export
export const showMoreLess = {
  // eslint-disable-next-line object-shorthand, func-names
  showMore: function (element, excerpt) {
    const textElement = element;

    textElement.addEventListener('click', (event) => {
      const linkText = event.target.textContent.toLowerCase();
      event.preventDefault();

      if (linkText === 'more...') {
        textElement.textContent = 'less...';
        excerpt.classList.remove('truncate');
      } else {
        textElement.textContent = 'more...';
        excerpt.classList.add('truncate');
      }
    });
  },
};
/*
Based on https://dev.to/justalever/how-to-code-a-show-more--show-less-toggle-with-javascript-3c7m
*/
