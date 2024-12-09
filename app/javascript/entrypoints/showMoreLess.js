/* 

Based on https://dev.to/justalever/how-to-code-a-show-more--show-less-toggle-with-javascript-3c7m 

*/

export const showMoreLess = {

    addClass: function(element, theClass) {
      element.classList.add(theClass);
    },

    removeClass: function(element, theClass) {
      element.classList.remove(theClass);
    },

    showMore: function(element, excerpt) {
      element.addEventListener("click", event => {
        const linkText = event.target.textContent.toLowerCase();
        event.preventDefault();

        console.log(this);
        if (linkText == "more...") {
          element.textContent = "less...";
          this.removeClass(excerpt, "truncate");
          this.addClass(excerpt, "excerpt-visible");
        } else {
          element.textContent = "more...";
          this.removeClass(excerpt, "excerpt-visible");
          this.addClass(excerpt, "truncate");
        }
      });
    } 
  }